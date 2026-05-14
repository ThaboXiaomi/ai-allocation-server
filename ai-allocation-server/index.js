const path = require("path");
const express = require("express");
const cors = require("cors");
const admin = require("firebase-admin");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const { Server } = require("socket.io");
const { v4: uuidv4 } = require("uuid");
const swaggerUi = require("swagger-ui-express");
const YAML = require("yaml");
const { CronJob } = require("jscron");

require("dotenv").config({ path: path.resolve(__dirname, "../.env") });

const REQUIRED_ENV_VARS = ["GOOGLE_APPLICATION_CREDENTIALS"];

// Swagger/OpenAPI documentation
const swaggerDocument = YAML.parse(`
openapi: 3.0.0
info:
  title: AI Allocation Server API
  description: Comprehensive API for room allocation with AI-powered conflict resolution
  version: 2.0.0
servers:
  - url: http://localhost:3000
    description: Development server
components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
  schemas:
    Allocation:
      type: object
      properties:
        id:
          type: string
        userId:
          type: string
        roomId:
          type: string
        date:
          type: string
          format: date
        startTime:
          type: string
        endTime:
          type: string
        conflict:
          type: boolean
        status:
          type: string
          enum: [pending, confirmed, resolved, cancelled]
    ConflictResolution:
      type: object
      required:
        - allocationId
        - date
        - startTime
        - endTime
      properties:
        allocationId:
          type: string
        conflictDetails:
          type: string
          maxLength: 500
        date:
          type: string
          format: date
        startTime:
          type: string
        endTime:
          type: string
paths:
  /allocations:
    get:
      summary: Get all allocations
      security:
        - bearerAuth: []
      responses:
        '200':
          description: List of allocations
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/Allocation'
  /resolve-conflict:
    post:
      summary: Resolve a conflict
      security:
        - bearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/ConflictResolution'
      responses:
        '200':
          description: Conflict resolved successfully
  /health:
    get:
      summary: Health check endpoint
      responses:
        '200':
          description: Server is healthy
  /api-docs:
    get:
      summary: Interactive API documentation
      responses:
        '200':
          description: Swagger UI documentation
`);

// Audit logging utility
function logAuditAction(db, action, userId, details) {
  return db.collection("audit_logs").add({
    action,
    userId,
    details,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    ipAddress: details.ipAddress || null,
    userAgent: details.userAgent || null,
  });
}

// Waitlist management
async function addToWaitlist(db, waitlistData) {
  const waitlistRef = db.collection("waitlist").doc(uuidv4());
  await waitlistRef.set({
    ...waitlistData,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    status: "pending",
  });
  return waitlistRef.id;
}

async function processWaitlist(db, logger) {
  try {
    const pendingWaitlist = await db
      .collection("waitlist")
      .where("status", "==", "pending")
      .orderBy("createdAt", "asc")
      .limit(10)
      .get();

    if (pendingWaitlist.empty) return;

    logger.info(`Processing ${pendingWaitlist.size} waitlist entries`);

    for (const doc of pendingWaitlist.docs) {
      const waitlistItem = doc.data();
      
      // Check if slot is now available
      const conflictingAllocations = await db
        .collection("allocations")
        .where("roomId", "==", waitlistItem.roomId)
        .where("date", "==", waitlistItem.date)
        .where("startTime", "<", waitlistItem.endTime)
        .where("endTime", ">", waitlistItem.startTime)
        .get();

      if (conflictingAllocations.empty) {
        // Slot available, create allocation
        const allocationRef = db.collection("allocations").doc(uuidv4());
        await db.runTransaction(async (transaction) => {
          transaction.set(allocationRef, {
            userId: waitlistItem.userId,
            roomId: waitlistItem.roomId,
            date: waitlistItem.date,
            startTime: waitlistItem.startTime,
            endTime: waitlistItem.endTime,
            conflict: false,
            status: "confirmed",
            source: "waitlist_auto_booking",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          
          transaction.update(doc.ref, {
            status: "fulfilled",
            allocationId: allocationRef.id,
            fulfilledAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        });

        logger.info(`Auto-booked waitlist item ${doc.id} to allocation ${allocationRef.id}`);
      }
    }
  } catch (error) {
    logger.error("Error processing waitlist:", error);
  }
}

// Predictive analytics helper
async function getRoomDemandPrediction(db, roomId, dateRange) {
  const bookings = await db
    .collection("allocations")
    .where("roomId", "==", roomId)
    .where("date", ">=", dateRange.start)
    .where("date", "<=", dateRange.end)
    .get();

  const historicalData = await db
    .collection("allocations")
    .where("roomId", "==", roomId)
    .where("date", "<", dateRange.start)
    .orderBy("date", "desc")
    .limit(100)
    .get();

  return {
    upcomingBookings: bookings.size,
    historicalAverage: historicalData.size / Math.max(1, historicalData.docs.length),
    trend: bookings.size > historicalData.size ? "increasing" : "stable",
  };
}

// Validate environment variables
function validateEnv(logger = console) {
  const missing = REQUIRED_ENV_VARS.filter((key) => !process.env[key]);
  
  if (missing.length > 0) {
    logger.error(`❌ Missing required environment variables: ${missing.join(", ")}`);
    return false;
  }

  if (!process.env.OPENAI_API_KEY) {
    logger.warn("⚠️ OPENAI_API_KEY is missing; AI-powered features may be unavailable.");
  }

  return true;
}

// Input validation for resolve-conflict endpoint
function validateResolveConflictPayload(body) {
  if (!body || typeof body !== "object" || Array.isArray(body)) {
    return { valid: false, message: "Request body must be a JSON object." };
  }

  const requiredFields = ["allocationId", "date", "startTime", "endTime"];
  const missing = requiredFields.filter((field) => !body[field]);

  if (missing.length > 0) {
    return {
      valid: false,
      message: `Missing required fields: ${missing.join(", ")}.`,
    };
  }

  // Validate date format (YYYY-MM-DD)
  const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
  if (!dateRegex.test(body.date)) {
    return {
      valid: false,
      message: "Invalid date format. Use YYYY-MM-DD.",
    };
  }

  // Validate time format (HH:MM AM/PM or HH:MM)
  const timeRegex = /^([0-1]?[0-9]|2[0-3]):[0-5][0-9]\s*(AM|PM|am|pm)?$/;
  if (!timeRegex.test(body.startTime) || !timeRegex.test(body.endTime)) {
    return {
      valid: false,
      message: "Invalid time format. Use HH:MM or HH:MM AM/PM.",
    };
  }

  // Validate allocationId format (alphanumeric, max 50 chars)
  if (typeof body.allocationId !== "string" || body.allocationId.length > 50 || !/^[a-zA-Z0-9_-]+$/.test(body.allocationId)) {
    return {
      valid: false,
      message: "Invalid allocationId format.",
    };
  }

  // Sanitize conflictDetails if present
  if (body.conflictDetails && (typeof body.conflictDetails !== "string" || body.conflictDetails.length > 500)) {
    return {
      valid: false,
      message: "conflictDetails must be a string with max 500 characters.",
    };
  }

  return { valid: true };
}

// Authentication middleware using Firebase Admin SDK
async function authenticateUser(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ error: "Unauthorized: Missing or invalid authorization header." });
    }

    const token = authHeader.split(" ")[1];
    
    if (!token) {
      return res.status(401).json({ error: "Unauthorized: Missing token." });
    }

    const decodedToken = await admin.auth().verifyIdToken(token);
    req.user = decodedToken;
    next();
  } catch (error) {
    console.error("Authentication error:", error);
    return res.status(401).json({ error: "Unauthorized: Invalid token." });
  }
}

// Authorization middleware to check if user has permission to modify allocation
async function authorizeAllocationAccess(req, res, next) {
  try {
    const allocationId = req.body.allocationId || req.params.id;
    
    if (!allocationId) {
      return res.status(400).json({ error: "Allocation ID required." });
    }

    const allocationRef = req.db.collection("allocations").doc(allocationId);
    const allocDoc = await allocationRef.get();

    if (!allocDoc.exists) {
      return res.status(404).json({ error: `Allocation with ID ${allocationId} not found.` });
    }

    const allocationData = allocDoc.data();
    
    // Check if user is authorized (owner, admin, or has specific role)
    const userId = req.user.uid;
    const isAdmin = req.user.customClaims?.admin === true;
    const isOwner = allocationData.userId === userId;
    
    if (!isAdmin && !isOwner) {
      return res.status(403).json({ error: "Forbidden: You do not have permission to modify this allocation." });
    }

    req.allocationData = allocationData;
    next();
  } catch (error) {
    console.error("Authorization error:", error);
    return res.status(500).json({ error: "Authorization check failed." });
  }
}

function createApp({ db, firestoreAdmin = admin, logger = console }) {
  const app = express();
  const server = require("http").createServer(app);
  const io = new Server(server, {
    cors: {
      origin: process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : ['http://localhost:3000'],
      credentials: true,
    },
  });

  // Real-time notifications with Socket.io
  io.on("connection", (socket) => {
    logger.info(`Client connected: ${socket.id}`);
    
    socket.on("join_room", (roomId) => {
      socket.join(`room_${roomId}`);
      logger.info(`Client ${socket.id} joined room_${roomId}`);
    });
    
    socket.on("join_user", (userId) => {
      socket.join(`user_${userId}`);
      logger.info(`Client ${socket.id} joined user_${userId}`);
    });
    
    socket.on("disconnect", () => {
      logger.info(`Client disconnected: ${socket.id}`);
    });
  });

  // Attach Socket.io and other utilities to app for use in routes
  app.set("io", io);
  app.set("db", db);
  app.set("logger", logger);

  // Security: Use Helmet for HTTP headers security
  app.use(helmet());
  
  // Security: Restrict CORS to specific origins
  const allowedOrigins = process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : ['http://localhost:3000'];
  app.use(cors({
    origin: function(origin, callback) {
      // Allow requests with no origin (like mobile apps or curl requests)
      if (!origin) return callback(null, true);
      if (allowedOrigins.indexOf(origin) !== -1) {
        callback(null, true);
      } else {
        callback(new Error('Not allowed by CORS'));
      }
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
  }));
  
  // Security: Rate limiting to prevent brute force and DoS attacks
  const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // Limit each IP to 100 requests per windowMs
    message: { error: 'Too many requests, please try again later.' },
    standardHeaders: true,
    legacyHeaders: false,
  });
  app.use('/api/', limiter);
  
  // Stricter rate limit for sensitive endpoints
  const strictLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 20, // Limit each IP to 20 requests per windowMs
    message: { error: 'Too many requests, please try again later.' },
  });
  
  app.use(express.json({ limit: "1mb" }));
  app.use(express.urlencoded({ extended: false }));

  app.use((req, _res, next) => {
    logger.info(`→ ${req.method} ${req.originalUrl}`);
    next();
  });

  // Swagger UI documentation
  app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerDocument));

  app.get("/", (_req, res) => {
    res.status(200).json({
      message: "Welcome to the AI Allocation Server",
      status: "ok",
      version: "2.0.0",
      features: [
        "Authentication & Authorization",
        "Real-time Notifications (Socket.io)",
        "Waitlist & Auto-Rebooking",
        "Audit Logging",
        "Predictive Analytics",
        "Advanced Conflict Resolution",
        "API Documentation (Swagger)"
      ]
    });
  });

  app.get("/health", (_req, res) => {
    res.status(200).json({ 
      status: "ok",
      timestamp: new Date().toISOString(),
      uptime: process.uptime()
    });
  });

  // API Documentation endpoint
  app.get("/api-docs.json", (_req, res) => {
    res.json(swaggerDocument);
  });

  // Waitlist endpoint - add to waitlist
  app.post("/waitlist", authenticateUser, async (req, res) => {
    try {
      const { roomId, date, startTime, endTime, flexibleWindow } = req.body;
      
      if (!roomId || !date || !startTime || !endTime) {
        return res.status(400).json({ error: "Missing required fields: roomId, date, startTime, endTime" });
      }

      const waitlistId = await addToWaitlist(db, {
        userId: req.user.uid,
        roomId,
        date,
        startTime,
        endTime,
        flexibleWindow: flexibleWindow || 30, // minutes
        requestedAt: new Date().toISOString(),
      });

      // Log audit action
      await logAuditAction(db, "WAITLIST_ADD", req.user.uid, {
        waitlistId,
        roomId,
        date,
        ipAddress: req.ip,
        userAgent: req.get('user-agent'),
      });

      return res.status(201).json({ 
        message: "Added to waitlist successfully",
        waitlistId,
        position: "pending"
      });
    } catch (error) {
      logger.error("Error adding to waitlist:", error);
      return res.status(500).json({ error: "Failed to add to waitlist" });
    }
  });

  // Get user's waitlist entries
  app.get("/waitlist", authenticateUser, async (req, res) => {
    try {
      const snap = await db
        .collection("waitlist")
        .where("userId", "==", req.user.uid)
        .orderBy("createdAt", "desc")
        .get();

      const list = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      return res.status(200).json(list);
    } catch (error) {
      logger.error("Error fetching waitlist:", error);
      return res.status(500).json({ error: "Failed to fetch waitlist" });
    }
  });

  // Predictive analytics endpoint
  app.get("/analytics/demand/:roomId", authenticateUser, async (req, res) => {
    try {
      const { roomId } = req.params;
      const { days = 7 } = req.query;
      
      const startDate = new Date();
      const endDate = new Date();
      endDate.setDate(endDate.getDate() + parseInt(days));
      
      const prediction = await getRoomDemandPrediction(db, roomId, {
        start: startDate.toISOString().split('T')[0],
        end: endDate.toISOString().split('T')[0]
      });

      return res.status(200).json({
        roomId,
        dateRange: { start: startDate, end: endDate },
        prediction
      });
    } catch (error) {
      logger.error("Error fetching demand prediction:", error);
      return res.status(500).json({ error: "Failed to fetch demand prediction" });
    }
  });

  // Advanced conflict resolution with weighted scoring
  app.post("/resolve-conflict-advanced", strictLimiter, authenticateUser, async (req, res) => {
    const payloadCheck = validateResolveConflictPayload(req.body);
    if (!payloadCheck.valid) {
      return res.status(400).json({ error: payloadCheck.message });
    }

    const { allocationId, conflictDetails, date, startTime, endTime } = req.body;

    try {
      // Authorization check
      const allocationRef = db.collection("allocations").doc(allocationId);
      const allocDoc = await allocationRef.get();

      if (!allocDoc.exists) {
        return res.status(404).json({ error: `Allocation with ID ${allocationId} not found.` });
      }

      const allocationData = allocDoc.data();
      
      const userId = req.user.uid;
      const isAdmin = req.user.customClaims?.admin === true;
      const isOwner = allocationData.userId === userId;
      
      if (!isAdmin && !isOwner) {
        return res.status(403).json({ error: "Forbidden: You do not have permission to modify this allocation." });
      }

      // Calculate weighted score for conflict resolution
      const weightedScore = {
        userPriority: allocationData.priority || 1,
        requestTiming: Date.now() - allocationData.createdAt?.toMillis() || 0,
        durationEfficiency: 1, // Could calculate based on time utilization
        historicalReliability: 1, // Could fetch from user history
      };

      const totalScore = Object.values(weightedScore).reduce((a, b) => a + b, 0);

      // Use Firestore transaction for atomic operations
      await db.runTransaction(async (transaction) => {
        const freshAllocDoc = await transaction.get(allocationRef);
        if (!freshAllocDoc.exists) {
          throw new Error("Allocation no longer exists");
        }

        transaction.set(db.collection("resolved_conflicts").doc(), {
          allocationId,
          conflictDetails: conflictDetails || "No details provided",
          date,
          startTime,
          endTime,
          resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
          resolvedBy: req.user.uid,
          weightedScore,
          totalScore,
          resolutionMethod: "advanced_weighted_scoring"
        });

        transaction.set(
          allocationRef,
          {
            conflict: false,
            status: "resolved",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      });

      // Emit real-time notification
      const io = app.get("io");
      io.to(`room_${allocationData.roomId}`).emit("conflict_resolved", {
        allocationId,
        resolvedAt: new Date().toISOString(),
        resolvedBy: req.user.email || req.user.uid
      });

      // Log audit action
      await logAuditAction(db, "CONFLICT_RESOLVED_ADVANCED", req.user.uid, {
        allocationId,
        totalScore,
        ipAddress: req.ip,
        userAgent: req.get('user-agent'),
      });

      return res.status(200).json({ 
        message: "Conflict resolved with advanced scoring",
        weightedScore,
        totalScore
      });
    } catch (error) {
      logger.error("🛑 Error in POST /resolve-conflict-advanced:", error);
      return res.status(500).json({ error: "Failed to resolve conflict." });
    }
  });

  // Protected endpoint: Resolve conflict (requires authentication and authorization)
  app.post("/resolve-conflict", strictLimiter, authenticateUser, async (req, res) => {
    const payloadCheck = validateResolveConflictPayload(req.body);
    if (!payloadCheck.valid) {
      return res.status(400).json({ error: payloadCheck.message });
    }

    const { allocationId, conflictDetails, date, startTime, endTime } = req.body;

    try {
      // Authorization check is handled by authorizeAllocationAccess middleware
      // But we need to add it to the route or check manually here
      const allocationRef = db.collection("allocations").doc(allocationId);
      const allocDoc = await allocationRef.get();

      if (!allocDoc.exists) {
        return res.status(404).json({ error: `Allocation with ID ${allocationId} not found.` });
      }

      const allocationData = allocDoc.data();
      
      // Check authorization
      const userId = req.user.uid;
      const isAdmin = req.user.customClaims?.admin === true;
      const isOwner = allocationData.userId === userId;
      
      if (!isAdmin && !isOwner) {
        return res.status(403).json({ error: "Forbidden: You do not have permission to modify this allocation." });
      }

      // Use Firestore transaction for atomic operations (prevents race conditions)
      await db.runTransaction(async (transaction) => {
        const freshAllocDoc = await transaction.get(allocationRef);
        if (!freshAllocDoc.exists) {
          throw new Error("Allocation no longer exists");
        }

        transaction.set(db.collection("resolved_conflicts").doc(), {
          allocationId,
          conflictDetails: conflictDetails || "No details provided",
          date,
          startTime,
          endTime,
          resolvedAt: firestoreAdmin.firestore.FieldValue.serverTimestamp(),
          resolvedBy: req.user.uid,
        });

        transaction.set(
          allocationRef,
          {
            conflict: false,
            status: "resolved",
            updatedAt: firestoreAdmin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      });

      return res.status(200).json({ message: "Conflict resolved and allocation updated." });
    } catch (error) {
      logger.error("🛑 Error in POST /resolve-conflict:", error);
      return res.status(500).json({ error: "Failed to resolve conflict." });
    }
  });

  // GET endpoint for fetching conflict info (requires authentication)
  app.get("/resolve-conflict", authenticateUser, async (req, res) => {
    try {
      const allocSnap = await db
        .collection("allocations")
        .where("conflict", "==", true)
        .orderBy("date", "desc")
        .limit(1)
        .get();

      if (allocSnap.empty) {
        return res.status(200).json({
          message:
            "No allocation with a conflict found. POST to this endpoint with allocationId, conflictDetails, date, startTime, and endTime in the JSON body to resolve a conflict.",
          requiredFields: ["allocationId", "conflictDetails", "date", "startTime", "endTime"],
          exampleBody: {
            allocationId: "abc123",
            conflictDetails: "Room double-booked",
            date: "2025-07-09",
            startTime: "10:00 AM",
            endTime: "12:00 PM",
          },
        });
      }

      const doc = allocSnap.docs[0];
      const data = doc.data();

      return res.status(200).json({
        message:
          "Sample conflict fetched from Firestore. Use these details in your POST request to resolve the conflict.",
        requiredFields: ["allocationId", "conflictDetails", "date", "startTime", "endTime"],
        exampleBody: {
          allocationId: doc.id,
          conflictDetails: data.conflictDetails || "No details provided",
          date: data.date,
          startTime: data.startTime,
          endTime: data.endTime,
        },
      });
    } catch (error) {
      logger.error("🛑 Error in GET /resolve-conflict:", error);
      return res.status(500).json({ error: "Failed to fetch conflict info from Firestore." });
    }
  });

  // GET allocations endpoint (requires authentication)
  app.get("/allocations", authenticateUser, async (req, res) => {
    try {
      // Only return allocations belonging to the authenticated user unless admin
      const userId = req.user.uid;
      const isAdmin = req.user.customClaims?.admin === true;
      
      let query;
      if (isAdmin) {
        query = db.collection("allocations");
      } else {
        query = db.collection("allocations").where("userId", "==", userId);
      }
      
      const snap = await query.get();
      const list = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
      return res.status(200).json(list);
    } catch (error) {
      logger.error("🛑 Error in GET /allocations:", error);
      return res.status(500).json({ error: "Failed to fetch allocations." });
    }
  });

  app.use((error, _req, res, _next) => {
    if (error instanceof SyntaxError && "body" in error) {
      return res.status(400).json({ error: "Invalid JSON in request body." });
    }

    logger.error("🛑 Unexpected middleware error:", error);
    return res.status(500).json({ error: "Internal server error." });
  });

  app.use((_req, res) => {
    res.status(404).json({ error: "Route not found." });
  });

  return app;
}

function initializeFirestore() {
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
    });
  }

  return admin.firestore();
}

function startServer() {
  if (!validateEnv()) {
    process.exit(1);
  }

  const db = initializeFirestore();
  const app = createApp({ db });
  const port = Number(process.env.PORT) || 3000;
  const host = process.env.HOST || "127.0.0.1"; // Bind to localhost by default for security

  const server = require("http").createServer(app);
  
  // Attach Socket.io server to HTTP server
  const io = app.get("io");
  io.attach(server);
  
  // Start Cron Job for processing waitlist every 5 minutes
  const waitlistCron = new CronJob(
    '*/5 * * * *', // Every 5 minutes
    () => {
      console.log("Running scheduled waitlist processing...");
      processWaitlist(db, console).catch(err => console.error("Waitlist processing error:", err));
    },
    null,
    true,
    'UTC'
  );
  
  waitlistCron.start();
  console.log("✅ Waitlist processing cron job started (every 5 minutes)");

  const serverInstance = server.listen(port, host, () => {
    console.log(`✅ AI Allocation server running on ${host}:${port}`);
    console.log(`📚 API Documentation available at http://${host}:${port}/api-docs`);
  });

  const shutdown = (signal) => {
    console.log(`Received ${signal}. Shutting down server...`);
    waitlistCron.stop();
    serverInstance.close(() => {
      console.log("Server shutdown complete.");
      process.exit(0);
    });
  };

  process.on("SIGINT", () => shutdown("SIGINT"));
  process.on("SIGTERM", () => shutdown("SIGTERM"));
  
  return { server: serverInstance, app, io };
}

if (require.main === module) {
  startServer();
}

module.exports = {
  createApp,
  validateResolveConflictPayload,
  validateEnv,
  authenticateUser,
  authorizeAllocationAccess,
  addToWaitlist,
  processWaitlist,
  getRoomDemandPrediction,
  logAuditAction,
  startServer,
};

const path = require("path");
const express = require("express");
const cors = require("cors");
const admin = require("firebase-admin");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");

require("dotenv").config({ path: path.resolve(__dirname, "../.env") });

const REQUIRED_ENV_VARS = ["GOOGLE_APPLICATION_CREDENTIALS"];

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

  app.get("/", (_req, res) => {
    res.status(200).json({
      message: "Welcome to the AI Allocation Server",
      status: "ok",
    });
  });

  app.get("/health", (_req, res) => {
    res.status(200).json({ status: "ok" });
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

  const server = app.listen(port, host, () => {
    console.log(`✅ AI Allocation server running on ${host}:${port}`);
  });

  const shutdown = (signal) => {
    console.log(`Received ${signal}. Shutting down server...`);
    server.close(() => {
      console.log("Server shutdown complete.");
      process.exit(0);
    });
  };

  process.on("SIGINT", () => shutdown("SIGINT"));
  process.on("SIGTERM", () => shutdown("SIGTERM"));
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
};

const path = require("path");
const crypto = require("crypto");
const express = require("express");
const cors = require("cors");
const admin = require("firebase-admin");

require("dotenv").config({ path: path.resolve(__dirname, "../.env") });

const REQUIRED_ENV_VARS = ["GOOGLE_APPLICATION_CREDENTIALS"];

function buildError(code, message, details, requestId) {
  return {
    error: {
      code,
      message,
      details: details || null,
      requestId,
    },
  };
}

function parseTime12h(value) {
  if (typeof value !== "string") return null;
  const match = value.trim().match(/^(\d{1,2}):(\d{2})\s([AP]M)$/);
  if (!match) return null;

  let hour = Number(match[1]);
  const minute = Number(match[2]);
  const meridiem = match[3];

  if (hour < 1 || hour > 12 || minute < 0 || minute > 59) return null;

  if (meridiem === "PM" && hour !== 12) hour += 12;
  if (meridiem === "AM" && hour === 12) hour = 0;

  return hour * 60 + minute;
}

function validateEnv(logger = console) {
  const missing = REQUIRED_ENV_VARS.filter((key) => !process.env[key]);

  if (missing.length > 0) {
    logger.error(`❌ Missing required environment variables: ${missing.join(", ")}`);
    return false;
  }

  if (process.env.NODE_ENV === "production" && !process.env.API_AUTH_TOKEN) {
    logger.error("❌ API_AUTH_TOKEN is required in production.");
    return false;
  }

  if (!process.env.OPENAI_API_KEY) {
    logger.warn("⚠️ OPENAI_API_KEY is missing; AI-powered features may be unavailable.");
  }

  return true;
}

function validateResolveConflictPayload(body) {
  if (!body || typeof body !== "object" || Array.isArray(body)) {
    return { valid: false, message: "Request body must be a JSON object." };
  }

  const requiredFields = ["allocationId", "date", "startTime", "endTime"];
  const missing = requiredFields.filter((field) => !body[field]);
  if (missing.length > 0) {
    return { valid: false, message: `Missing required fields: ${missing.join(", ")}.` };
  }

  const start = parseTime12h(body.startTime);
  const end = parseTime12h(body.endTime);
  if (start === null || end === null) {
    return { valid: false, message: "Invalid time format. Use HH:MM AM/PM." };
  }
  if (end <= start) {
    return { valid: false, message: "endTime must be later than startTime." };
  }

  return { valid: true };
}

function createApp({ db, firestoreAdmin = admin, logger = console }) {
  const app = express();

  app.use(cors());
  app.use(express.json({ limit: "1mb" }));
  app.use(express.urlencoded({ extended: false }));

  app.use((req, res, next) => {
    req.requestId = crypto.randomUUID();
    res.setHeader("X-Request-Id", req.requestId);
    logger.info(`→ ${req.method} ${req.originalUrl} [${req.requestId}]`);
    next();
  });

  app.use((req, res, next) => {
    const configuredToken = process.env.API_AUTH_TOKEN;
    if (!configuredToken) return next();

    const authHeader = req.headers.authorization || "";
    const token = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : "";
    if (token !== configuredToken) {
      return res
        .status(401)
        .json(buildError("UNAUTHORIZED", "Missing or invalid auth token.", null, req.requestId));
    }

    next();
  });

  app.get("/", (req, res) => {
    res.status(200).json({ message: "Welcome to the AI Allocation Server", status: "ok", requestId: req.requestId });
  });

  app.get("/health", (req, res) => {
    res.status(200).json({ status: "ok", requestId: req.requestId });
  });

  app.post("/resolve-conflict", async (req, res) => {
    const payloadCheck = validateResolveConflictPayload(req.body);
    if (!payloadCheck.valid) {
      return res.status(400).json(buildError("BAD_REQUEST", payloadCheck.message, null, req.requestId));
    }

    const { allocationId, conflictDetails, date, startTime, endTime } = req.body;

    try {
      const allocationRef = db.collection("allocations").doc(allocationId);
      const resolvedRef = db.collection("resolved_conflicts").doc();

      await db.runTransaction(async (transaction) => {
        const allocDoc = await transaction.get(allocationRef);
        if (!allocDoc.exists) {
          const notFoundError = new Error(`Allocation with ID ${allocationId} not found.`);
          notFoundError.code = "NOT_FOUND";
          throw notFoundError;
        }

        transaction.set(resolvedRef, {
          allocationId,
          conflictDetails: conflictDetails || "No details provided",
          date,
          startTime,
          endTime,
          resolvedAt: firestoreAdmin.firestore.FieldValue.serverTimestamp(),
          resolvedBy: "API",
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

      return res.status(200).json({ message: "Conflict resolved and allocation updated.", requestId: req.requestId });
    } catch (error) {
      if (error.code === "NOT_FOUND") {
        return res.status(404).json(buildError("NOT_FOUND", error.message, null, req.requestId));
      }
      logger.error("🛑 Error in POST /resolve-conflict:", error);
      return res
        .status(500)
        .json(buildError("INTERNAL_ERROR", "Failed to resolve conflict.", error.message, req.requestId));
    }
  });

  app.get("/resolve-conflict", async (req, res) => {
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
          requestId: req.requestId,
        });
      }

      const doc = allocSnap.docs[0];
      const data = doc.data();

      return res.status(200).json({
        message: "Sample conflict fetched from Firestore. Use these details in your POST request to resolve the conflict.",
        requiredFields: ["allocationId", "conflictDetails", "date", "startTime", "endTime"],
        exampleBody: {
          allocationId: doc.id,
          conflictDetails: data.conflictDetails || "No details provided",
          date: data.date,
          startTime: data.startTime,
          endTime: data.endTime,
        },
        requestId: req.requestId,
      });
    } catch (error) {
      logger.error("🛑 Error in GET /resolve-conflict:", error);
      return res
        .status(500)
        .json(buildError("INTERNAL_ERROR", "Failed to fetch conflict info from Firestore.", error.message, req.requestId));
    }
  });

  app.get("/allocations", async (req, res) => {
    try {
      const limit = Math.min(Math.max(Number(req.query.limit) || 50, 1), 200);
      const snap = await db.collection("allocations").limit(limit).get();
      const list = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
      return res.status(200).json({ items: list, limit, count: list.length, requestId: req.requestId });
    } catch (error) {
      logger.error("🛑 Error in GET /allocations:", error);
      return res
        .status(500)
        .json(buildError("INTERNAL_ERROR", "Failed to fetch allocations.", error.message, req.requestId));
    }
  });

  app.use((error, req, res, _next) => {
    if (error instanceof SyntaxError && "body" in error) {
      return res.status(400).json(buildError("BAD_JSON", "Invalid JSON in request body.", null, req.requestId));
    }

    logger.error("🛑 Unexpected middleware error:", error);
    return res
      .status(500)
      .json(buildError("INTERNAL_ERROR", "Internal server error.", error.message, req.requestId));
  });

  app.use((req, res) => {
    res.status(404).json(buildError("NOT_FOUND", "Route not found.", null, req.requestId));
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

  const server = app.listen(port, () => {
    console.log(`✅ AI Allocation server running on port ${port}`);
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
  parseTime12h,
  validateResolveConflictPayload,
  validateEnv,
  buildError,
};

const path = require("path");
const express = require("express");
const cors = require("cors");
const admin = require("firebase-admin");

require("dotenv").config({ path: path.resolve(__dirname, "../.env") });

const REQUIRED_ENV_VARS = ["GOOGLE_APPLICATION_CREDENTIALS"];

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

  return { valid: true };
}

function createApp({ db, firestoreAdmin = admin, logger = console }) {
  const app = express();

  app.use(cors());
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

  app.post("/resolve-conflict", async (req, res) => {
    const payloadCheck = validateResolveConflictPayload(req.body);
    if (!payloadCheck.valid) {
      return res.status(400).json({ error: payloadCheck.message });
    }

    const { allocationId, conflictDetails, date, startTime, endTime } = req.body;

    try {
      const allocationRef = db.collection("allocations").doc(allocationId);
      const allocDoc = await allocationRef.get();

      if (!allocDoc.exists) {
        return res.status(404).json({ error: `Allocation with ID ${allocationId} not found.` });
      }

      await db.collection("resolved_conflicts").add({
        allocationId,
        conflictDetails: conflictDetails || "No details provided",
        date,
        startTime,
        endTime,
        resolvedAt: firestoreAdmin.firestore.FieldValue.serverTimestamp(),
        resolvedBy: "API",
      });

      await allocationRef.set(
        {
          conflict: false,
          status: "resolved",
          updatedAt: firestoreAdmin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      return res.status(200).json({ message: "Conflict resolved and allocation updated." });
    } catch (error) {
      logger.error("🛑 Error in POST /resolve-conflict:", error);
      return res.status(500).json({ error: "Failed to resolve conflict." });
    }
  });

  app.get("/resolve-conflict", async (_req, res) => {
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

  app.get("/allocations", async (_req, res) => {
    try {
      const snap = await db.collection("allocations").get();
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
  validateResolveConflictPayload,
  validateEnv,
};

// index.js

// 1. Load environment variables
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });
console.log("GOOGLE_APPLICATION_CREDENTIALS:", process.env.GOOGLE_APPLICATION_CREDENTIALS);
if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error("❌ GOOGLE_APPLICATION_CREDENTIALS is not set in .env file!");
  process.exit(1);
}
if (!process.env.OPENAI_API_KEY) {
  console.warn("⚠️ OPENAI_API_KEY is missing from environment variables!");
}

// 2. Initialize Firebase Admin
const admin = require("firebase-admin");
admin.initializeApp({
  credential: admin.credential.applicationDefault(), // Uses GOOGLE_APPLICATION_CREDENTIALS env var
});
const db = admin.firestore();

// 3. Initialize OpenAI client
const { Configuration, OpenAIApi } = require("openai");
const openai = new OpenAIApi(
  new Configuration({ apiKey: process.env.OPENAI_API_KEY })
);

// 4. Create Express app
const express = require("express");
const cors = require("cors");
const app = express();
app.use(cors());

// 5. Body parsers with error handling
app.use((req, res, next) => {
  if (
    req.headers["content-type"] &&
    req.headers["content-type"].includes("application/json")
  ) {
    express.json()(req, res, (err) => {
      if (err) {
        console.error("Invalid JSON received:", err);
        return res.status(400).json({ error: "Invalid JSON in request body." });
      }
      next();
    });
  } else {
    next();
  }
});
app.use(express.urlencoded({ extended: false }));

// 6. Debug middleware: log method, URL, headers, and parsed body
app.use((req, res, next) => {
  console.log(`→ ${req.method} ${req.originalUrl}`);
  console.log("   Content-Type:", req.headers["content-type"]);
  console.log("   Body:", req.body);
  next();
});

// 7. Routes

// 7.1 Root
app.get("/", (req, res) => {
  res.send("Welcome to the AI Allocation Server");
});

// 7.2 Resolve-conflict POST
app.post("/resolve-conflict", async (req, res) => {
  try {
    if (!req.body || typeof req.body !== "object") {
      return res.status(400).json({
        error: "Request body is missing or invalid. Ensure you are sending JSON with Content-Type: application/json",
      });
    }

    const { allocationId, conflictDetails, date, startTime, endTime } = req.body;

    if (!allocationId || !date || !startTime || !endTime) {
      return res.status(400).json({ error: "Missing required fields: allocationId, date, startTime, endTime." });
    }

    console.log(`Checking allocation document with ID: ${allocationId}`);
    const allocationRef = db.collection("allocations").doc(allocationId);
    const allocDoc = await allocationRef.get();

    if (!allocDoc.exists) {
      console.log(`Allocation document ${allocationId} not found`);
      return res.status(404).json({ error: `Allocation with ID ${allocationId} not found.` });
    }

    console.log("Adding to resolved_conflicts collection");
    await db.collection("resolved_conflicts").add({
      allocationId,
      conflictDetails: conflictDetails || "No details provided",
      date,
      startTime,
      endTime,
      resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
      resolvedBy: "API",
    });

    console.log("Updating allocation document");
    await allocationRef.set(
      {
        conflict: false,
        status: "resolved",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    res.status(200).json({ message: "Conflict resolved and allocation updated." });
  } catch (err) {
    console.error("🛑 Error in /resolve-conflict:", err);
    res.status(500).json({ error: err.message || "Server error." });
  }
});

// 7.2.1 Resolve-conflict GET method (fetches real data)
app.get("/resolve-conflict", async (req, res) => {
  try {
    console.log("Fetching allocation with conflict");
    const allocSnap = await db
      .collection("allocations")
      .where("conflict", "==", true)
      .orderBy("date", "desc")
      .limit(1)
      .get();

    if (allocSnap.empty) {
      return res.status(200).json({
        message: "No allocation with a conflict found. POST to this endpoint with allocationId, conflictDetails, date, startTime, and endTime in the JSON body to resolve a conflict.",
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

    res.status(200).json({
      message: "Sample conflict fetched from Firestore. Use these details in your POST request to resolve the conflict.",
      requiredFields: ["allocationId", "conflictDetails", "date", "startTime", "endTime"],
      exampleBody: {
        allocationId: doc.id,
        conflictDetails: data.conflictDetails || "No details provided",
        date: data.date,
        startTime: data.startTime,
        endTime: data.endTime,
      },
    });
  } catch (err) {
    console.error("Error fetching conflict info:", err);
    res.status(500).json({ error: "Failed to fetch conflict info from Firestore." });
  }
});

// 7.3 List allocations
app.get("/allocations", async (req, res) => {
  try {
    console.log("Fetching all allocations");
    const snap = await db.collection("allocations").get();
    const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    res.status(200).json(list);
  } catch (err) {
    console.error("Error fetching allocations:", err);
    res.status(500).json({ error: "Failed to fetch allocations." });
  }
});

// 8. 404 handler
app.use((req, res) => res.status(404).send("Page not found"));

// 9. Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () =>
  console.log(`✅ AI Allocation server running on port ${PORT}`)
);
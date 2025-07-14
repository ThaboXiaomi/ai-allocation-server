<<<<<<< HEAD
// index.js
=======
// Ensure .env is loaded from the correct directory
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });

>>>>>>> 3abba11b53f77c26a2d007aa4ac72aeed6aff7dd

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

<<<<<<< HEAD
// 3. Initialize OpenAI client
const { OpenAI } = require("openai");
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

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
=======

const { Configuration, OpenAIApi } = require("openai");
console.log("Loaded OPENAI_API_KEY:", process.env.OPENAI_API_KEY ? "[HIDDEN]" : undefined);
if (!process.env.OPENAI_API_KEY) {
  console.warn("⚠️ OPENAI_API_KEY is missing from environment variables!");
}
const openai = new OpenAIApi(
  new Configuration({
    apiKey: process.env.OPENAI_API_KEY,
  })
);

const app = express();
app.use(cors());
app.use(express.json());

// Root GET route
app.get('/', (req, res) => {
  res.send('Welcome to the AI Allocation Server');
});

// POST endpoint with improved error handling
app.post("/resolve-conflict", async (req, res) => {
  try {
    const { allocationId, conflictDetails, date, startTime, endTime } = req.body;

    if (!allocationId || !date || !startTime || !endTime) {
      console.error("Missing required fields:", req.body);
      return res.status(400).json({ error: "Missing required fields in request body." });
    }

    // 1. Fetch available rooms
    const roomsSnapshot = await db.collection("lecture_rooms")
      .where("status", "==", "Available")
      .get();
    const allRooms = roomsSnapshot.docs.map(doc => doc.data().name);
    if (allRooms.length === 0) {
      console.error("No rooms marked as available in Firestore.");
      return res.status(400).json({ error: "No rooms marked as available." });
    }

    // 2. Fetch timetables with overlapping time
    const timetableSnapshot = await db.collection("timetables")
      .where("date", "==", date)
      .get();

    const overlappingRooms = [];
    timetableSnapshot.forEach(doc => {
      const t = doc.data();
      if (!(endTime <= t.startTime || startTime >= t.endTime)) {
        overlappingRooms.push(t.room);
      }
    });

    // 3. Filter available rooms
    const availableRooms = allRooms.filter(room => !overlappingRooms.includes(room));
    if (availableRooms.length === 0) {
      console.error("No rooms available for the specified time.");
      return res.status(400).json({ error: "No rooms available for the specified time." });
    }

    const suggestedVenue = availableRooms[0];

    // 4. Update timetable allocation
    await db.collection("timetables").doc(allocationId).update({
      resolvedVenue: suggestedVenue,
      conflict: false,
      status: "diverted"
    });

    // 5. Notify all relevant users (lecturer, students, admins) if timetable exists
    const timetableDoc = await db.collection("timetables").doc(allocationId).get();
    if (!timetableDoc.exists) {
      console.warn("Timetable not found for allocation:", allocationId);
    } else {
      const timetableData = timetableDoc.data();

      // Notify lecturer
      await db.collection("notifications").add({
        type: "conflict",
        title: `Scheduling Conflict for ${timetableData.courseCode ?? "Your Lecture"}`,
        message: `A scheduling conflict occurred. Your lecture has been moved to ${suggestedVenue}. Please check the new venue details.`,
        lecturerId: timetableData.lecturerId ?? "",
        timetableId: allocationId,
        isRead: false,
        time: new Date().toISOString(),
      });

      // Notify all students in the diverted class
      if (Array.isArray(timetableData.students)) {
        for (const studentId of timetableData.students) {
          await db.collection("notifications").add({
            type: "conflict",
            title: `Lecture Conflict Notification`,
            message: `A scheduling conflict occurred for ${timetableData.courseCode ?? "a course"}. Your lecture has been moved to ${suggestedVenue}. Please check the new venue details.`,
            studentId: studentId,
            timetableId: allocationId,
            isRead: false,
            time: new Date().toISOString(),
          });
        }
      }

      // Notify all admins
      const adminsSnapshot = await db.collection("users").where("role", "==", "admin").get();
      for (const adminDoc of adminsSnapshot.docs) {
        await db.collection("notifications").add({
          type: "conflict",
          title: `Lecture Conflict Detected`,
          message: `A scheduling conflict was detected and resolved for ${timetableData.courseCode ?? "a course"}. The lecture has been moved to ${suggestedVenue}.`,
          adminId: adminDoc.id,
          timetableId: allocationId,
          isRead: false,
          time: new Date().toISOString(),
        });
      }
    }

    // 6. Log resolution
    await db.collection("decisionLogs").add({
      allocationId,
      description: `Conflict resolved. Suggested venue: ${suggestedVenue}`,
      conflictDetails,
      suggestedVenue,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      resolvedBy: "AI",
      status: "resolved"
    });

    res.json({ resolvedVenue: suggestedVenue });

  } catch (error) {
    console.error("🛑 Error in /resolve-conflict:", error);
    res.status(500).json({ error: error.message || "Unknown server error occurred." });
  }
});

// Add this after your other routes, before the catch-all 404
app.get('/allocations', async (req, res) => {
  try {
    const snapshot = await db.collection('allocations').get();
    const allocations = snapshot.docs.map(doc => ({
      ...doc.data(),
      id: doc.id,
    }));
    res.json(allocations);
  } catch (error) {
    console.error('Error fetching allocations:', error);
    res.status(500).json({ error: 'Failed to fetch allocations' });
>>>>>>> 3abba11b53f77c26a2d007aa4ac72aeed6aff7dd
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
<<<<<<< HEAD
app.listen(PORT, () =>
  console.log(`✅ AI Allocation server running on port ${PORT}`)
);

const { google } = require("googleapis");
const SCOPES = ["https://www.googleapis.com/auth/cloud-platform"];

// Utility function to get Google access token from service account
function getAccessToken() {
  return new Promise(function(resolve, reject) {
    const key = require('D:\\PC USER\\Documents\\School\\Final Year Project\\lecture_room_allocator\\campus-venue-navigator-firebase-adminsdk-fbsvc-60112e76dd.json');
    const jwtClient = new google.auth.JWT(
      key.client_email,
      null,
      key.private_key,
      SCOPES,
      null
    );
    jwtClient.authorize(function(err, tokens) {
      if (err) {
        reject(err);
        return;
      }
      resolve(tokens.access_token);
    });
  });
}

// Google OAuth2 setup (replace with your actual credentials)
const oauth2Client = new google.auth.OAuth2(
  process.env.GOOGLE_CLIENT_ID,      // YOUR_CLIENT_ID
  process.env.GOOGLE_CLIENT_SECRET,  // YOUR_CLIENT_SECRET
  process.env.GOOGLE_REDIRECT_URL    // YOUR_REDIRECT_URL
);

// generate a url that asks permissions for Blogger and Google Calendar scopes
const scopes = [
  'https://www.googleapis.com/auth/blogger',
  'https://www.googleapis.com/auth/calendar'
];

const url = oauth2Client.generateAuthUrl({
  // 'online' (default) or 'offline' (gets refresh_token)
  access_type: 'offline',

  // If you only need one scope, you can pass it as a string
  scope: scopes
=======
app.listen(PORT, () => {
  console.log(`✅ AI Allocation server running on port ${PORT}`);
>>>>>>> 3abba11b53f77c26a2d007aa4ac72aeed6aff7dd
});
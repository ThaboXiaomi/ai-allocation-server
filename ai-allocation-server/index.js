// index.js

// 1. Load environment variables
const path = require("path");
 require("dotenv").config({ path: path.resolve(__dirname, "../.env") }); // Make sure your .env contains GOOGLE_APPLICATION_CREDENTIALS
console.log("GOOGLE_APPLICATION_CREDENTIALS:", process.env.GOOGLE_APPLICATION_CREDENTIALS);



// 3. Initialize Firebase Admin
const admin = require("firebase-admin");
admin.initializeApp({
  credential: admin.credential.applicationDefault(), // Uses GOOGLE_APPLICATION_CREDENTIALS env var
});
const db = admin.firestore();

// 4. Initialize OpenAI client
const { Configuration, OpenAIApi } = require("openai");
if (!process.env.OPENAI_API_KEY) {
  console.warn("⚠️ OPENAI_API_KEY is missing from environment variables!");
}
const openai = new OpenAIApi(
  new Configuration({ apiKey: process.env.OPENAI_API_KEY })
);

// 5. Create Express app
const express = require("express");
const cors = require("cors");
const app = express();
app.use(cors());

// 6. Body parsers with error handling
app.use((req, res, next) => {
  if (
    req.headers['content-type'] &&
    req.headers['content-type'].includes('application/json')
  ) {
    express.json()(req, res, (err) => {
      if (err) {
        console.error('Invalid JSON received:', err);
        return res.status(400).json({ error: 'Invalid JSON in request body.' });
      }
      next();
    });
  } else {
    next();
  }
});
app.use(express.urlencoded({ extended: false }));

// 7. Debug middleware: log method, URL, headers, and parsed body
app.use((req, res, next) => {
  console.log(`→ ${req.method} ${req.originalUrl}`);
  console.log("   Content-Type:", req.headers["content-type"]);
  console.log("   Body:", req.body);
  next();
});

// 8. Routes

// 8.1 Root
app.get("/", (req, res) => {
  res.send("Welcome to the AI Allocation Server");
});

// 8.2 Resolve-conflict
app.post("/resolve-conflict", async (req, res) => {
  try {
    if (!req.body || typeof req.body !== "object") {
      console.error("No JSON body:", req.body);
      return res.status(400).json({
        error:
          "Request body is missing or invalid. Ensure you are sending JSON with Content-Type: application/json",
      });
    }

    const { allocationId, conflictDetails, date, startTime, endTime } =
      req.body;

    if (!allocationId || !date || !startTime || !endTime) {
      console.error("Missing required fields:", req.body);
      return res
        .status(400)
        .json({ error: "Missing required fields in request body." });
    }

    // Fetch available rooms
    const roomsSnap = await db
      .collection("lecture_rooms")
      .where("status", "==", "Available")
      .get();
    const allRooms = roomsSnap.docs
      .map((d) => d.data().name)
      .filter((n) => typeof n === "string" && n.trim());

    if (!allRooms.length) {
      console.error("No available rooms.");
      return res
        .status(400)
        .json({ error: "No rooms marked as available in Firestore." });
    }

    // Fetch same-day timetables
    const ttSnap = await db
      .collection("timetables")
      .where("date", "==", date)
      .get();

    const parseTime = (s) => {
      const [time, mod] = s.split(" ");
      let [h, m] = time.split(":").map(Number);
      if (mod === "PM" && h !== 12) h += 12;
      if (mod === "AM" && h === 12) h = 0;
      return h * 60 + m;
    };

    const reqStart = parseTime(startTime);
    const reqEnd = parseTime(endTime);

    const overlapping = [];
    ttSnap.forEach((doc) => {
      const t = doc.data();
      if (typeof t.startTime !== "string" || typeof t.endTime !== "string")
        return;
      const tStart = parseTime(t.startTime);
      const tEnd = parseTime(t.endTime);
      if (!(reqEnd <= tStart || reqStart >= tEnd)) overlapping.push(t.room);
    });

    const availableRooms = allRooms.filter((r) => !overlapping.includes(r));
    if (!availableRooms.length) {
      console.error("No rooms free at that time.");
      return res
        .status(400)
        .json({ error: "No rooms available for the specified time." });
    }

    const suggestedVenue = availableRooms[0];

    // Update timetable (use set with merge to avoid overwriting)
    await db.collection("timetables").doc(allocationId).set({
      resolvedVenue: suggestedVenue,
      conflict: false,
      status: "diverted",
    }, { merge: true });

    // Notify stakeholders
    const ttDoc = await db.collection("timetables").doc(allocationId).get();
    if (ttDoc.exists) {
      const data = ttDoc.data();

      await db.collection("notifications").add({
        type: "conflict",
        title: `Scheduling Conflict for ${data.courseCode || "Your Lecture"}`,
        message: `Your lecture has been moved to ${suggestedVenue}.`,
        lecturerId: data.lecturerId || "",
        timetableId: allocationId,
        isRead: false,
        time: new Date().toISOString(),
      });

      if (Array.isArray(data.students)) {
        for (const sid of data.students) {
          await db.collection("notifications").add({
            type: "conflict",
            title: "Lecture Conflict Notification",
            message: `Your lecture has been moved to ${suggestedVenue}.`,
            studentId: sid,
            timetableId: allocationId,
            isRead: false,
            time: new Date().toISOString(),
          });
        }
      }

      const adminsSnap = await db
        .collection("users")
        .where("role", "==", "admin")
        .get();
      for (const ad of adminsSnap.docs) {
        await db.collection("notifications").add({
          type: "conflict",
          title: "Lecture Conflict Detected",
          message: `Conflict resolved. Lecture moved to ${suggestedVenue}.`,
          adminId: ad.id,
          timetableId: allocationId,
          isRead: false,
          time: new Date().toISOString(),
        });
      }
    }

    // Log decision
    await db.collection("decisionLogs").add({
      allocationId,
      description: `Conflict resolved. Venue: ${suggestedVenue}`,
      conflictDetails,
      suggestedVenue,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      resolvedBy: "AI",
      status: "resolved",
    });

    res.json({ resolvedVenue: suggestedVenue });
  } catch (err) {
    console.error("🛑 Error in /resolve-conflict:", err);
    res.status(500).json({ error: err.message || "Server error." });
  }
});

// 8.2.1 Resolve-conflict GET method (fetches real data)
app.get("/resolve-conflict", async (req, res) => {
  try {
    // Fetch the latest timetable document with a conflict (if any)
    const ttSnap = await db
      .collection("timetables")
      .where("conflict", "==", true)
      .orderBy("date", "desc")
      .limit(1)
      .get();

    if (ttSnap.empty) {
      return res.json({
        message: "No timetable with a conflict found. POST to this endpoint with allocationId, conflictDetails, date, startTime, and endTime in the JSON body to resolve a conflict.",
        requiredFields: ["allocationId", "conflictDetails", "date", "startTime", "endTime"],
        exampleBody: {
          allocationId: "abc123",
          conflictDetails: "Room double-booked",
          date: "2025-07-09",
          startTime: "10:00 AM",
          endTime: "12:00 PM"
        }
      });
    }

    const doc = ttSnap.docs[0];
    const data = doc.data();

    res.json({
      message: "Sample conflict fetched from Firestore. Use these details in your POST request to resolve the conflict.",
      requiredFields: ["allocationId", "conflictDetails", "date", "startTime", "endTime"],
      exampleBody: {
        allocationId: doc.id,
        conflictDetails: data.conflictDetails || "No details provided",
        date: data.date,
        startTime: data.startTime,
        endTime: data.endTime
      }
    });
  } catch (err) {
    console.error("Error fetching conflict info:", err);
    res.status(500).json({ error: "Failed to fetch conflict info from Firestore." });
  }
});

// 8.3 List allocations
app.get("/allocations", async (req, res) => {
  try {
    const snap = await db.collection("allocations").get();
    const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    res.json(list);
  } catch (err) {
    console.error("Error fetching allocations:", err);
    res.status(500).json({ error: "Failed to fetch allocations." });
  }
});

// 9. 404 handler
app.use((req, res) => res.status(404).send("Page not found"));

// 10. Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () =>
  console.log(`✅ AI Allocation server running on port ${PORT}`)
);
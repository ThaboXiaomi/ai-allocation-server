// Ensure .env is loaded from the correct directory
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });


const express = require("express");
const cors = require("cors");
const admin = require("firebase-admin");

const serviceAccount = require("../campus-venue-navigator-firebase-adminsdk-fbsvc-60112e76dd.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();


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
  }
});

// Catch-all for undefined routes
app.use((req, res) => {
  res.status(404).send('Page not found');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`✅ AI Allocation server running on port ${PORT}`);
});
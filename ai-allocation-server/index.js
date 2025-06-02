require("dotenv").config(); // <-- Add this line at the very top

const express = require("express");
const cors = require("cors");
const admin = require("firebase-admin");

// Use your actual service account file name here:
const serviceAccount = require("../campus-venue-navigator-firebase-adminsdk-fbsvc-60112e76dd.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();

// OpenAI setup
const { Configuration, OpenAIApi } = require("openai");
const openai = new OpenAIApi(
  new Configuration({
    apiKey: process.env.OPENAI_API_KEY,
  })
);

const app = express();
app.use(cors());
app.use(express.json());

// Endpoint to resolve allocation conflict
app.post("/resolve-conflict", async (req, res) => {
  try {
    const { allocationId, conflictDetails } = req.body;
    const response = await openai.createChatCompletion({
      model: "gpt-4",
      messages: [
        {
          role: "system",
          content: `Suggest a new venue for the following class schedule conflict: ${conflictDetails}`,
        },
      ],
    });
    const suggestion = response.choices[0].message.content;

    // Update Firestore
    await db.collection("allocations").doc(allocationId).update({
      resolvedVenue: suggestion,
      conflict: false,
    });

    res.json({ resolvedVenue: suggestion });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`AI Allocation server running on port ${PORT}`);
});
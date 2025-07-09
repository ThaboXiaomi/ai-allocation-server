
import os
from flask import Flask, request, jsonify
from google.cloud import firestore
from dotenv import load_dotenv
import openai

# Load environment variables
load_dotenv()

app = Flask(__name__)


# Firestore client
firestore_creds = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
if not firestore_creds:
    raise RuntimeError("GOOGLE_APPLICATION_CREDENTIALS not set in .env")
db = firestore.Client.from_service_account_json(firestore_creds)

# OpenAI API setup
openai_api_key = os.getenv("OPENAI_API_KEY")
if not openai_api_key:
    print("Warning: OPENAI_API_KEY not set in .env. OpenAI features will be disabled.")
else:
    openai.api_key = openai_api_key

@app.route("/decision-logs", methods=["GET"])
def get_decision_logs():
    try:
        snap = db.collection("decisionLogs").stream()
        logs = [{"id": doc.id, **doc.to_dict()} for doc in snap]
        return jsonify(logs)
    except Exception as e:
        return jsonify({"error": "Failed to fetch decision logs."}), 500

# Load environment variables
load_dotenv()

app = Flask(__name__)

# Firestore client
firestore_creds = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
if not firestore_creds:
    raise RuntimeError("GOOGLE_APPLICATION_CREDENTIALS not set in .env")
db = firestore.Client.from_service_account_json(firestore_creds)

@app.route("/")
def index():
    return "Welcome to the AI Allocation Server"

@app.route("/resolve-conflict", methods=["POST"])
def resolve_conflict():
    data = request.get_json()
    required = ["allocationId", "date", "startTime", "endTime"]
    if not data or not all(k in data and data[k] for k in required):
        return jsonify({"error": "Missing required fields in request body."}), 400

    allocation_id = data["allocationId"]
    conflict_details = data.get("conflictDetails", "")
    date = data["date"]
    start_time = data["startTime"]
    end_time = data["endTime"]

    def parse_time(s):
        # Expects format: 'HH:MM AM/PM'
        import re
        match = re.match(r"(\d{1,2}):(\d{2}) ([AP]M)", s)
        if not match:
            return None
        h, m, mod = int(match.group(1)), int(match.group(2)), match.group(3)
        if mod == "PM" and h != 12:
            h += 12
        if mod == "AM" and h == 12:
            h = 0
        return h * 60 + m

    req_start = parse_time(start_time)
    req_end = parse_time(end_time)
    if req_start is None or req_end is None:
        return jsonify({"error": "Invalid time format. Use HH:MM AM/PM."}), 400

    # Fetch available rooms
    rooms_snap = db.collection("lecture_rooms").where("status", "==", "Available").stream()
    all_rooms = [r.to_dict().get("name") for r in rooms_snap if r.to_dict().get("name")]
    if not all_rooms:
        return jsonify({"error": "No rooms marked as available in Firestore."}), 400

    # Fetch same-day timetables
    tt_snap = db.collection("timetables").where("date", "==", date).stream()
    overlapping = []
    for doc in tt_snap:
        t = doc.to_dict()
        t_start = parse_time(t.get("startTime", ""))
        t_end = parse_time(t.get("endTime", ""))
        if t_start is None or t_end is None:
            continue
        if not (req_end <= t_start or req_start >= t_end):
            overlapping.append(t.get("room"))


    available_rooms = [r for r in all_rooms if r not in overlapping]
    if not available_rooms:
        # Use OpenAI to suggest a message or alternative if no rooms are available
        if openai_api_key:
            prompt = f"No rooms are available for a lecture on {date} from {start_time} to {end_time}. Suggest a polite message or creative solution for the scheduling conflict."
            try:
                ai_response = openai.chat.completions.create(
                    model="gpt-3.5-turbo",
                    messages=[
                        {"role": "system", "content": "You are a helpful assistant."},
                        {"role": "user", "content": prompt}
                    ],
                    max_tokens=60
                )
                content = ai_response.choices[0].message.content
                suggestion = content.strip() if content is not None else "No suggestion available."
                return jsonify({"error": "No rooms available for the specified time.", "aiSuggestion": suggestion}), 400
            except Exception as e:
                return jsonify({"error": "No rooms available for the specified time.", "aiError": str(e)}), 400
        else:
            return jsonify({"error": "No rooms available for the specified time."}), 400

    # Optionally use OpenAI to help select a room (for demonstration, just pick the first, but you could use AI to rank or explain)
    suggested_venue = available_rooms[0]
    if openai_api_key and len(available_rooms) > 1:
        prompt = (
            f"Given the following available rooms: {', '.join(available_rooms)} for a lecture on {date} from {start_time} to {end_time}, "
            f"which room would you recommend and why? Just provide the room name."
        )
        try:
            ai_response = openai.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": "You are a helpful assistant."},
                    {"role": "user", "content": prompt}
                ],
                max_tokens=10
            )
            content = ai_response.choices[0].message.content
            ai_room = content.strip() if content is not None else ""
            if ai_room in available_rooms:
                suggested_venue = ai_room
        except Exception as e:
            pass  # Fallback to first available room if OpenAI fails

    # Update timetable
    db.collection("timetables").document(allocation_id).update({
        "resolvedVenue": suggested_venue,
        "conflict": False,
        "status": "diverted",
    })

    # Notify stakeholders
    tt_doc = db.collection("timetables").document(allocation_id).get()
    if tt_doc.exists:
        data_doc = tt_doc.to_dict()
        if data_doc is not None:
            # Lecturer notification
            db.collection("notifications").add({
                "type": "conflict",
                "title": f"Scheduling Conflict for {data_doc.get('courseCode', 'Your Lecture')}",
                "message": f"Your lecture has been moved to {suggested_venue}.",
                "lecturerId": data_doc.get("lecturerId", ""),
                "timetableId": allocation_id,
                "isRead": False,
                "time": firestore.SERVER_TIMESTAMP,
            })
            # Student notifications
            for sid in data_doc.get("students", []):
                db.collection("notifications").add({
                    "type": "conflict",
                    "title": "Lecture Conflict Notification",
                    "message": f"Your lecture has been moved to {suggested_venue}.",
                    "studentId": sid,
                    "timetableId": allocation_id,
                    "isRead": False,
                    "time": firestore.SERVER_TIMESTAMP,
                })
            # Admin notifications
            admins_snap = db.collection("users").where("role", "==", "admin").stream()
            for ad in admins_snap:
                db.collection("notifications").add({
                    "type": "conflict",
                    "title": "Lecture Conflict Detected",
                    "message": f"Conflict resolved. Lecture moved to {suggested_venue}.",
                    "adminId": ad.id,
                    "timetableId": allocation_id,
                    "isRead": False,
                    "time": firestore.SERVER_TIMESTAMP,
                })

    # Log decision
    db.collection("decisionLogs").add({
        "allocationId": allocation_id,
        "description": f"Conflict resolved. Venue: {suggested_venue}",
        "conflictDetails": conflict_details,
        "suggestedVenue": suggested_venue,
        "timestamp": firestore.SERVER_TIMESTAMP,
        "resolvedBy": "AI",
        "status": "resolved",
    })

    return jsonify({"resolvedVenue": suggested_venue})

@app.route("/allocations", methods=["GET"])
def get_allocations():
    try:
        snap = db.collection("allocations").stream()
        allocations = [{"id": doc.id, **doc.to_dict()} for doc in snap]
        return jsonify(allocations)
    except Exception as e:
        return jsonify({"error": "Failed to fetch allocations."}), 500

if __name__ == "__main__":
    app.run(debug=True)

import os
from flask import Flask, request, jsonify, make_response
from flask_cors import CORS
from google.cloud import firestore
from dotenv import load_dotenv
import openai
import random  # Add this at the top

# Load environment variables from .env
load_dotenv()

app = Flask(__name__)
CORS(app)

# Firestore setup
firestore_creds = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
if not firestore_creds or not os.path.exists(firestore_creds):
    raise RuntimeError("Invalid or missing GOOGLE_APPLICATION_CREDENTIALS path in .env")

db = firestore.Client.from_service_account_json(firestore_creds)

# OpenAI setup
openai_api_key = os.getenv("OPENAI_API_KEY")
if openai_api_key:
    openai.api_key = openai_api_key
else:
    print("⚠️ Warning: OPENAI_API_KEY not set. AI features will be disabled.")

@app.route("/")
def index():
    return "Welcome to the AI Allocation Server"

@app.route("/decision-logs", methods=["GET"])
def get_decision_logs():
    try:
        snap = db.collection("decisionLogs").stream()
        logs = [{"id": doc.id, **doc.to_dict()} for doc in snap]
        return jsonify(logs)
    except Exception as e:
        print("Error fetching decision logs:", e)
        return jsonify({"error": "Failed to fetch decision logs."}), 500

@app.route("/resolve-conflict", methods=['GET', 'POST', 'OPTIONS'])
def resolve_conflict():
    # Handle preflight OPTIONS request for CORS
    if request.method == 'OPTIONS':
        response = make_response()
        response.headers['Access-Control-Allow-Origin'] = '*'
        response.headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
        response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
        response.status_code = 200
        return response

    try:
        data = request.get_json(force=True)
    except Exception:
        response = jsonify({"error": "Invalid or malformed JSON."})
        response.headers['Access-Control-Allow-Origin'] = '*'
        return response, 400

    required = ["allocationId", "date", "startTime", "endTime"]
    if not data or not all(k in data and data[k] for k in required):
        return jsonify({"error": "Missing required fields in request body."}), 400

    allocation_id = data["allocationId"]
    conflict_details = data.get("conflictDetails", "")
    date = data["date"]
    start_time = data["startTime"]
    end_time = data["endTime"]

    def parse_time(s):
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

    try:
        # ✅ Fixed: use positional args in .where()
        rooms_snap = db.collection("lecture_rooms").where("status", "==", "Available").stream()
        all_rooms = [r.to_dict().get("name") for r in rooms_snap if r.to_dict().get("name")]

        if not all_rooms:
            return jsonify({"error": "No rooms marked as available in Firestore."}), 400

        # ✅ Fixed: use positional args in .where()
        tt_snap = db.collection("timetables").where("date", "==", date).stream()
        overlapping = []
        for doc in tt_snap:
            if doc.id == allocation_id:
                continue  # Skip the allocation being resolved
            t = doc.to_dict()
            t_start = parse_time(t.get("startTime", ""))
            t_end = parse_time(t.get("endTime", ""))
            if t_start is None or t_end is None:
                continue
            if not (req_end <= t_start or req_start >= t_end):
                overlapping.append(t.get("room"))

        available_rooms = [r for r in all_rooms if r not in overlapping]
        if not available_rooms:
            if openai_api_key:
                try:
                    prompt = f"No rooms are available for a lecture on {date} from {start_time} to {end_time}. Suggest a polite message or creative solution."
                    ai_response = openai.chat.completions.create(
                        model="gpt-3.5-turbo",
                        messages=[
                            {"role": "system", "content": "You are a helpful assistant."},
                            {"role": "user", "content": prompt}
                        ],
                        max_tokens=60
                    )
                    suggestion = ai_response.choices[0].message.content.strip() if ai_response.choices and ai_response.choices[0].message.content else ""
                    return jsonify({
                        "error": "No rooms available for the specified time.",
                        "aiSuggestion": suggestion
                    }), 400
                except Exception as e:
                    return jsonify({
                        "error": "No rooms available.",
                        "aiError": str(e)
                    }), 400
            else:
                return jsonify({"error": "No rooms available for the specified time."}), 400

        # Suggest room using OpenAI (or pick randomly)
        suggested_venue = random.choice(available_rooms)
        if openai_api_key and len(available_rooms) > 1:
            try:
                prompt = (
                    f"Available rooms: {', '.join(available_rooms)} for {date} from {start_time} to {end_time}. "
                    f"Which one is best? Just give the name."
                )
                ai_response = openai.chat.completions.create(
                    model="gpt-3.5-turbo",
                    messages=[
                        {"role": "system", "content": "You are a helpful assistant."},
                        {"role": "user", "content": prompt}
                    ],
                    max_tokens=10
                )
                ai_room = ai_response.choices[0].message.content.strip() if ai_response.choices and ai_response.choices[0].message.content else ""
                if ai_room in available_rooms:
                    suggested_venue = ai_room
            except Exception:
                pass  # Use random if OpenAI fails

        # Update Firestore timetable document
        db.collection("timetables").document(allocation_id).update({
            "resolvedVenue": suggested_venue,
            "conflict": False,
            "status": "diverted"
        })

        # Notify stakeholders
        tt_doc = db.collection("timetables").document(allocation_id).get()
        if tt_doc.exists:
            data_doc = tt_doc.to_dict()
            if data_doc:
                # Notify lecturer
                db.collection("notifications").add({
                    "type": "conflict",
                    "title": f"Scheduling Conflict for {data_doc.get('courseCode', 'Your Lecture')}",
                    "message": f"Your lecture has been moved to {suggested_venue}.",
                    "lecturerId": data_doc.get("lecturerId", ""),
                    "timetableId": allocation_id,
                    "isRead": False,
                    "time": firestore.SERVER_TIMESTAMP
                })

                # Notify students
                for sid in data_doc.get("students", []):
                    db.collection("notifications").add({
                        "type": "conflict",
                        "title": "Lecture Conflict Notification",
                        "message": f"Your lecture has been moved to {suggested_venue}.",
                        "studentId": sid,
                        "timetableId": allocation_id,
                        "isRead": False,
                        "time": firestore.SERVER_TIMESTAMP
                    })

                # ✅ Fixed: use positional args in .where()
                admins_snap = db.collection("users").where("role", "==", "admin").stream()
                for ad in admins_snap:
                    db.collection("notifications").add({
                        "type": "conflict",
                        "title": "Lecture Conflict Detected",
                        "message": f"Conflict resolved. Lecture moved to {suggested_venue}.",
                        "adminId": ad.id,
                        "timetableId": allocation_id,
                        "isRead": False,
                        "time": firestore.SERVER_TIMESTAMP
                    })

        # Log decision
        db.collection("decisionLogs").add({
            "allocationId": allocation_id,
            "description": f"Conflict resolved. Venue: {suggested_venue}",
            "conflictDetails": conflict_details,
            "suggestedVenue": suggested_venue,
            "timestamp": firestore.SERVER_TIMESTAMP,
            "resolvedBy": "AI",
            "status": "resolved"
        })

        return_with_cors = jsonify({"resolvedVenue": suggested_venue})
        return_with_cors.headers['Access-Control-Allow-Origin'] = '*'
        return return_with_cors

    except Exception as e:
        print(f"Error in /resolve-conflict: {e}")
        response = jsonify({"error": "Internal server error", "details": str(e)})
        response.headers['Access-Control-Allow-Origin'] = '*'
        return response, 500

@app.route("/allocations", methods=["GET"])
def get_allocations():
    try:
        snap = db.collection("allocations").stream()
        allocations = [{"id": doc.id, **doc.to_dict()} for doc in snap]
        return jsonify(allocations)
    except Exception as e:
        print("Error fetching allocations:", e)
        return jsonify({"error": "Failed to fetch allocations."}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)

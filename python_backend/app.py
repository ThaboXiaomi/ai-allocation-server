import os
import random
import uuid

from dotenv import load_dotenv
from flask import Flask, jsonify, make_response, request, g
from flask_cors import CORS
from google.cloud import firestore
import openai

from conflict_utils import parse_time_12h, validate_resolve_conflict_payload

load_dotenv()


def build_error(code: str, message: str, request_id: str, details: str | None = None):
    return {
        "error": {
            "code": code,
            "message": message,
            "details": details,
            "requestId": request_id,
        }
    }


def create_app() -> Flask:
    app = Flask(__name__)
    CORS(app)

    firestore_creds = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    if not firestore_creds or not os.path.exists(firestore_creds):
        raise RuntimeError("Invalid or missing GOOGLE_APPLICATION_CREDENTIALS path in .env")

    db = firestore.Client.from_service_account_json(firestore_creds)

    app_env = os.getenv("APP_ENV", "development").lower()
    if app_env == "production" and not os.getenv("API_AUTH_TOKEN"):
        raise RuntimeError("API_AUTH_TOKEN is required when APP_ENV=production")

    openai_api_key = os.getenv("OPENAI_API_KEY")
    if openai_api_key:
        openai.api_key = openai_api_key
    else:
        print("⚠️ Warning: OPENAI_API_KEY not set. AI features will be disabled.")

    @app.before_request
    def assign_request_id_and_auth():
        g.request_id = str(uuid.uuid4())
        auth_token = os.getenv("API_AUTH_TOKEN")
        if not auth_token:
            return None

        auth_header = request.headers.get("Authorization", "")
        token = auth_header[7:] if auth_header.startswith("Bearer ") else ""
        if token != auth_token:
            return jsonify(build_error("UNAUTHORIZED", "Missing or invalid auth token.", g.request_id)), 401

        return None

    @app.after_request
    def add_request_id_header(response):
        response.headers["X-Request-Id"] = g.get("request_id", "unknown")
        return response

    @app.route("/")
    def index():
        return jsonify({"message": "Welcome to the AI Allocation Server", "status": "ok", "requestId": g.request_id})

    @app.route("/health")
    def health():
        return jsonify({"status": "ok", "requestId": g.request_id})

    @app.route("/decision-logs", methods=["GET"])
    def get_decision_logs():
        try:
            limit = min(max(int(request.args.get("limit", 50)), 1), 200)
            snap = db.collection("decisionLogs").limit(limit).stream()
            logs = [{"id": doc.id, **doc.to_dict()} for doc in snap]
            return jsonify({"items": logs, "count": len(logs), "limit": limit, "requestId": g.request_id})
        except Exception as exc:
            print("Error fetching decision logs:", exc)
            return jsonify(build_error("INTERNAL_ERROR", "Failed to fetch decision logs.", g.request_id, str(exc))), 500

    @app.route("/resolve-conflict", methods=["OPTIONS"])
    def resolve_conflict_options():
        response = make_response()
        response.headers["Access-Control-Allow-Origin"] = "*"
        response.headers["Access-Control-Allow-Methods"] = "POST, GET, OPTIONS"
        response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
        response.status_code = 200
        return response

    @app.route("/resolve-conflict", methods=["GET"])
    def resolve_conflict_get():
        try:
            docs = list(db.collection("allocations").where("conflict", "==", True).limit(1).stream())
            if not docs:
                return jsonify(
                    {
                        "message": "No conflicting allocation found.",
                        "requiredFields": ["allocationId", "date", "startTime", "endTime"],
                        "exampleBody": {
                            "allocationId": "abc123",
                            "conflictDetails": "Room double-booked",
                            "date": "2025-07-09",
                            "startTime": "10:00 AM",
                            "endTime": "12:00 PM",
                        },
                        "requestId": g.request_id,
                    }
                )

            doc = docs[0]
            data = doc.to_dict()
            return jsonify(
                {
                    "message": "Sample conflict payload fetched from Firestore.",
                    "requiredFields": ["allocationId", "date", "startTime", "endTime"],
                    "exampleBody": {
                        "allocationId": doc.id,
                        "conflictDetails": data.get("conflictDetails", "No details provided"),
                        "date": data.get("date"),
                        "startTime": data.get("startTime"),
                        "endTime": data.get("endTime"),
                    },
                    "requestId": g.request_id,
                }
            )
        except Exception as exc:
            print("Error fetching conflict info:", exc)
            return jsonify(build_error("INTERNAL_ERROR", "Failed to fetch conflict info.", g.request_id, str(exc))), 500

    @app.route("/resolve-conflict", methods=["POST"])
    def resolve_conflict_post():
        data = request.get_json(silent=True)
        is_valid, error_message = validate_resolve_conflict_payload(data)
        if not is_valid:
            return jsonify(build_error("BAD_REQUEST", error_message, g.request_id)), 400

        allocation_id = data["allocationId"]
        conflict_details = data.get("conflictDetails", "")
        date = data["date"]
        start_time = data["startTime"]
        end_time = data["endTime"]

        req_start = parse_time_12h(start_time)
        req_end = parse_time_12h(end_time)

        try:
            rooms_snap = db.collection("lecture_rooms").where("status", "==", "Available").stream()
            all_rooms = [room.to_dict().get("name") for room in rooms_snap if room.to_dict().get("name")]
            if not all_rooms:
                return jsonify(build_error("NO_AVAILABLE_ROOMS", "No rooms marked as available in Firestore.", g.request_id)), 400

            timetables = db.collection("timetables").where("date", "==", date).stream()
            overlapping = []
            for doc in timetables:
                if doc.id == allocation_id:
                    continue
                t = doc.to_dict()
                t_start = parse_time_12h(t.get("startTime", ""))
                t_end = parse_time_12h(t.get("endTime", ""))
                if t_start is None or t_end is None:
                    continue
                if not (req_end <= t_start or req_start >= t_end):
                    overlapping.append(t.get("room"))

            available_rooms = [room for room in all_rooms if room not in overlapping]
            if not available_rooms:
                if openai_api_key:
                    try:
                        prompt = (
                            f"No rooms are available for a lecture on {date} from {start_time} to {end_time}. "
                            "Suggest a short alternative plan for students and lecturers."
                        )
                        ai_response = openai.chat.completions.create(
                            model="gpt-3.5-turbo",
                            messages=[
                                {"role": "system", "content": "You are a helpful assistant."},
                                {"role": "user", "content": prompt},
                            ],
                            max_tokens=80,
                        )
                        suggestion = (
                            ai_response.choices[0].message.content.strip()
                            if ai_response.choices and ai_response.choices[0].message.content
                            else ""
                        )
                        return jsonify(
                            {
                                "error": {
                                    "code": "NO_AVAILABLE_ROOMS",
                                    "message": "No rooms available for the specified time.",
                                    "details": suggestion,
                                    "requestId": g.request_id,
                                }
                            }
                        ), 400
                    except Exception as ai_exc:
                        return jsonify(build_error("NO_AVAILABLE_ROOMS", "No rooms available.", g.request_id, str(ai_exc))), 400

                return jsonify(build_error("NO_AVAILABLE_ROOMS", "No rooms available for the specified time.", g.request_id)), 400

            suggested_venue = random.choice(available_rooms)

            tt_ref = db.collection("timetables").document(allocation_id)
            tt_doc = tt_ref.get()
            if not tt_doc.exists:
                return jsonify(build_error("NOT_FOUND", "Allocation not found in timetables.", g.request_id)), 404

            data_doc = tt_doc.to_dict() or {}
            admins_snap = list(db.collection("users").where("role", "==", "admin").stream())

            batch = db.batch()
            batch.update(tt_ref, {"resolvedVenue": suggested_venue, "conflict": False, "status": "diverted"})

            lecturer_id = data_doc.get("lecturerId")
            if lecturer_id:
                batch.set(
                    db.collection("notifications").document(),
                    {
                        "type": "conflict",
                        "title": f"Scheduling Conflict for {data_doc.get('courseCode', 'Your Lecture')}",
                        "message": f"Your lecture has been moved to {suggested_venue}.",
                        "lecturerId": lecturer_id,
                        "timetableId": allocation_id,
                        "isRead": False,
                        "time": firestore.SERVER_TIMESTAMP,
                    },
                )

            for student_id in data_doc.get("students", []):
                batch.set(
                    db.collection("notifications").document(),
                    {
                        "type": "conflict",
                        "title": "Lecture Conflict Notification",
                        "message": f"Your lecture has been moved to {suggested_venue}.",
                        "studentId": student_id,
                        "timetableId": allocation_id,
                        "isRead": False,
                        "time": firestore.SERVER_TIMESTAMP,
                    },
                )

            for admin_doc in admins_snap:
                batch.set(
                    db.collection("notifications").document(),
                    {
                        "type": "conflict",
                        "title": "Lecture Conflict Detected",
                        "message": f"Conflict resolved. Lecture moved to {suggested_venue}.",
                        "adminId": admin_doc.id,
                        "timetableId": allocation_id,
                        "isRead": False,
                        "time": firestore.SERVER_TIMESTAMP,
                    },
                )

            batch.set(
                db.collection("decisionLogs").document(),
                {
                    "allocationId": allocation_id,
                    "description": f"Conflict resolved. Venue: {suggested_venue}",
                    "conflictDetails": conflict_details,
                    "suggestedVenue": suggested_venue,
                    "timestamp": firestore.SERVER_TIMESTAMP,
                    "resolvedBy": "AI",
                    "status": "resolved",
                },
            )

            batch.commit()

            response = jsonify({"resolvedVenue": suggested_venue, "requestId": g.request_id})
            response.headers["Access-Control-Allow-Origin"] = "*"
            return response

        except Exception as exc:
            print(f"Error in /resolve-conflict: {exc}")
            response = jsonify(build_error("INTERNAL_ERROR", "Internal server error", g.request_id, str(exc)))
            response.headers["Access-Control-Allow-Origin"] = "*"
            return response, 500

    @app.route("/allocations", methods=["GET"])
    def get_allocations():
        try:
            limit = min(max(int(request.args.get("limit", 50)), 1), 200)
            snap = db.collection("allocations").limit(limit).stream()
            allocations = [{"id": doc.id, **doc.to_dict()} for doc in snap]
            return jsonify({"items": allocations, "count": len(allocations), "limit": limit, "requestId": g.request_id})
        except Exception as exc:
            print("Error fetching allocations:", exc)
            return jsonify(build_error("INTERNAL_ERROR", "Failed to fetch allocations.", g.request_id, str(exc))), 500

    return app


app = create_app()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)

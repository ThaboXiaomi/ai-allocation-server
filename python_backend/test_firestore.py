import os
from google.cloud import firestore

# Update this path if needed
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "D:\PC USER\Documents\School\Final Year Project\lecture_room_allocator\python_backend\credentials\campus-venue-navigator-d2bd86d4219a.json"

try:
    db = firestore.Client()
    collections = [c.id for c in db.collections()]
    print("✅ Firestore connection successful!")
    print("Collections:", collections)
except Exception as e:
    print("❌ Failed to connect to Firestore:")
    print(e)

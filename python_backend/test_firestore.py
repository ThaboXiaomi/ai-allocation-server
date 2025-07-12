import os
from google.cloud import firestore

# Update this path if needed
google_creds = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
if google_creds is not None:
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = google_creds
else:
    raise EnvironmentError("GOOGLE_APPLICATION_CREDENTIALS environment variable is not set.")

try:
    db = firestore.Client()
    collections = [c.id for c in db.collections()]
    print("✅ Firestore connection successful!")
    print("Collections:", collections)
except Exception as e:
    print("❌ Failed to connect to Firestore:")
    print(e)

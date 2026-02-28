# Lecture Room Allocator Python Backend

This is the Flask backend for lecture room allocation conflict resolution and allocation visibility.

## Features
- Resolve lecture room conflicts (`POST /resolve-conflict`)
- Fetch helper conflict payload (`GET /resolve-conflict`)
- List allocations (`GET /allocations`)
- List decision logs (`GET /decision-logs`)
- Health check (`GET /health`)
- Firestore integration
- Optional OpenAI suggestion support when no rooms are available

## Setup
1. Create a `.env` file in the project root and set:
   - `GOOGLE_APPLICATION_CREDENTIALS=/absolute/path/to/service-account.json`
   - `OPENAI_API_KEY=...` (optional)
2. Install dependencies:
   ```sh
   pip install -r requirements.txt
   ```
3. Run the server:
   ```sh
   python app.py
   ```

## Test
Run unit and integration tests:
```sh
python -m unittest test_conflict_utils.py test_app_integration.py
```

## Project Structure
- `app.py` — Main Flask app and route handlers
- `conflict_utils.py` — Pure validation/time parsing helpers
- `test_conflict_utils.py` — Unit tests for helper logic
- `test_app_integration.py` — Flask route integration tests with mocked Firestore
- `requirements.txt` — Python dependencies

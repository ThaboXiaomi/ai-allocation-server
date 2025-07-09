# Lecture Room Allocator Python Backend

This project is a Python Flask backend for lecture room allocation, supporting conflict resolution, allocation listing, and notifications. It uses Google Firestore for data storage and supports .env configuration for credentials and API keys.

## Features
- Resolve lecture room conflicts
- List allocations
- Send notifications to users
- Firestore integration
- .env support for credentials

## Setup
1. Create a `.env` file in the project root with your Google credentials and API keys.
2. Install dependencies:
   ```sh
   pip install -r requirements.txt
   ```
3. Run the server:
   ```sh
   flask run
   ```

## Endpoints
- `POST /resolve-conflict` — Resolve a scheduling conflict
- `GET /allocations` — List all allocations

## Project Structure
- `app.py` — Main Flask application
- `.env` — Environment variables
- `requirements.txt` — Python dependencies

---

# AI Allocation System - Complete Implementation Guide

## 📋 Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Getting Started](#getting-started)
4. [Flutter Frontend](#flutter-frontend)
5. [Python AI Service](#python-ai-service)
6. [Docker Deployment](#docker-deployment)
7. [API Documentation](#api-documentation)

---

## Overview

This is a complete AI-powered room allocation system with:

### ✨ Key Features
- **Real-time Updates**: Socket.io integration for live booking status
- **Smart Conflict Resolution**: Weighted multi-factor algorithm
- **Predictive Analytics**: ML-based demand forecasting
- **Natural Language Processing**: Book rooms using natural language
- **Waitlist Management**: Automatic rebooking from waitlist
- **Offline Support**: Hive/Isar local caching
- **Biometric Auth**: Secure authentication with fingerprint/Face ID
- **Interactive Calendar**: Heatmap visualization of bookings

### 🏗️ Tech Stack

**Backend (Node.js)**
- Express.js + Firebase Admin
- Socket.io for real-time
- Firestore database
- Helmet + rate-limiting for security

**AI Microservice (Python)**
- FastAPI
- Scikit-learn/XGBoost for ML
- SpaCy for NLP
- Celery + Redis for async tasks

**Frontend (Flutter)**
- Riverpod state management
- Table Calendar with heatmaps
- Socket.io client
- Hive/Isar offline storage
- Firebase Auth integration

---

## Architecture

```
┌─────────────────┐         ┌──────────────────┐
│  Flutter App    │◄───────►│  Node.js Server  │
│  (Riverpod)     │ WebSocket│  (Express +      │
└─────────────────┘         │   Socket.io)     │
         │                  └────────┬─────────┘
         │                           │
         │                    ┌──────▼──────┐
         │                    │   Python    │
         │                    │  AI Service │
         │                    │  (FastAPI)  │
         │                    └──────┬──────┘
         │                           │
┌────────▼─────────┐        ┌───────▼────────┐
│   Firebase       │        │     Redis      │
│   (Auth/Firestore)│        │  (Cache/Queue) │
└──────────────────┘        └────────────────┘
```

---

## Getting Started

### Prerequisites
- Node.js 20+
- Python 3.11+
- Flutter 3.16+
- Docker & Docker Compose
- Firebase project

### Quick Start with Docker

```bash
# Clone repository
cd /workspace

# Set environment variables
cp .env.example .env
# Edit .env with your Firebase credentials

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Access services:
# - Node.js Server: http://localhost:8080
# - Python AI Service: http://localhost:8081/docs
# - Grafana: http://localhost:3001 (admin/admin)
# - Prometheus: http://localhost:9090
```

### Manual Setup

#### Backend (Node.js)
```bash
cd ai-allocation-server
npm install
npm start
```

#### Python AI Service
```bash
cd python_ai_service
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8081
```

#### Flutter App
```bash
cd flutter_app
flutter pub get
flutter run
```

---

## Flutter Frontend

### Project Structure
```
lib/
├── main.dart                 # App entry point
├── models/
│   └── booking.dart         # Data models
├── services/
│   ├── api_client.dart      # HTTP client
│   └── socket_service.dart  # WebSocket service
├── repositories/
│   └── allocation_repository.dart
├── providers/
│   └── booking_providers.dart  # Riverpod providers
├── screens/
│   ├── splash_screen.dart
│   └── booking_calendar_screen.dart
└── utils/
    └── logger.dart
```

### Key Features Implemented

#### 1. Riverpod State Management
```dart
final bookingsProvider = StateNotifierProvider<BookingsStateNotifier, AsyncValue<List<Booking>>>((ref) {
  final repository = ref.watch(allocationRepositoryProvider);
  final socketService = ref.watch(socketServiceProvider);
  return BookingsStateNotifier(repository, socketService);
});
```

#### 2. Real-Time Socket Integration
- Automatic connection on app start
- Live booking updates
- Conflict resolution notifications
- Connection status indicator

#### 3. Interactive Calendar
- Table Calendar integration
- Heatmap markers based on booking density
- Tap to view day's bookings
- Status chips (Confirmed/Pending/Waitlist)

#### 4. Offline Support
```dart
// Hive boxes initialized in main.dart
await Hive.initFlutter();
await Hive.openBox('bookings');
await Hive.openBox('user_preferences');
```

#### 5. Secure Storage
```dart
// JWT tokens stored securely
final storage = FlutterSecureStorage();
await storage.write(key: 'auth_token', value: token);
```

---

## Python AI Service

### Endpoints

#### Demand Prediction
```bash
POST /analytics/demand/predict
{
  "roomId": "room_123",
  "startDate": "2024-01-01",
  "endDate": "2024-01-31",
  "historicalData": [...]
}
```

#### Conflict Resolution
```bash
POST /analytics/conflict/resolve
{
  "allocationId": "alloc_123",
  "competingBookings": [...],
  "roomCapacity": 10,
  "amenities": ["projector", "whiteboard"]
}
```

#### NLP Booking Parser
```bash
POST /nlp/parse-booking
{
  "text": "Book conference room for next Tuesday afternoon for 5 people",
  "userId": "user_123"
}
```

### Weighted Scoring Algorithm

The conflict resolution uses these factors:
- **Priority (30%)**: User priority level (1-10)
- **Timing (20%)**: First-come advantage
- **Duration Efficiency (15%)**: Optimal meeting length
- **Reliability (25%)**: Historical no-show rate
- **Capacity Fit (10%)**: Room size utilization

---

## Docker Deployment

### Services

| Service | Port | Description |
|---------|------|-------------|
| allocation-server | 8080 | Main Node.js API |
| python-ai-service | 8081 | AI/ML microservice |
| redis | 6379 | Cache & message queue |
| celery-worker | - | Background task processor |
| celery-beat | - | Scheduled task scheduler |
| prometheus | 9090 | Metrics collection |
| grafana | 3001 | Dashboard visualization |

### Production Configuration

```yaml
# docker-compose.prod.yml
services:
  allocation-server:
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '1'
          memory: 512M
  
  python-ai-service:
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: '2'
          memory: 2G
```

---

## API Documentation

### Node.js Server

Swagger UI available at: `http://localhost:8080/api-docs`

### Python AI Service

Interactive docs at: `http://localhost:8081/docs`

### Key Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /health | Health check |
| GET | /allocations | Get user bookings |
| POST | /allocations | Create booking |
| POST | /resolve-conflict | Resolve conflicts |
| GET | /waitlist | Get waitlist |
| POST | /waitlist | Add to waitlist |
| GET | /analytics/demand/:roomId | Demand prediction |

---

## Monitoring

### Prometheus Metrics
- Request rate
- Response times
- Error rates
- Active connections

### Grafana Dashboards
- System overview
- Booking analytics
- AI service performance
- Real-time metrics

---

## Security

✅ Implemented:
- Firebase Authentication
- Rate limiting
- CORS restrictions
- Input validation
- SQL injection prevention
- XSS protection (Helmet)
- Secure token storage
- Biometric auth support

---

## Testing

### Run Tests

```bash
# Node.js tests
cd ai-allocation-server
npm test

# Python tests
cd python_ai_service
pytest

# Flutter tests
cd flutter_app
flutter test
```

---

## Contributing

1. Fork the repository
2. Create feature branch
3. Make changes
4. Run tests
5. Submit PR

---

## License

MIT License - See LICENSE file for details

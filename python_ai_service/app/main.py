"""
AI Allocation Microservice - FastAPI
Provides predictive analytics, weighted conflict scoring, and NLP processing
"""
from fastapi import FastAPI, HTTPException, Depends, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from datetime import datetime, date
from typing import List, Dict, Optional, Any
import uvicorn
import logging
from pathlib import Path
import json

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="AI Allocation Service",
    description="Predictive analytics and intelligent conflict resolution for room allocation",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:8080", "http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================================================
# Data Models
# ============================================================================

class BookingRequest(BaseModel):
    roomId: str
    userId: str
    startTime: datetime
    endTime: datetime
    priority: int = Field(default=1, ge=1, le=10)
    duration: Optional[int] = None  # in minutes

class ConflictResolutionRequest(BaseModel):
    allocationId: str
    competingBookings: List[BookingRequest]
    roomCapacity: int
    amenities: List[str]

class DemandPredictionRequest(BaseModel):
    roomId: str
    startDate: date
    endDate: date
    historicalData: Optional[List[Dict[str, Any]]] = None

class NLPBookingRequest(BaseModel):
    text: str = Field(..., min_length=10, max_length=500)
    userId: str
    context: Optional[Dict[str, Any]] = None

class PredictionResponse(BaseModel):
    roomId: str
    predictedDemand: float
    trend: str  # 'increasing', 'stable', 'decreasing'
    confidence: float
    historicalData: List[Dict[str, Any]]
    recommendations: List[str]

class ConflictScore(BaseModel):
    bookingId: str
    score: float
    factors: Dict[str, float]
    reasoning: str

class ConflictResolutionResponse(BaseModel):
    selectedBooking: str
    scores: List[ConflictScore]
    algorithm: str
    timestamp: datetime

class NLPBookingResponse(BaseModel):
    intent: str
    entities: Dict[str, Any]
    structuredRequest: Optional[BookingRequest]
    confidence: float
    suggestions: List[str]

# ============================================================================
# In-Memory Storage (Replace with Redis/Database in production)
# ============================================================================

booking_history: Dict[str, List[Dict]] = {}
user_reliability_scores: Dict[str, float] = {}

# ============================================================================
# ML & Analytics Endpoints
# ============================================================================

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "version": "2.0.0"
    }

@app.post("/analytics/demand/predict", response_model=PredictionResponse)
async def predict_demand(request: DemandPredictionRequest):
    """
    Predict room demand using historical data and trends
    
    Uses time-series analysis to forecast demand patterns
    """
    logger.info(f"Predicting demand for room {request.roomId}")
    
    # Simulate ML prediction (replace with actual model in production)
    # In production: Load scikit-learn/xgboost model and predict
    
    base_demand = 0.7  # Base demand score
    trend_factor = 0.1  # Trend adjustment
    
    # Analyze historical data if provided
    if request.historicalData and len(request.historicalData) > 0:
        # Simple trend analysis
        recent_avg = sum(d.get('bookings', 0) for d in request.historicalData[-7:]) / min(7, len(request.historicalData))
        older_avg = sum(d.get('bookings', 0) for d in request.historicalData[:7]) / min(7, len(request.historicalData))
        
        if recent_avg > older_avg * 1.2:
            trend = "increasing"
            trend_factor = 0.15
        elif recent_avg < older_avg * 0.8:
            trend = "decreasing"
            trend_factor = -0.1
        else:
            trend = "stable"
            trend_factor = 0.0
    
    predicted_demand = min(1.0, base_demand + trend_factor)
    
    # Generate recommendations
    recommendations = []
    if predicted_demand > 0.8:
        recommendations.append("High demand expected. Consider booking early.")
        recommendations.append("Alternative rooms may be limited.")
    elif predicted_demand < 0.4:
        recommendations.append("Low demand period. Good availability.")
        recommendations.append("Flexible booking times available.")
    
    return PredictionResponse(
        roomId=request.roomId,
        predictedDemand=predicted_demand,
        trend=trend if 'trend' in locals() else "stable",
        confidence=0.85,
        historicalData=request.historicalData or [],
        recommendations=recommendations
    )

@app.post("/analytics/conflict/resolve", response_model=ConflictResolutionResponse)
async def resolve_conflict(request: ConflictResolutionRequest):
    """
    Resolve booking conflicts using weighted scoring algorithm
    
    Factors considered:
    - User priority level
    - Request timing (first-come advantage)
    - Duration efficiency
    - Historical reliability
    - Room fit (capacity match)
    """
    logger.info(f"Resolving conflict for allocation {request.allocationId}")
    
    scores: List[ConflictScore] = []
    
    for idx, booking in enumerate(request.competingBookings):
        # Calculate weighted score components
        priority_score = booking.priority / 10.0  # Normalize to 0-1
        
        # Timing score (earlier requests get slight advantage)
        timing_score = max(0.5, 1.0 - (idx * 0.1))
        
        # Duration efficiency (shorter, focused meetings preferred)
        duration_minutes = (booking.endTime - booking.startTime).total_seconds() / 60
        optimal_duration = 60  # 1 hour optimal
        duration_efficiency = 1.0 - abs(duration_minutes - optimal_duration) / 120
        duration_efficiency = max(0.3, min(1.0, duration_efficiency))
        
        # User reliability (from historical data)
        reliability = user_reliability_scores.get(booking.userId, 0.7)
        
        # Room fit (capacity utilization)
        capacity_fit = min(1.0, 5 / request.roomCapacity)  # Assume avg 5 people
        
        # Weighted final score
        weights = {
            'priority': 0.30,
            'timing': 0.20,
            'duration_efficiency': 0.15,
            'reliability': 0.25,
            'capacity_fit': 0.10
        }
        
        final_score = (
            priority_score * weights['priority'] +
            timing_score * weights['timing'] +
            duration_efficiency * weights['duration_efficiency'] +
            reliability * weights['reliability'] +
            capacity_fit * weights['capacity_fit']
        )
        
        scores.append(ConflictScore(
            bookingId=f"booking_{idx}",
            score=round(final_score, 3),
            factors={
                'priority': round(priority_score, 3),
                'timing': round(timing_score, 3),
                'duration_efficiency': round(duration_efficiency, 3),
                'reliability': round(reliability, 3),
                'capacity_fit': round(capacity_fit, 3)
            },
            reasoning=f"Weighted combination of priority ({weights['priority']:.0%}), timing ({weights['timing']:.0%}), efficiency ({weights['duration_efficiency']:.0%}), reliability ({weights['reliability']:.0%}), and fit ({weights['capacity_fit']:.0%})"
        ))
    
    # Sort by score descending
    scores.sort(key=lambda x: x.score, reverse=True)
    selected = scores[0].bookingId
    
    return ConflictResolutionResponse(
        selectedBooking=selected,
        scores=scores,
        algorithm="weighted_multi_factor_v2",
        timestamp=datetime.now()
    )

# ============================================================================
# NLP Processing Endpoints
# ============================================================================

@app.post("/nlp/parse-booking", response_model=NLPBookingResponse)
async def parse_booking_request(request: NLPBookingRequest):
    """
    Parse natural language booking requests
    
    Example: "Book conference room for next Tuesday afternoon for 5 people"
    """
    logger.info(f"Parsing NLP request: {request.text[:50]}...")
    
    # In production: Use spaCy or Hugging Face transformers
    # For now, simple keyword-based parsing
    
    text_lower = request.text.lower()
    entities = {}
    
    # Detect room type
    room_types = ['conference', 'meeting', 'board', 'huddle', 'training']
    for room_type in room_types:
        if room_type in text_lower:
            entities['roomType'] = room_type
            break
    
    # Detect time references (simplified)
    time_indicators = {
        'morning': '09:00-12:00',
        'afternoon': '13:00-17:00',
        'evening': '17:00-20:00',
        'today': datetime.now().date().isoformat(),
        'tomorrow': (datetime.now().date().replace(day=datetime.now().day+1)).isoformat() if datetime.now().day < 28 else None,
    }
    
    for indicator, value in time_indicators.items():
        if indicator in text_lower and value:
            if 'timeRange' not in entities:
                entities['timeRange'] = value
            elif 'date' not in entities:
                entities['date'] = value
    
    # Detect number of people
    import re
    people_match = re.search(r'(\d+)\s*(people|person|attendees)', text_lower)
    if people_match:
        entities['attendees'] = int(people_match.group(1))
    
    # Determine intent
    intent = "create_booking"
    if any(word in text_lower for word in ['cancel', 'delete', 'remove']):
        intent = "cancel_booking"
    elif any(word in text_lower for word in ['change', 'modify', 'update', 'reschedule']):
        intent = "modify_booking"
    elif any(word in text_lower for word in ['check', 'view', 'show', 'list']):
        intent = "view_bookings"
    
    # Build structured request if possible
    structured_request = None
    if intent == "create_booking" and 'roomType' in entities:
        # Create a basic structured request
        structured_request = BookingRequest(
            roomId=entities.get('roomType', 'general'),
            userId=request.userId,
            startTime=datetime.now().replace(hour=14, minute=0),
            endTime=datetime.now().replace(hour=15, minute=0),
            priority=5
        )
    
    # Generate suggestions
    suggestions = []
    if 'attendees' not in entities:
        suggestions.append("Please specify the number of attendees")
    if 'timeRange' not in entities:
        suggestions.append("Please specify preferred time (morning/afternoon/evening)")
    if not suggestions:
        suggestions.append("Request looks complete. Proceed with booking?")
    
    confidence = 0.9 if len(entities) >= 3 else 0.6 if len(entities) >= 2 else 0.4
    
    return NLPBookingResponse(
        intent=intent,
        entities=entities,
        structuredRequest=structured_request,
        confidence=confidence,
        suggestions=suggestions
    )

# ============================================================================
# Background Tasks & Model Training
# ============================================================================

@app.post("/ml/train", status_code=202)
async def trigger_model_training(background_tasks: BackgroundTasks):
    """
    Trigger background model retraining
    
    In production: This would queue a Celery task
    """
    logger.info("Triggering model retraining...")
    
    async def train_models():
        # Simulate training process
        import asyncio
        await asyncio.sleep(5)  # Simulate training time
        logger.info("Model training completed")
        # Update models in memory or save to disk
    
    background_tasks.add_task(train_models)
    
    return {
        "status": "training_queued",
        "message": "Model retraining started in background"
    }

@app.get("/ml/model-status")
async def get_model_status():
    """Get current ML model status"""
    return {
        "lastTrained": "2024-01-15T10:30:00Z",
        "modelVersion": "2.0.0",
        "accuracy": 0.87,
        "status": "active"
    }

# ============================================================================
# Main Entry Point
# ============================================================================

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="127.0.0.1",
        port=8081,
        reload=True,
        log_level="info"
    )

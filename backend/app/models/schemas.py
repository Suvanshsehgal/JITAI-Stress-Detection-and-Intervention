from datetime import datetime
from typing import Optional, Dict, Any, List
from pydantic import BaseModel, Field

# ─── Auth Schemas ─────────────────────────────────────────────────────────────

class UserRegisterRequest(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=6, max_length=100)
    buddy_name: Optional[str] = "Pip"

class UserLoginRequest(BaseModel):
    username: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str
    username: str

class UserProfileResponse(BaseModel):
    user_id: str
    username: str
    buddy_name: str
    created_at: datetime

# ─── Context & Health Schemas ─────────────────────────────────────────────────

class ContextInputSchema(BaseModel):
    timestamp: datetime
    heartRateBpm: Optional[float] = None
    hrvRmssdMs: Optional[float] = None
    sleepDurationMinutes: Optional[int] = None
    calendarState: Optional[str] = None  # "busy", "free", "unknown"
    recentMood: Optional[int] = None      # 1 to 5 scale
    dataQualityMap: Dict[str, str] = Field(default_factory=dict)

# ─── Stress Assessment Schemas ────────────────────────────────────────────────

class StressAssessmentRequest(BaseModel):
    context: ContextInputSchema
    userId: Optional[str] = None

class StressAssessmentResponse(BaseModel):
    id: str
    timestamp: datetime
    state: str  # "baseline", "elevated", "high", "unknown"
    confidence: Optional[float] = None
    inferenceStatus: str  # "success", "insufficientData", "unavailable", "staleData", "permissionDenied", "error"
    dataQuality: str
    modelVersion: str
    metadata: Dict[str, Any] = Field(default_factory=dict)
    explanation: Optional[Dict[str, Any]] = None

# ─── JITAI Decision Schemas ───────────────────────────────────────────────────

class JitaiEvaluationRequest(BaseModel):
    idempotencyKey: str
    context: ContextInputSchema
    stressAssessment: StressAssessmentResponse
    userTone: Optional[str] = "gentle"
    recentInterventions: List[str] = Field(default_factory=list)

class JitaiRecommendationResponse(BaseModel):
    isRecommended: bool
    recommendationId: Optional[str] = None
    interventionId: Optional[str] = None
    title: Optional[str] = None
    description: Optional[str] = None
    duration: Optional[str] = None
    reason: Optional[str] = None
    triggerState: str
    cooldownUntil: Optional[datetime] = None
    statusReason: str  # "recommended", "in_cooldown", "calendar_busy", "steady_no_action_needed", "insufficient_data"

# ─── Sync Schemas ─────────────────────────────────────────────────────────────

class InterventionResponseItem(BaseModel):
    id: str
    recommendationId: Optional[str] = None
    interventionId: str
    responseType: str  # "accepted", "declined", "dismissed", "completed", "abandoned"
    timestamp: datetime
    postMood: Optional[str] = None

class InterventionResponseSyncRequest(BaseModel):
    items: List[InterventionResponseItem]

class InterventionResponseSyncResponse(BaseModel):
    syncedCount: int
    failedCount: int
    message: str

# ─── Chat & Buddy Schemas ─────────────────────────────────────────────────────

class ChatMessageItem(BaseModel):
    role: str  # "user", "assistant", "model"
    content: str

class BuddyChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=2000)
    buddy_name: Optional[str] = "Pip"
    tone: Optional[str] = "gentle"  # "gentle", "playful", "straightTalking"
    history: List[ChatMessageItem] = Field(default_factory=list)
    context: Optional[Dict[str, Any]] = None  # optional stress assessment, heart rate, mood

class BuddyChatResponse(BaseModel):
    response: str
    buddy_name: str
    tone: str
    model_used: str  # "gemini-1.5-flash" or "fallback-rules"


from datetime import datetime
from app.services.jitai_service import JitaiService
from app.models.schemas import (
    JitaiEvaluationRequest,
    ContextInputSchema,
    StressAssessmentResponse,
)

def test_jitai_evaluation_and_idempotency():
    service = JitaiService()
    now = datetime.now()
    req = JitaiEvaluationRequest(
        idempotencyKey="idem-key-123",
        context=ContextInputSchema(timestamp=now, calendarState="free"),
        stressAssessment=StressAssessmentResponse(
            id="assess-1",
            timestamp=now,
            state="high",
            confidence=0.85,
            inferenceStatus="success",
            dataQuality="available",
            modelVersion="test-v1",
        ),
    )

    res1 = service.evaluate(req, user_id="user-1")
    assert res1.isRecommended is True
    assert res1.interventionId == "box-breathing"
    assert res1.statusReason == "recommended"

    # Repeated request with same idempotency key must return same result
    res2 = service.evaluate(req, user_id="user-1")
    assert res2.recommendationId == res1.recommendationId

def test_jitai_calendar_busy_suppresses():
    service = JitaiService()
    now = datetime.now()
    req = JitaiEvaluationRequest(
        idempotencyKey="idem-key-busy",
        context=ContextInputSchema(timestamp=now, calendarState="busy"),
        stressAssessment=StressAssessmentResponse(
            id="assess-2",
            timestamp=now,
            state="high",
            confidence=0.85,
            inferenceStatus="success",
            dataQuality="available",
            modelVersion="test-v1",
        ),
    )

    res = service.evaluate(req, user_id="user-2")
    assert res.isRecommended is False
    assert res.statusReason == "calendar_busy"

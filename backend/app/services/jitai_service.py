import uuid
from datetime import datetime, timedelta
from typing import Dict, Optional
from app.config import settings
from app.models.schemas import JitaiEvaluationRequest, JitaiRecommendationResponse
from app.core.logging import log_safe_event

class JitaiService:
    def __init__(self):
        # Cache for idempotency: key -> JitaiRecommendationResponse
        self._idempotency_cache: Dict[str, JitaiRecommendationResponse] = {}
        # Cooldown tracking: user_id -> datetime
        self._user_cooldowns: Dict[str, datetime] = {}

    def evaluate(self, req: JitaiEvaluationRequest, user_id: str = "anonymous") -> JitaiRecommendationResponse:
        log_safe_event("jitai_evaluation_started", user_id=user_id, idempotency_key=req.idempotencyKey)

        # 1. Idempotency check: if already evaluated for this key, return cached result
        if req.idempotencyKey in self._idempotency_cache:
            log_safe_event("jitai_idempotent_hit", idempotency_key=req.idempotencyKey)
            return self._idempotency_cache[req.idempotencyKey]

        # 2. Check if stress assessment succeeded
        if req.stressAssessment.inferenceStatus != "success":
            resp = JitaiRecommendationResponse(
                isRecommended=False,
                triggerState=req.stressAssessment.state,
                statusReason="insufficient_data",
            )
            self._idempotency_cache[req.idempotencyKey] = resp
            return resp

        # 3. Check calendar context: suppress if busy to avoid interrupting user
        if req.context.calendarState == "busy":
            resp = JitaiRecommendationResponse(
                isRecommended=False,
                triggerState=req.stressAssessment.state,
                statusReason="calendar_busy",
            )
            self._idempotency_cache[req.idempotencyKey] = resp
            return resp

        # 4. Check user cooldown
        now = datetime.now()
        cooldown_until = self._user_cooldowns.get(user_id)
        if cooldown_until and now < cooldown_until:
            resp = JitaiRecommendationResponse(
                isRecommended=False,
                triggerState=req.stressAssessment.state,
                cooldownUntil=cooldown_until,
                statusReason="in_cooldown",
            )
            self._idempotency_cache[req.idempotencyKey] = resp
            return resp

        # 5. Check stress state: steady does not need intrusive intervention
        state = req.stressAssessment.state
        if state == "baseline":
            resp = JitaiRecommendationResponse(
                isRecommended=False,
                triggerState=state,
                statusReason="steady_no_action_needed",
            )
            self._idempotency_cache[req.idempotencyKey] = resp
            return resp

        # 6. Recommendation selection for elevated / high stress state
        recommendation_id = str(uuid.uuid4())
        new_cooldown = now + timedelta(minutes=settings.JITAI_COOLDOWN_MINUTES)
        self._user_cooldowns[user_id] = new_cooldown

        if state == "high":
            intervention_id = "box-breathing"
            title = "Box Breathing"
            description = "A structured 4-4-4-4 rhythm to regulate physiological activation."
            duration = "3 min"
            reason = "Your recent readings show elevated activation. Taking 3 minutes can restore balance."
        else:  # elevated
            # Rotate or choose focus reset
            if "focus-reset" in req.recentInterventions:
                intervention_id = "grounding-54321"
                title = "5-4-3-2-1 Grounding"
                description = "Engage your senses to re-anchor into the present moment."
                duration = "5 min"
                reason = "A gentle sensory reset to clear cognitive overload."
            else:
                intervention_id = "focus-reset"
                title = "Focus Reset"
                description = "Step back and recalibrate attention."
                duration = "2 min"
                reason = "A quick pause to steady your focus."

        resp = JitaiRecommendationResponse(
            isRecommended=True,
            recommendationId=recommendation_id,
            interventionId=intervention_id,
            title=title,
            description=description,
            duration=duration,
            reason=reason,
            triggerState=state,
            cooldownUntil=new_cooldown,
            statusReason="recommended",
        )

        self._idempotency_cache[req.idempotencyKey] = resp
        log_safe_event("jitai_recommendation_issued", intervention_id=intervention_id)
        return resp

jitai_service = JitaiService()

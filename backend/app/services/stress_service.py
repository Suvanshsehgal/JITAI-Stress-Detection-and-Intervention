from app.adapters.stress_adapter import StrideProbeStressAdapter
from app.models.schemas import ContextInputSchema, StressAssessmentResponse
from app.core.logging import log_safe_event

class StressService:
    def __init__(self, adapter: StrideProbeStressAdapter = None):
        self.adapter = adapter or StrideProbeStressAdapter()

    def assess_context(self, context: ContextInputSchema, user_id: str = None) -> StressAssessmentResponse:
        log_safe_event("stress_assessment_requested", user_id=user_id or "anonymous")
        result = self.adapter.evaluate(context)
        log_safe_event(
            "stress_assessment_completed",
            inference_status=result.inferenceStatus,
            state=result.state,
            model_version=result.modelVersion,
        )
        return result

stress_service = StressService()

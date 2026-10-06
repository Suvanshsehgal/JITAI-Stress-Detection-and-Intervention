import uuid
from datetime import datetime
from typing import Dict, Any, Optional
from app.config import settings
from app.models.schemas import ContextInputSchema, StressAssessmentResponse

class StrideProbeStressAdapter:
    """
    Adapter bridging to the Stride Probe / composite stress model.
    Encapsulates the 7-component normalization logic without touching or modifying stressdata/.
    """

    def __init__(self, model_version: Optional[str] = None):
        self.model_version = model_version or settings.MODEL_VERSION

    def evaluate(self, context: ContextInputSchema) -> StressAssessmentResponse:
        quality_map = context.dataQualityMap

        # 1. Check for permission requirements
        if quality_map.get("heartRate") == "permissionRequired" or quality_map.get("hrv") == "permissionRequired":
            return StressAssessmentResponse(
                id=str(uuid.uuid4()),
                timestamp=datetime.now(),
                state="unknown",
                confidence=None,
                inferenceStatus="permissionDenied",
                dataQuality="permissionRequired",
                modelVersion=self.model_version,
                metadata={"source": "stride_probe_adapter"},
            )

        # 2. Check for disabled sources
        if quality_map.get("heartRate") == "disabled" and quality_map.get("hrv") == "disabled":
            return StressAssessmentResponse(
                id=str(uuid.uuid4()),
                timestamp=datetime.now(),
                state="unknown",
                confidence=None,
                inferenceStatus="unavailable",
                dataQuality="disabled",
                modelVersion=self.model_version,
                metadata={"source": "stride_probe_adapter"},
            )

        # 3. Check for stale data
        if quality_map.get("heartRate") == "stale" or quality_map.get("hrv") == "stale":
            return StressAssessmentResponse(
                id=str(uuid.uuid4()),
                timestamp=datetime.now(),
                state="unknown",
                confidence=None,
                inferenceStatus="staleData",
                dataQuality="stale",
                modelVersion=self.model_version,
                metadata={"source": "stride_probe_adapter"},
            )

        # 4. Check if required physiological signals are provided
        hr = context.heartRateBpm
        hrv = context.hrvRmssdMs

        if hr is None and hrv is None:
            return StressAssessmentResponse(
                id=str(uuid.uuid4()),
                timestamp=datetime.now(),
                state="unknown",
                confidence=None,
                inferenceStatus="insufficientData",
                dataQuality="noData",
                modelVersion=self.model_version,
                metadata={"source": "stride_probe_adapter", "details": "Physiological signals absent"},
            )

        # 5. Compute normalized component scores
        # HR stress: 60..100 BPM mapped to 0..1
        hr_stress = 0.5
        if hr is not None:
            hr_stress = max(0.0, min(1.0, (hr - 60.0) / 40.0))

        # HRV stress: RMSSD 0..100ms inverted
        hrv_stress = 0.5
        if hrv is not None:
            hrv_stress = max(0.0, min(1.0, 1.0 - (hrv / 100.0)))

        # Self-reported stress (mood: 1=Low/Bad, 5=Great) -> inverted
        mood_stress = 0.5
        if context.recentMood is not None:
            mood_stress = max(0.0, min(1.0, (5 - context.recentMood) / 4.0))

        # Sleep recovery contribution (8h = 480min)
        sleep_stress = 0.5
        if context.sleepDurationMinutes is not None:
            sleep_stress = max(0.0, min(1.0, 1.0 - (context.sleepDurationMinutes / 480.0)))

        # Composite score weighting (Stride Probe composite formula)
        # Weights: HRV (0.35), HR (0.25), Sleep (0.20), Mood (0.20)
        composite_score = (
            (0.35 * hrv_stress) +
            (0.25 * hr_stress) +
            (0.20 * sleep_stress) +
            (0.20 * mood_stress)
        ) * 100.0

        # Confidence calculation
        signals_present = (1.0 if hr is not None else 0.0) + (1.0 if hrv is not None else 0.0) + (1.0 if context.sleepDurationMinutes is not None else 0.0)
        confidence = round(min(0.95, 0.40 + (signals_present / 3.0) * 0.50), 2)

        # Map to discrete non-medical pattern state
        if composite_score < 40.0:
            state = "baseline"
            explanation_summary = "Observed patterns are consistent with steady resting baseline."
        elif composite_score < 65.0:
            state = "elevated"
            explanation_summary = "Mild activation observed in recent physiological context."
        else:
            state = "high"
            explanation_summary = "Elevated activation detected across available signals."

        return StressAssessmentResponse(
            id=str(uuid.uuid4()),
            timestamp=datetime.now(),
            state=state,
            confidence=confidence,
            inferenceStatus="success",
            dataQuality="available",
            modelVersion=self.model_version,
            metadata={
                "source": "stride_probe_composite",
                "compositeScore": round(composite_score, 1),
            },
            explanation={
                "summary": explanation_summary,
            },
        )

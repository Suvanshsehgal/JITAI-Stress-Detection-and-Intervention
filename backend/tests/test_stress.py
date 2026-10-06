from datetime import datetime
from app.adapters.stress_adapter import StrideProbeStressAdapter
from app.models.schemas import ContextInputSchema

def test_stress_adapter_insufficient_data():
    adapter = StrideProbeStressAdapter()
    context = ContextInputSchema(timestamp=datetime.now())
    res = adapter.evaluate(context)
    assert res.inferenceStatus == "insufficientData"
    assert res.state == "unknown"

def test_stress_adapter_with_valid_signals():
    adapter = StrideProbeStressAdapter()
    context = ContextInputSchema(
        timestamp=datetime.now(),
        heartRateBpm=70.0,
        hrvRmssdMs=48.0,
        sleepDurationMinutes=450,
        recentMood=4,
    )
    res = adapter.evaluate(context)
    assert res.inferenceStatus == "success"
    assert res.state in ["baseline", "elevated"]
    assert res.confidence is not None
    assert res.confidence > 0.5

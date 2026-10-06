import pytest
from datetime import datetime
from app.services.sync_service import SyncService
from app.models.schemas import InterventionResponseItem

@pytest.mark.asyncio
async def test_sync_interventions_idempotency():
    service = SyncService()
    now = datetime.now()
    items = [
        InterventionResponseItem(
            id="resp-1",
            recommendationId="rec-1",
            interventionId="box-breathing",
            responseType="completed",
            timestamp=now,
            postMood="Great",
        ),
        InterventionResponseItem(
            id="resp-2",
            recommendationId="rec-2",
            interventionId="focus-reset",
            responseType="declined",
            timestamp=now,
        ),
    ]

    res = await service.sync_responses("user-1", items)
    assert res.syncedCount == 2
    assert res.failedCount == 0

    history = await service.get_history("user-1")
    assert len(history) == 2

    # Retrying same sync should be idempotent (no duplicate count)
    res2 = await service.sync_responses("user-1", items)
    assert res2.syncedCount == 2
    assert len(await service.get_history("user-1")) == 2

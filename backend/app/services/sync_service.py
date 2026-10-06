from typing import Dict, List
from app.models.schemas import InterventionResponseItem, InterventionResponseSyncResponse
from app.core.logging import log_safe_event
from app.core.supabase_client import supabase_backend

class SyncService:
    def __init__(self):
        # In-memory fast cache: user_id -> dict of response_id -> item
        self._user_responses: Dict[str, Dict[str, InterventionResponseItem]] = {}

    async def sync_responses(self, user_id: str, items: List[InterventionResponseItem]) -> InterventionResponseSyncResponse:
        if user_id not in self._user_responses:
            self._user_responses[user_id] = {}

        user_store = self._user_responses[user_id]
        synced_count = 0
        records_to_supabase = []

        for item in items:
            # Idempotent: overwrite or insert in local memory cache
            user_store[item.id] = item
            synced_count += 1

            # Format for Supabase table `jitai_user_responses`
            records_to_supabase.append({
                "id": item.id,
                "user_id": user_id,
                "recommendation_id": item.recommendationId,
                "intervention_id": item.interventionId,
                "response_type": item.responseType,
                "post_mood": item.postMood,
                "timestamp": item.timestamp.isoformat(),
            })

        # Persist to Supabase asynchronously
        if records_to_supabase:
            try:
                await supabase_backend.upsert("jitai_user_responses", records_to_supabase)
            except Exception as e:
                log_safe_event("supabase_sync_error", user_id=user_id, error=str(e))

        log_safe_event("sync_interventions_completed", user_id=user_id, count=synced_count)

        return InterventionResponseSyncResponse(
            syncedCount=synced_count,
            failedCount=0,
            message="Successfully synchronized intervention responses.",
        )

    async def get_history(self, user_id: str) -> List[InterventionResponseItem]:
        # 1. Try querying Supabase
        try:
            records = await supabase_backend.select("jitai_user_responses", {"user_id": f"eq.{user_id}", "order": "timestamp.desc"})
            if records:
                return [
                    InterventionResponseItem(
                        id=r["id"],
                        recommendationId=r.get("recommendation_id"),
                        interventionId=r["intervention_id"],
                        responseType=r["response_type"],
                        timestamp=r["timestamp"],
                        postMood=r.get("post_mood"),
                    )
                    for r in records
                ]
        except Exception:
            pass

        # 2. Fall back to in-memory store
        user_store = self._user_responses.get(user_id, {})
        items = list(user_store.values())
        items.sort(key=lambda x: x.timestamp, reverse=True)
        return items

sync_service = SyncService()

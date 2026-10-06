from fastapi import APIRouter, Depends
from typing import List
from app.models.schemas import (
    InterventionResponseSyncRequest,
    InterventionResponseSyncResponse,
    InterventionResponseItem,
    UserProfileResponse,
)
from app.services.sync_service import sync_service
from app.api.deps import get_current_user

router = APIRouter(prefix="/sync", tags=["sync"])

@router.post("/interventions", response_model=InterventionResponseSyncResponse)
async def sync_interventions(
    req: InterventionResponseSyncRequest,
    current_user: UserProfileResponse = Depends(get_current_user),
):
    return await sync_service.sync_responses(current_user.user_id, req.items)

@router.get("/history", response_model=List[InterventionResponseItem])
async def get_sync_history(
    current_user: UserProfileResponse = Depends(get_current_user),
):
    return await sync_service.get_history(current_user.user_id)


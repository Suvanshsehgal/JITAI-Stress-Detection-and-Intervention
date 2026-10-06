from fastapi import APIRouter, Depends
from typing import Optional
from app.models.schemas import JitaiEvaluationRequest, JitaiRecommendationResponse, UserProfileResponse
from app.services.jitai_service import jitai_service
from app.api.deps import get_optional_user

router = APIRouter(prefix="/jitai", tags=["jitai"])

@router.post("/evaluate", response_model=JitaiRecommendationResponse)
async def evaluate_jitai(
    req: JitaiEvaluationRequest,
    current_user: Optional[UserProfileResponse] = Depends(get_optional_user),
):
    user_id = current_user.user_id if current_user else "anonymous"
    return jitai_service.evaluate(req, user_id=user_id)

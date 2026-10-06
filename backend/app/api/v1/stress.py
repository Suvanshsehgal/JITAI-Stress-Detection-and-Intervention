from fastapi import APIRouter, Depends
from typing import Optional
from app.models.schemas import StressAssessmentRequest, StressAssessmentResponse, UserProfileResponse
from app.services.stress_service import stress_service
from app.api.deps import get_optional_user

router = APIRouter(prefix="/stress", tags=["stress"])

@router.post("/assess", response_model=StressAssessmentResponse)
async def assess_stress(
    req: StressAssessmentRequest,
    current_user: Optional[UserProfileResponse] = Depends(get_optional_user),
):
    user_id = current_user.user_id if current_user else req.userId
    return stress_service.assess_context(req.context, user_id=user_id)

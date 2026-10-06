from fastapi import APIRouter, HTTPException, status, Depends
from app.models.schemas import UserRegisterRequest, UserLoginRequest, TokenResponse, UserProfileResponse
from app.services.auth_service import auth_service
from app.api.deps import get_current_user

router = APIRouter(prefix="/auth", tags=["auth"])

@router.post("/register", response_model=TokenResponse)
async def register(req: UserRegisterRequest):
    try:
        return auth_service.register(req)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

@router.post("/login", response_model=TokenResponse)
async def login(req: UserLoginRequest):
    result = auth_service.login(req.username, req.password)
    if not result:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
        )
    return result

@router.get("/me", response_model=UserProfileResponse)
async def get_me(current_user: UserProfileResponse = Depends(get_current_user)):
    return current_user

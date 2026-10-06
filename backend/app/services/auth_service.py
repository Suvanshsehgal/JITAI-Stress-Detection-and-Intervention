import uuid
from datetime import datetime
from typing import Dict, Optional
from app.core.security import hash_password, verify_password, create_access_token
from app.models.schemas import UserRegisterRequest, TokenResponse, UserProfileResponse

class AuthService:
    def __init__(self):
        # In-memory user store for portable, self-contained development and deployment
        self._users: Dict[str, dict] = {}
        # Pre-seed a test user
        self.register(UserRegisterRequest(username="testuser", password="password123", buddy_name="Pip"))

    def register(self, req: UserRegisterRequest) -> TokenResponse:
        if req.username in self._users:
            raise ValueError("Username already exists")

        user_id = str(uuid.uuid4())
        hashed = hash_password(req.password)
        self._users[req.username] = {
            "id": user_id,
            "username": req.username,
            "password": hashed,
            "buddy_name": req.buddy_name or "Pip",
            "created_at": datetime.now(),
        }

        token = create_access_token(user_id)
        return TokenResponse(
            access_token=token,
            user_id=user_id,
            username=req.username,
        )

    def login(self, username: str, password: str) -> Optional[TokenResponse]:
        user = self._users.get(username)
        if not user:
            return None
        if not verify_password(password, user["password"]):
            return None

        token = create_access_token(user["id"])
        return TokenResponse(
            access_token=token,
            user_id=user["id"],
            username=user["username"],
        )

    def get_user_by_id(self, user_id: str) -> Optional[UserProfileResponse]:
        for user in self._users.values():
            if user["id"] == user_id:
                return UserProfileResponse(
                    user_id=user["id"],
                    username=user["username"],
                    buddy_name=user["buddy_name"],
                    created_at=user["created_at"],
                )
        return None

auth_service = AuthService()

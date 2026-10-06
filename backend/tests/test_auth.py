from app.services.auth_service import AuthService
from app.models.schemas import UserRegisterRequest

def test_auth_registration_and_login():
    auth = AuthService()
    req = UserRegisterRequest(username="newuser", password="securepassword123")
    res = auth.register(req)
    assert res.access_token is not None
    assert res.username == "newuser"

    # Login
    login_res = auth.login("newuser", "securepassword123")
    assert login_res is not None
    assert login_res.user_id == res.user_id

    # Wrong password
    assert auth.login("newuser", "wrongpwd") is None

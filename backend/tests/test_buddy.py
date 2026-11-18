import pytest
from unittest.mock import patch, AsyncMock
from fastapi.testclient import TestClient
from app.main import app
from app.services.gemini_service import GeminiService
from app.models.schemas import ChatMessageItem

client = TestClient(app)

@pytest.mark.asyncio
async def test_buddy_chat_fallback_rules():
    service = GeminiService(api_key="")
    resp = await service.get_response(
        message="I am feeling so stressed with work deadlines",
        buddy_name="Pip",
        tone="gentle",
    )
    assert resp.buddy_name == "Pip"
    assert resp.tone == "gentle"
    assert "988" in resp.response  # honest unavailable message with crisis line
    assert resp.model_used == "fallback-rules"

@pytest.mark.asyncio
async def test_buddy_chat_tones():
    service = GeminiService(api_key="")
    
    # Playful
    playful_resp = await service.get_response(
        message="I'm feeling so stressed today",
        buddy_name="Pip",
        tone="playful",
    )
    assert "988" in playful_resp.response

    # Straight-talking
    direct_resp = await service.get_response(
        message="I'm feeling so stressed today",
        buddy_name="Pip",
        tone="straightTalking",
    )
    assert "988" in direct_resp.response

@pytest.mark.asyncio
async def test_buddy_crisis_guardrail():
    service = GeminiService(api_key="")
    resp = await service.get_response(
        message="I want to hurt myself and end my life",
        buddy_name="Pip",
        tone="gentle",
    )
    assert "988" in resp.response
    assert "741741" in resp.response
    assert resp.model_used == "safety-crisis-guardrail"

@pytest.mark.asyncio
async def test_buddy_gemini_api_mocked():
    service = GeminiService(api_key="mock-test-key", model="gemini-1.5-flash")
    
    mock_payload = {
        "candidates": [
            {
                "content": {
                    "parts": [{"text": "Take a slow breath. I am right here with you."}]
                }
            }
        ]
    }
    
    from unittest.mock import MagicMock
    with patch("httpx.AsyncClient.post") as mock_post:
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = mock_payload
        mock_post.return_value = mock_response

        resp = await service.get_response(
            message="Hello Pip, I need some help.",
            buddy_name="Pip",
            tone="gentle",
            history=[ChatMessageItem(role="user", content="Hi")],
        )
        assert resp.response == "Take a slow breath. I am right here with you."
        assert resp.model_used == "gemini-1.5-flash"

def test_buddy_api_endpoint():
    res = client.post(
        "/api/v1/buddy/chat",
        json={
            "message": "I'm stressed and can't sleep",
            "buddy_name": "Pip",
            "tone": "gentle",
            "history": [],
            "context": {
                "state": "elevated",
                "heartRateBpm": 88.0,
                "recentMood": 2
            }
        }
    )
    assert res.status_code == 200
    data = res.json()
    assert "response" in data
    assert data["buddy_name"] == "Pip"
    assert data["tone"] == "gentle"
    assert len(data["response"]) > 0

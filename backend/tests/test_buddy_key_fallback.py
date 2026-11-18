from unittest.mock import AsyncMock, MagicMock, patch

import httpx
import pytest

from app.services.gemini_service import GeminiService


def _response(status: int, text: str | None = None) -> MagicMock:
    res = MagicMock()
    res.status_code = status
    if text is not None:
        res.json.return_value = {
            "candidates": [{"content": {"parts": [{"text": text}]}}]
        }
    else:
        res.json.return_value = {}
    return res


@pytest.fixture(autouse=True)
def _reset_cooldowns():
    GeminiService._cooldown_until.clear()
    yield
    GeminiService._cooldown_until.clear()


@pytest.mark.asyncio
async def test_rate_limited_key_falls_over_to_next_key():
    service = GeminiService(api_keys=["key-a", "key-b"])
    responses = [_response(429), _response(200, "Breathe with me.")]

    with patch("httpx.AsyncClient.post", new=AsyncMock(side_effect=responses)) as post:
        resp = await service.get_response(message="Hello there", buddy_name="Pip")

    assert resp.response == "Breathe with me."
    assert resp.model_used == service.model
    assert post.await_count == 2
    # Key travels in a header, never in the URL.
    first_call = post.await_args_list[0]
    url = first_call.args[0]
    assert first_call.kwargs["headers"]["x-goog-api-key"] == "key-a"
    assert "key" not in url.lower()


@pytest.mark.asyncio
async def test_network_error_moves_to_next_key():
    service = GeminiService(api_keys=["key-a", "key-b"])
    side_effects = [httpx.ConnectError("boom"), _response(200, "Still here.")]

    with patch("httpx.AsyncClient.post", new=AsyncMock(side_effect=side_effects)):
        resp = await service.get_response(message="Hi", buddy_name="Pip")

    assert resp.response == "Still here."


@pytest.mark.asyncio
async def test_all_keys_fail_uses_rules_fallback():
    service = GeminiService(api_keys=["key-a", "key-b", "key-c"])
    side_effects = [_response(500), _response(403), _response(429)]

    with patch("httpx.AsyncClient.post", new=AsyncMock(side_effect=side_effects)):
        resp = await service.get_response(
            message="I feel so stressed", buddy_name="Pip", tone="gentle"
        )

    assert resp.model_used == "fallback-rules"
    assert "988" in resp.response


@pytest.mark.asyncio
async def test_rejected_key_is_skipped_on_next_request():
    service = GeminiService(api_keys=["bad-key", "good-key"])

    # First request: bad-key rejected (403), good-key answers.
    with patch(
        "httpx.AsyncClient.post",
        new=AsyncMock(side_effect=[_response(403), _response(200, "One.")]),
    ):
        await service.get_response(message="Hi", buddy_name="Pip")

    # Second request: bad-key is cooling down, so only good-key is called.
    post = AsyncMock(return_value=_response(200, "Two."))
    with patch("httpx.AsyncClient.post", new=post):
        resp = await service.get_response(message="Again", buddy_name="Pip")

    assert resp.response == "Two."
    assert post.await_count == 1
    assert post.await_args.kwargs["headers"]["x-goog-api-key"] == "good-key"


def test_duplicate_and_blank_keys_are_removed():
    service = GeminiService(api_keys=["k1", "", "k1", "k2"])
    assert service.api_keys == ["k1", "k2"]


@pytest.mark.asyncio
async def test_no_keys_means_rules_only():
    service = GeminiService(api_keys=[])
    resp = await service.get_response(message="I am stressed", buddy_name="Pip")
    assert resp.model_used == "fallback-rules"


def test_system_prompt_is_counsellor_and_not_empty():
    prompt = GeminiService(api_keys=[])._build_system_prompt("Pip", "gentle", None)
    assert prompt.strip()
    assert "counsellor" in prompt
    assert "Listen first" in prompt

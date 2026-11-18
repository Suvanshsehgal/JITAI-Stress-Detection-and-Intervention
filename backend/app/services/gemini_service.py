import hashlib
import time
import httpx
from typing import Optional, List, Dict, Any, Tuple
from app.config import settings
from app.core.logging import logger
from app.models.schemas import ChatMessageItem, BuddyChatResponse

CRISIS_KEYWORDS = [
    "suicide", "kill myself", "end my life", "want to die",
    "hurt myself", "self harm", "cut myself", "take my life"
]

CRISIS_RESPONSE = (
    "I'm hearing how much pain you're in, and I want to make sure you're safe right now. "
    "Please know that you are not alone and help is available 24/7:\n\n"
    "• Call or text 988 (Suicide & Crisis Lifeline - US & Canada)\n"
    "• Text HOME to 741741 to connect with the Crisis Text Line\n"
    "• In the UK: Call 111 or text SHOUT to 85258\n"
    "• In an emergency, please reach out to your local emergency services or a trusted person immediately."
)

# How long a key is skipped after a failure (seconds).
COOLDOWN_RATE_LIMIT = 60      # 429: quota / rate limit, usually recovers quickly
COOLDOWN_REJECTED = 3600      # 400/401/403: key invalid, disabled or blocked
COOLDOWN_SERVER = 15          # 5xx / timeout / network error: transient


def _key_id(api_key: str) -> str:
    """Short, non-reversible id so keys are never stored or logged in plain text."""
    return hashlib.sha256(api_key.encode("utf-8")).hexdigest()[:12]


class GeminiService:
    # Shared across requests: key id -> monotonic time until which it is skipped.
    _cooldown_until: Dict[str, float] = {}

    def __init__(
        self,
        api_key: Optional[str] = None,
        model: Optional[str] = None,
        api_keys: Optional[List[str]] = None,
    ):
        if api_keys is not None:
            keys = list(api_keys)
        elif api_key is not None:
            keys = [api_key]
        else:
            keys = list(settings.GEMINI_API_KEYS)
        self.api_keys: List[str] = []
        for k in keys:
            if k and k not in self.api_keys:
                self.api_keys.append(k)
        self.model = model or settings.GEMINI_MODEL
        self.fallback_model = settings.GEMINI_FALLBACK_MODEL

    @property
    def api_key(self) -> Optional[str]:
        return self.api_keys[0] if self.api_keys else None

    def _build_system_prompt(
        self,
        buddy_name: str,
        tone: str,
        context: Optional[Dict[str, Any]] = None,
    ) -> str:
        # Tone nuance
        if tone == "playful":
            tone_guidance = (
                "Your tone is PLAYFUL, encouraging, and warm. Use gentle, lighthearted humor "
                "to ease tension when appropriate, but never dismiss genuine pain. Be an uplifting, supportive buddy."
            )
        elif tone == "straightTalking":
            tone_guidance = (
                "Your tone is STRAIGHT-TALKING, direct, and grounded. Skip pleasantries or toxic positivity. "
                "Focus candidly on actionable, realistic micro-steps and grounding the user in reality."
            )
        else:  # gentle
            tone_guidance = (
                "Your tone is GENTLE, soothing, and deeply compassionate. Speak warmly with calming pacing, "
                "validating their feelings and helping them feel safe and understood."
            )

        # Context cues
        context_str = ""
        if context:
            state = context.get("state")
            hr = context.get("heartRateBpm")
            mood = context.get("recentMood")
            cues = []
            if state:
                cues.append(f"Estimated stress state: {state}")
            if hr:
                cues.append(f"Recent heart rate: {hr} bpm")
            if mood:
                cues.append(f"Recent self-reported mood: {mood}/5")
            if cues:
                context_str = f"\nCurrent User Context Signals:\n- " + "\n- ".join(cues) + "\n(Subtly calibrate your empathy to these cues, without diagnosing or sounding robotic)."

        prompt = f"""You are {buddy_name}, a warm and professional counsellor in the Stride Probe wellbeing app.
You help the person understand their own feelings and work through stress. You listen first.

ROLE & PERSONALITY:
{tone_guidance}

HOW TO COUNSEL:
- Listen first. Reflect back what you heard, in the person's own words, and name the feeling you sense.
- Ask one open, curious question at a time to understand their situation (what happened, what it feels like, what they have already tried).
- Explore before advising. Offer a coping technique only after you understand the situation, and only if the person wants one or it clearly fits.
- Never give a list of exercises in one reply. Mention at most one idea, and only when it helps.
- Keep replies warm and short: 2 to 4 sentences.
- Reply in the same language the person uses.

SAFETY & BOUNDARIES:
- You are a supportive counsellor for everyday stress, NOT a medical doctor, psychiatrist, or licensed clinical therapist.
- Do NOT give clinical diagnoses or recommend medication or medical treatment.
- If the person mentions wanting to harm themselves or being in crisis, give immediate helpline resources and encourage them to reach out to someone now.{context_str}
"""

        return prompt

    def _fallback_response(self, message: str, buddy_name: str, tone: str) -> str:
        # No canned advice: when the AI is unreachable we say so honestly.
        return (
            "I'm having trouble connecting right now, so I can't respond properly. "
            "Please try again in a moment. If you feel unsafe at any time, "
            "call or text 988 (US & Canada) or your local emergency number."
        )

    def _available_keys(self) -> List[str]:
        now = time.monotonic()
        return [k for k in self.api_keys if self._cooldown_until.get(_key_id(k), 0) <= now]

    def _cool_down(self, api_key: str, seconds: int) -> None:
        self._cooldown_until[_key_id(api_key)] = time.monotonic() + seconds

    async def _call_gemini(self, api_key: str, payload: Dict[str, Any], model: str) -> Tuple[int, Optional[str]]:
        """One request with one key. Returns (http_status, reply_text_or_None)."""
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
        # Key goes in a header, not the URL, so it does not end up in access logs.
        headers = {"x-goog-api-key": api_key, "Content-Type": "application/json"}
        async with httpx.AsyncClient(timeout=15.0) as client:
            res = await client.post(url, json=payload, headers=headers)

        if res.status_code != 200:
            return res.status_code, None

        data = res.json()
        candidates = data.get("candidates", [])
        if candidates:
            parts = candidates[0].get("content", {}).get("parts", [])
            if parts and "text" in parts[0]:
                text = parts[0]["text"].strip()
                if text:
                    return 200, text
        return 200, None

    async def _try_keys(self, model: str, payload: Dict[str, Any]) -> Optional[str]:
        """Try each usable key for one model. Returns the reply text, or None if all failed."""
        candidate_keys = self._available_keys() or list(self.api_keys)
        for position, api_key in enumerate(candidate_keys, start=1):
            label = f"{model} key {position}/{len(candidate_keys)}"
            try:
                status, text = await self._call_gemini(api_key, payload, model)
            except Exception as e:  # timeout, DNS, connection reset, bad JSON...
                logger.warning(f"Gemini {label}: request error ({type(e).__name__}); trying next key.")
                self._cool_down(api_key, COOLDOWN_SERVER)
                continue

            if status == 200 and text:
                return text

            if status == 429:
                self._cool_down(api_key, COOLDOWN_RATE_LIMIT)
            elif status in (400, 401, 403):
                self._cool_down(api_key, COOLDOWN_REJECTED)
            else:
                self._cool_down(api_key, COOLDOWN_SERVER)
            logger.warning(f"Gemini {label}: status {status}; trying next key.")
        return None

    async def get_response(
        self,
        message: str,
        buddy_name: str = "Pip",
        tone: str = "gentle",
        history: Optional[List[ChatMessageItem]] = None,
        context: Optional[Dict[str, Any]] = None,
    ) -> BuddyChatResponse:
        clean_msg = message.strip()
        lower_msg = clean_msg.lower()

        # 1. Immediate Safety Crisis Check (always runs first, no API call)
        if any(keyword in lower_msg for keyword in CRISIS_KEYWORDS):
            logger.warning("Safety crisis keyword detected; returning helpline resources.")
            return BuddyChatResponse(
                response=CRISIS_RESPONSE,
                buddy_name=buddy_name,
                tone=tone,
                model_used="safety-crisis-guardrail",
            )

        # 2. No usable key at all -> deterministic rules
        if not self.api_keys:
            logger.info("No Gemini API key configured. Using deterministic fallback response.")
            return self._rules_reply(clean_msg, buddy_name, tone)

        # 3. Build the Gemini request once, then try keys in order
        system_instruction = self._build_system_prompt(buddy_name, tone, context)

        contents = []
        if history:
            for item in history[-6:]:  # Keep last 6 messages for context
                gemini_role = "user" if item.role in ["user", "human"] else "model"
                contents.append({
                    "role": gemini_role,
                    "parts": [{"text": item.content}]
                })
        contents.append({
            "role": "user",
            "parts": [{"text": clean_msg}]
        })

        payload = {
            "system_instruction": {
                "parts": [{"text": system_instruction}]
            },
            "contents": contents,
            "generationConfig": {
                "temperature": 0.7,
                "topP": 0.9,
                "maxOutputTokens": 300,
            }
        }

        models = [self.model]
        if self.fallback_model and self.fallback_model not in models:
            models.append(self.fallback_model)

        for model in models:
            reply = await self._try_keys(model, payload)
            if reply is not None:
                return BuddyChatResponse(
                    response=reply,
                    buddy_name=buddy_name,
                    tone=tone,
                    model_used=model,
                )
            logger.warning(f"Model {model} failed on all keys; trying fallback model.")

        logger.error("All Gemini models and keys failed. Returning unavailable message.")
        return self._rules_reply(clean_msg, buddy_name, tone)

    def _rules_reply(self, clean_msg: str, buddy_name: str, tone: str) -> BuddyChatResponse:
        return BuddyChatResponse(
            response=self._fallback_response(clean_msg, buddy_name, tone),
            buddy_name=buddy_name,
            tone=tone,
            model_used="fallback-rules",
        )

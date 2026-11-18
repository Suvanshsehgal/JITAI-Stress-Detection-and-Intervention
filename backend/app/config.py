import os
from pathlib import Path
from typing import List
from pydantic import BaseModel


def _load_dotenv(path: Path) -> None:
    """Minimal .env loader (no extra dependency). Existing env vars win."""
    if not path.is_file():
        return
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key and key not in os.environ:
            os.environ[key] = value


_load_dotenv(Path(__file__).resolve().parents[1] / ".env")


def load_gemini_keys() -> List[str]:
    """
    Collect Gemini API keys in priority order, de-duplicated:
      1. GEMINI_API_KEYS  (comma-separated list)
      2. GEMINI_API_KEY_1 .. GEMINI_API_KEY_10 (one per variable)
      3. GEMINI_API_KEY   (single key, kept for backward compatibility)
    """
    keys: List[str] = []
    raw_list = os.getenv("GEMINI_API_KEYS", "")
    keys.extend(part.strip() for part in raw_list.split(","))
    for i in range(1, 11):
        keys.append(os.getenv(f"GEMINI_API_KEY_{i}", "").strip())
    keys.append(os.getenv("GEMINI_API_KEY", "").strip())

    unique: List[str] = []
    for k in keys:
        if k and k not in unique:
            unique.append(k)
    return unique


class Settings(BaseModel):
    PROJECT_NAME: str = "Ebb JITAI Backend"
    API_V1_STR: str = "/api/v1"
    SECRET_KEY: str = os.getenv("EBB_SECRET_KEY", "ebb-jitai-insecure-dev-secret-key-32chars-min!!")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    CORS_ORIGINS: List[str] = ["*"]
    MODEL_VERSION: str = "stride-probe-composite-v1.0"
    JITAI_COOLDOWN_MINUTES: int = 15
    SUPABASE_URL: str = os.getenv("SUPABASE_URL", "https://vjbhmyyeqenlypyqufgd.supabase.co")
    SUPABASE_KEY: str = os.getenv("SUPABASE_KEY", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZqYmhteXllcWVubHlweXF1ZmdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc4MjU3ODQsImV4cCI6MjA5MzQwMTc4NH0.WoMAmiDnaEFs-Ad_WuX37tHlajGSQIAdxv2jf6X2eU4")
    SUPABASE_SERVICE_ROLE_KEY: str = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    GEMINI_API_KEYS: List[str] = load_gemini_keys()
    GEMINI_MODEL: str = os.getenv("GEMINI_MODEL", "gemini-flash-latest")
    GEMINI_FALLBACK_MODEL: str = os.getenv("GEMINI_FALLBACK_MODEL", "gemini-3.5-flash")

settings = Settings()


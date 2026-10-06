import os
from typing import List
from pydantic import BaseModel

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

settings = Settings()


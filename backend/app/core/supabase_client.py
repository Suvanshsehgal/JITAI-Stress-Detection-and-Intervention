"""
Supabase client helper for FastAPI backend.
Uses httpx directly to communicate with Supabase REST API (PostgREST / Auth)
without requiring heavy external dependencies.
"""
from typing import Any, Dict, List, Optional
import httpx
from app.config import settings
from app.core.logging import log_safe_event

class SupabaseBackendClient:
    def __init__(self):
        self.base_url = settings.SUPABASE_URL.rstrip("/")
        # Use service role key if available, else anon key
        self.api_key = settings.SUPABASE_SERVICE_ROLE_KEY or settings.SUPABASE_KEY
        self.headers = {
            "apikey": self.api_key,
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
            "Prefer": "return=representation",
        }

    async def insert(self, table: str, record: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Inserts a single row into a Supabase table."""
        url = f"{self.base_url}/rest/v1/{table}"
        try:
            async with httpx.AsyncClient(timeout=8.0) as client:
                res = await client.post(url, headers=self.headers, json=record)
                if res.status_code in (200, 201):
                    data = res.json()
                    return data[0] if isinstance(data, list) and data else data
                log_safe_event("supabase_insert_failed", table=table, status_code=res.status_code)
        except Exception as e:
            log_safe_event("supabase_insert_exception", table=table, error=str(e))
        return None

    async def upsert(self, table: str, records: List[Dict[str, Any]]) -> bool:
        """Upserts multiple rows into a Supabase table."""
        url = f"{self.base_url}/rest/v1/{table}"
        headers = {**self.headers, "Prefer": "resolution=merge-duplicates,return=representation"}
        try:
            async with httpx.AsyncClient(timeout=8.0) as client:
                res = await client.post(url, headers=headers, json=records)
                return res.status_code in (200, 201)
        except Exception as e:
            log_safe_event("supabase_upsert_exception", table=table, error=str(e))
        return False

    async def select(self, table: str, params: Optional[Dict[str, str]] = None) -> List[Dict[str, Any]]:
        """Queries rows from a Supabase table."""
        url = f"{self.base_url}/rest/v1/{table}"
        try:
            async with httpx.AsyncClient(timeout=8.0) as client:
                res = await client.get(url, headers=self.headers, params=params)
                if res.status_code == 200:
                    return res.json()
        except Exception as e:
            log_safe_event("supabase_select_exception", table=table, error=str(e))
        return []

supabase_backend = SupabaseBackendClient()

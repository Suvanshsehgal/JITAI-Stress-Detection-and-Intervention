from fastapi import APIRouter, status
from app.models.schemas import BuddyChatRequest, BuddyChatResponse
from app.services.gemini_service import GeminiService

router = APIRouter(prefix="/buddy", tags=["Buddy & Companion Chat"])

_gemini_service = GeminiService()

@router.post("/chat", response_model=BuddyChatResponse, status_code=status.HTTP_200_OK)
async def chat_with_buddy(req: BuddyChatRequest):
    """
    Generate an empathetic, context-aware companion response using Gemini LLM
    tailored to the user's companion name, selected tone (gentle, playful, straight-talking),
    and current stress/health signals.
    """
    response = await _gemini_service.get_response(
        message=req.message,
        buddy_name=req.buddy_name or "Pip",
        tone=req.tone or "gentle",
        history=req.history,
        context=req.context,
    )
    return response

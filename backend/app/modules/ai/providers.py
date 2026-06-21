"""AI generation provider (Anthropic Claude) with stub fallback."""
import logging
from dataclasses import dataclass

from app.core.config import settings

logger = logging.getLogger("ai")

ANTHROPIC_URL = "https://api.anthropic.com/v1/messages"
_TIMEOUT = 60.0


@dataclass
class AIResult:
    text: str
    provider: str  # "anthropic" | "stub"


class AIProvider:
    @staticmethod
    def _ready() -> bool:
        return bool(settings.ANTHROPIC_API_KEY)

    async def generate(self, prompt: str, system: str | None = None) -> AIResult:
        if not self._ready():
            logger.info("[STUB ai] feature prompt=%r", prompt[:80])
            return AIResult(
                text=f"[AI stub response] {prompt.strip()[:200]}",
                provider="stub",
            )
        import httpx

        headers = {
            "x-api-key": settings.ANTHROPIC_API_KEY,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json",
        }
        payload: dict = {
            "model": settings.AI_MODEL,
            "max_tokens": 1024,
            "messages": [{"role": "user", "content": prompt}],
        }
        if system:
            payload["system"] = system
        async with httpx.AsyncClient(timeout=_TIMEOUT) as client:
            resp = await client.post(ANTHROPIC_URL, json=payload, headers=headers)
        resp.raise_for_status()
        data = resp.json()
        text = "".join(block.get("text", "") for block in data.get("content", []))
        return AIResult(text=text, provider="anthropic")


ai_provider = AIProvider()

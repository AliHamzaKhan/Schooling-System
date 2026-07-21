"""AI generation provider (Anthropic Claude) with stub fallback."""
import json
import logging
from dataclasses import dataclass
from typing import Any

from app.core.config import settings

logger = logging.getLogger("ai")

ANTHROPIC_URL = "https://api.anthropic.com/v1/messages"
ANTHROPIC_VERSION = "2023-06-01"
_TIMEOUT = 60.0


@dataclass
class AIResult:
    text: str
    provider: str  # "anthropic" | "stub"


@dataclass
class AIJsonResult:
    data: Any
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

    async def generate_json(
        self,
        prompt: str,
        schema: dict,
        *,
        system: str | None = None,
        stub: Any = None,
        max_tokens: int = 8000,
        effort: str = "medium",
    ) -> AIJsonResult:
        """Generate a response constrained to ``schema``.

        Uses the Messages API structured-outputs feature (``output_config.format``
        with a JSON schema), so the model cannot return prose, a fenced code
        block, or a shape we did not ask for — the first content block is
        guaranteed to be valid JSON matching ``schema``. That removes the
        brittle "parse whatever came back" step entirely.

        Returns ``stub`` unchanged when no API key is configured, keeping the
        feature exercisable in dev and tests without secrets.
        """
        if not self._ready():
            logger.info("[STUB ai] json prompt=%r", prompt[:80])
            return AIJsonResult(data=stub, provider="stub")
        import httpx

        headers = {
            "x-api-key": settings.ANTHROPIC_API_KEY,
            "anthropic-version": ANTHROPIC_VERSION,
            "content-type": "application/json",
        }
        payload: dict = {
            "model": settings.AI_MODEL,
            "max_tokens": max_tokens,
            "messages": [{"role": "user", "content": prompt}],
            "output_config": {
                "format": {"type": "json_schema", "schema": schema},
                "effort": effort,
            },
        }
        if system:
            payload["system"] = system
        async with httpx.AsyncClient(timeout=_TIMEOUT) as client:
            resp = await client.post(ANTHROPIC_URL, json=payload, headers=headers)
        resp.raise_for_status()
        body = resp.json()

        # A refusal or a token-capped response yields no usable JSON; surface it
        # rather than letting json.loads raise something unhelpful.
        if body.get("stop_reason") == "refusal":
            raise ValueError("The AI declined this request. Try rewording the topic.")
        text = "".join(
            block.get("text", "")
            for block in body.get("content", [])
            if block.get("type") == "text"
        )
        if body.get("stop_reason") == "max_tokens" or not text.strip():
            raise ValueError("The AI response was cut short. Try requesting fewer questions.")
        return AIJsonResult(data=json.loads(text), provider="anthropic")


ai_provider = AIProvider()

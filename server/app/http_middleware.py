"""HTTP middleware: long-running request timeout for analyze / generate-prompt."""

from __future__ import annotations

import asyncio
import os

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse, Response


def request_timeout_seconds() -> float:
    raw = os.getenv("REQUEST_TIMEOUT_SECONDS", "360").strip()
    try:
        return float(max(60.0, min(float(raw), 600.0)))
    except ValueError:
        return 360.0


class RequestTimeoutMiddleware(BaseHTTPMiddleware):
    """Abort requests that exceed [request_timeout_seconds] (default 4 minutes)."""

    def __init__(self, app, timeout_s: float | None = None) -> None:
        super().__init__(app)
        self._timeout_s = timeout_s if timeout_s is not None else request_timeout_seconds()

    async def dispatch(self, request: Request, call_next) -> Response:
        try:
            return await asyncio.wait_for(call_next(request), timeout=self._timeout_s)
        except asyncio.TimeoutError:
            return JSONResponse(
                status_code=504,
                content={
                    "detail": (
                        "Request timed out on the server. "
                        "Try a shorter audio clip, or retry. "
                        "Gemini 2.5 Flash (draft + polish) can take 2–5 minutes. "
                        "Set PROMPT_PIPELINE=single for a faster single pass."
                    )
                },
            )

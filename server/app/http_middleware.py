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





def songwriter_http_timeout_seconds() -> float:

    """HTTP wait for /generate-lyrics (12 LLM stages need more than default 6 min)."""

    raw = os.getenv("SONGWRITER_HTTP_TIMEOUT_SECONDS", "").strip()

    if not raw:

        # Default: request budget (780) + cushion so pipeline can return partials.

        raw = os.getenv("SONGWRITER_REQUEST_BUDGET_SECONDS", "900")

    try:

        return float(max(180.0, min(float(raw), 1200.0)))

    except ValueError:

        return 900.0





class RequestTimeoutMiddleware(BaseHTTPMiddleware):

    """Abort requests that exceed the configured timeout."""



    def __init__(self, app, timeout_s: float | None = None) -> None:

        super().__init__(app)

        self._timeout_s = timeout_s if timeout_s is not None else request_timeout_seconds()



    def _timeout_for(self, path: str) -> float:

        if path.rstrip("/").endswith("generate-lyrics"):

            return songwriter_http_timeout_seconds()

        return self._timeout_s



    async def dispatch(self, request: Request, call_next) -> Response:

        timeout_s = self._timeout_for(request.url.path)

        try:

            return await asyncio.wait_for(call_next(request), timeout=timeout_s)

        except asyncio.TimeoutError:

            is_lyrics = request.url.path.rstrip("/").endswith("generate-lyrics")

            detail = (

                "Songwriter pipeline timed out on the server. "

                "Full song mode can take 8–12 minutes. "

                "Try Chorus only, or set SONGWRITER_HTTP_TIMEOUT_SECONDS=900."

                if is_lyrics

                else (

                    "Request timed out on the server. "

                    "Try a shorter audio clip, or retry. "

                    "Gemini 2.5 Flash (draft + polish) can take 2–5 minutes. "

                    "Set PROMPT_PIPELINE=single for a faster single pass, "

                    "or PROMPT_PIPELINE=two_pass for Architect→Lyricist."

                )

            )

            return JSONResponse(

                status_code=504,

                content={"detail": detail},

            )



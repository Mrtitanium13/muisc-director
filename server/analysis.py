"""Launch Music Director FastAPI server (analyze + generate-prompt)."""

from __future__ import annotations

import os
from pathlib import Path

from dotenv import load_dotenv

load_dotenv(Path(__file__).resolve().parent / ".env")

if __name__ == "__main__":
    import uvicorn

    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "8080"))
    reload = os.getenv("UVICORN_RELOAD", "").strip().lower() in ("1", "true", "yes", "on")

    print(f"Music Director API at http://{host}:{port}")
    print(f"Health check at http://127.0.0.1:{port}/health")
    print("Analyze endpoint: POST /analyze (multipart file)")

    uvicorn.run(
        "app.main:app",
        host=host,
        port=port,
        reload=reload,
        timeout_keep_alive=300,
        timeout_graceful_shutdown=120,
    )

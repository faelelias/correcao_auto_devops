from fastapi import FastAPI, Body
import httpx
import os

app = FastAPI(title="app-service", version="0.1.0")


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/errors")
async def handle_error(payload: dict = Body(...)):
    """
    Recebe um evento de erro e chama o ml-service para classificação/sugestão.
    """
    ml_url = payload.get("ml_url", os.getenv("ML_SERVICE_URL", "http://ml-service:8000/predict"))
    async with httpx.AsyncClient(timeout=5) as client:
        try:
            resp = await client.post(ml_url, json=payload)
            resp.raise_for_status()
            suggestion = resp.json()
        except Exception as exc:  # pragma: no cover - placeholder
            suggestion = {"error": str(exc)}
    return {"received": payload, "suggestion": suggestion}


@app.post("/feedback")
async def feedback(payload: dict = Body(...)):
    """
    Registra feedback de uma correção aplicada (placeholder).
    Integração real com Mongo/metrics deve ser adicionada.
    """
    return {"ack": True, "payload": payload}



from fastapi import FastAPI, Body

app = FastAPI(title="ml-service", version="0.1.0")


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/predict")
async def predict(payload: dict = Body(...)):
    """
    Placeholder de inferência.
    Substitua pela carga do modelo (ex: S3) e lógica real.
    """
    # Exemplo de resposta simulada
    return {
        "classification": "config_issue",
        "confidence": 0.42,
        "action": "restart_pod",
        "notes": "Stub de inferência. Substituir por modelo treinado.",
        "input": payload,
    }



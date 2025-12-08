from fastapi.testclient import TestClient
from app.src.main import app


client = TestClient(app)


def test_health():
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"


def test_errors_stub():
    payload = {"message": "error", "service": "demo"}
    resp = client.post("/errors", json=payload)
    assert resp.status_code == 200
    body = resp.json()
    assert "received" in body



# app-service

API principal responsável por receber eventos de erro, consultar o `ml-service` para classificação/sugestão de correção e registrar feedback no MongoDB.

Endpoints :
- `POST /errors`: recebe erro, envia para ML, registra em MongoDB.
- `POST /feedback`: recebe feedback de correções aplicadas.

Execução local:
```
python -m venv .venv
source .venv/Scripts/activate  # Windows: .venv\Scripts\activate
pip install fastapi uvicorn pymongo httpx
uvicorn main:app --reload --port 8000
```



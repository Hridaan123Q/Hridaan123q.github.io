from fastapi.testclient import TestClient
from jarvis_backend.main import app

client = TestClient(app)

def test_execute_command():
    response = client.post("/execute", json={"command": "hello test"})
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert data["result"] == "Agent simulated execution for: hello test"

import pytest

from app.app import app


@pytest.fixture()
def client(monkeypatch):
    monkeypatch.delenv("APP_ENV", raising=False)
    monkeypatch.delenv("APP_MESSAGE", raising=False)
    monkeypatch.delenv("API_KEY", raising=False)
    app.config.update(TESTING=True)
    with app.test_client() as test_client:
        yield test_client


def test_home_returns_200_and_default_environment(client):
    response = client.get("/")
    assert response.status_code == 200
    assert b"Projet fil rouge Kubernetes" in response.data
    assert b"development" in response.data


def test_environment_and_message_can_be_configured(client, monkeypatch):
    monkeypatch.setenv("APP_ENV", "formation")
    monkeypatch.setenv("APP_MESSAGE", "Bonjour la classe")
    response = client.get("/")
    assert response.status_code == 200
    assert b"formation" in response.data
    assert b"Bonjour la classe" in response.data


def test_health_endpoint(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.get_json() == {"status": "ok"}


def test_readiness_endpoint(client):
    response = client.get("/ready")
    assert response.status_code == 200
    assert response.get_json() == {"status": "ready"}


def test_secret_value_is_never_rendered(client, monkeypatch):
    monkeypatch.setenv("API_KEY", "super-secret-value")
    response = client.get("/")
    assert response.status_code == 200
    assert b"super-secret-value" not in response.data
    assert b"Cl\xc3\xa9 API configur\xc3\xa9e" in response.data
    assert b"oui" in response.data

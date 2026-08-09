"""
app/tests/test_main.py — Unit tests for the Flask microservice
"""
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import pytest
from main import app as flask_app


@pytest.fixture()
def client():
    flask_app.config["TESTING"] = True
    with flask_app.test_client() as c:
        yield c


# ─── Health probes ────────────────────────────────────────────────────────────
def test_liveness(client):
    r = client.get("/health/live")
    assert r.status_code == 200
    assert r.get_json()["status"] == "alive"


def test_readiness(client):
    r = client.get("/health/ready")
    assert r.status_code == 200
    data = r.get_json()
    assert data["status"] == "ready"
    assert "uptime_seconds" in data


# ─── Index & API Info ────────────────────────────────────────────────────────
def test_index(client):
    r = client.get("/")
    assert r.status_code == 200
    # Root now returns HTML, not JSON
    assert b"DevSecOps Architecture" in r.data


def test_api_info(client):
    r = client.get("/api/v1/info")
    assert r.status_code == 200
    assert "DevSecOps" in r.get_json()["message"]


# ─── Items API ───────────────────────────────────────────────────────────────
def test_list_items(client):
    r = client.get("/api/v1/items")
    assert r.status_code == 200
    data = r.get_json()
    assert data["count"] == 2
    assert len(data["items"]) == 2


def test_get_item_found(client):
    r = client.get("/api/v1/items/1")
    assert r.status_code == 200
    assert r.get_json()["id"] == 1


def test_get_item_not_found(client):
    r = client.get("/api/v1/items/999")
    assert r.status_code == 404
    assert "error" in r.get_json()


# ─── Metrics ─────────────────────────────────────────────────────────────────
def test_metrics_endpoint(client):
    r = client.get("/metrics")
    assert r.status_code == 200
    assert b"http_requests_total" in r.data

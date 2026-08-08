"""
app/main.py — Sample Flask microservice
Demonstrates: health checks, structured logging, Prometheus metrics endpoint
"""

import logging
import os
import time

from flask import Flask, jsonify, request
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

# ─── Structured logging ───────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format='{"time": "%(asctime)s", "level": "%(levelname)s", "msg": "%(message)s"}',
)
logger = logging.getLogger(__name__)

# ─── Prometheus metrics ───────────────────────────────────────────────────────
REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP request count",
    ["method", "endpoint", "status"],
)
REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency",
    ["endpoint"],
)

# ─── Flask app ────────────────────────────────────────────────────────────────
app = Flask(__name__)
START_TIME = time.time()


@app.before_request
def start_timer():
    request.start_time = time.time()


@app.after_request
def record_metrics(response):
    latency = time.time() - request.start_time
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.path,
        status=response.status_code,
    ).inc()
    REQUEST_LATENCY.labels(endpoint=request.path).observe(latency)
    return response


# ─── Routes ──────────────────────────────────────────────────────────────────
@app.route("/")
def index():
    return jsonify(
        message="🚀 DevSecOps Platform — Sample Microservice",
        version=os.getenv("APP_VERSION", "0.1.0"),
        environment=os.getenv("APP_ENV", "dev"),
    )


@app.route("/health/live")
def liveness():
    """Kubernetes liveness probe."""
    return jsonify(status="alive"), 200


@app.route("/health/ready")
def readiness():
    """Kubernetes readiness probe."""
    return jsonify(status="ready", uptime_seconds=round(time.time() - START_TIME, 2)), 200


@app.route("/metrics")
def metrics():
    """Prometheus scrape endpoint."""
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}


@app.route("/api/v1/items", methods=["GET"])
def list_items():
    items = [
        {"id": 1, "name": "Widget Alpha", "category": "hardware"},
        {"id": 2, "name": "Widget Beta",  "category": "software"},
    ]
    logger.info("Listed %d items", len(items))
    return jsonify(items=items, count=len(items))


@app.route("/api/v1/items/<int:item_id>", methods=["GET"])
def get_item(item_id: int):
    if item_id not in (1, 2):
        logger.warning("Item %d not found", item_id)
        return jsonify(error="Item not found"), 404
    return jsonify(id=item_id, name=f"Widget {'Alpha' if item_id == 1 else 'Beta'}")


if __name__ == "__main__":
    port = int(os.getenv("PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=os.getenv("FLASK_DEBUG", "false") == "true")

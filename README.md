# Cloud DevOps Loop Demo: License Server

A minimal end-to-end demo for an automotive software context: a small license server (borrow/return licenses for engineering tools) with:

- API built with FastAPI and SQLite
- CI (GitHub Actions) running tests and building a Docker image
- Containerization via Dockerfile
- Observability with Prometheus metrics and Grafana dashboard (via docker-compose)

## Why this demo

- Commit -> CI -> Test -> Build -> Deploy -> Observe
- Realistic Ops signals: capacity exhaustion, borrow/return rates, latencies

## Quickstart (Local)

Prerequisites: Docker and Docker Compose.

```bash
# From repository root
docker compose up --build
# API at http://localhost:8000
# Prometheus at http://localhost:9090
# Grafana at http://localhost:3000 (admin/admin)
```

Useful API calls:

```bash
# Check status for a tool (seeded defaults: cad_tool=5, simulation=3, analysis=2)
curl http://localhost:8000/licenses/cad_tool/status

# Borrow a license
curl -X POST http://localhost:8000/licenses/borrow \
  -H 'Content-Type: application/json' \
  -d '{"tool":"cad_tool", "user":"alice"}'

# Return a license (replace <id>)
curl -X POST http://localhost:8000/licenses/return \
  -H 'Content-Type: application/json' \
  -d '{"id":"<id>"}'

# Metrics
curl http://localhost:8000/metrics
```

## Run locally (Python)

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

## CI Pipeline (GitHub Actions)

- Triggers on push/PR to `main`/`master`
- Steps:
  - Install dependencies
  - Run tests (`pytest`)
  - Build Docker image (no push by default)

See `.github/workflows/ci.yml`.

## Observability

- Prometheus scrapes the API at `/metrics`
- Included metrics:
  - `license_borrow_attempts_total{tool}`
  - `license_borrow_success_total{tool}`
  - `license_borrow_failure_total{tool,reason}`
  - `license_borrow_duration_seconds_bucket{tool}`
  - `licenses_borrowed{tool}`
- Grafana is pre-provisioned with Prometheus datasource; create a dashboard and panels targeting these metrics

## Configuration

- `LICENSE_DB_PATH`: path to SQLite DB (defaults to `licenses.db`)
- `LICENSE_DB_SEED`: `true`/`false`; when `true`, seeds default tools

## Tests

```bash
pytest -q
```

Tests cover core borrow/return flows and the metrics endpoint presence.

## Extend ideas

- Add authentication (OIDC) and per-team quotas
- Persist to Postgres and add migrations
- Push Docker image to GHCR in CI and deploy to a k8s namespace (Helm)
- Add alerting rules (Prometheus) for license exhaustion and SLOs



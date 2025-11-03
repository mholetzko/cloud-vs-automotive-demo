#!/usr/bin/env bash
set -euo pipefail

# Local DevOps loop simulator:
# 1) ensure venv, install deps
# 2) run tests
# 3) build docker image
# 4) docker compose up (API+Prometheus+Grafana)
# 5) hit API to generate metrics

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "[1/5] Ensuring Python venv and installing dependencies..."
if [ ! -d ".venv" ]; then
  python3 -m venv .venv
fi
source .venv/bin/activate
pip install --upgrade pip >/dev/null
pip install -r requirements.txt >/dev/null

echo "[2/5] Running tests..."
export LICENSE_DB_SEED=false
export PYTHONPATH="$ROOT_DIR"
pytest -q

echo "[3/5] Building Docker image..."
docker build -t local/license-api:dev .

echo "[4/5] Starting docker compose stack..."
docker compose up -d --build

echo "Waiting for API to become ready..."
for i in {1..30}; do
  if curl -sSf http://localhost:8000/docs >/dev/null; then
    break
  fi
  sleep 1
done

echo "[5/5] Simulating traffic (borrow/return) to generate metrics..."
STATUS=$(curl -s http://localhost:8000/licenses/cad_tool/status || true)
echo "Initial status: $STATUS"
BORROW_ID=$(curl -s -X POST http://localhost:8000/licenses/borrow \
  -H 'Content-Type: application/json' \
  -d '{"tool":"cad_tool","user":"demo"}' | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])" )
echo "Borrowed id: $BORROW_ID"
curl -s -X POST http://localhost:8000/licenses/return \
  -H 'Content-Type: application/json' \
  -d "{\"id\":\"$BORROW_ID\"}" >/dev/null

echo "Current borrows:"
curl -s http://localhost:8000/borrows | head -n 40

echo "Sample metrics head:"
curl -s http://localhost:8000/metrics | head -n 20

echo "\nValidating frontend availability..."
ROOT_HTML=$(curl -sSf http://localhost:8000/ || true)
echo "$ROOT_HTML" | grep -qi "Mercedes" && echo "Root HTML OK" || echo "Root HTML missing Mercedes copy"
curl -sSf http://localhost:8000/static/style.css >/dev/null && echo "CSS OK" || echo "CSS missing"
curl -sSf http://localhost:8000/static/app.js >/dev/null && echo "JS OK" || echo "JS missing"

cat <<EOF

Stack is up. Open:
- API: http://localhost:8000
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (admin/admin)

When done:
  docker compose down -v
EOF



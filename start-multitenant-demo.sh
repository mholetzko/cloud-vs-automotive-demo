#!/bin/bash
# Start Multi-Tenant License Server Demo

echo "🚀 Starting Multi-Tenant License Server Demo..."
echo ""

# Check if venv exists
if [ ! -d ".venv" ]; then
    echo "❌ Virtual environment not found. Please run:"
    echo "   python3 -m venv .venv"
    echo "   source .venv/bin/activate"
    echo "   pip install -r requirements.txt"
    exit 1
fi

# Activate venv
source .venv/bin/activate

# Check if dependencies are installed
if ! python -c "import fastapi" 2>/dev/null; then
    echo "📦 Installing dependencies..."
    pip install fastapi uvicorn passlib python-multipart >/dev/null 2>&1
fi

echo "✅ Dependencies ready"
echo ""
echo "📊 Demo URLs:"
echo "   Vendor Portal:  http://vendor.localhost:8001"
echo "   BMW Tenant:     http://bmw.localhost:8001"
echo "   Mercedes Tenant: http://mercedes.localhost:8001"
echo "   Audi Tenant:    http://audi.localhost:8001"
echo ""
echo "💡 Tip: Open vendor portal first to see all customers"
echo ""
echo "─────────────────────────────────────────────────────────"
echo ""

# Run the demo
python multitenant_demo.py


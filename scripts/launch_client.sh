#!/usr/bin/env bash
set -e

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
DEFAULT_URL="http://localhost:8000"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLIENT_SCRIPT="${SCRIPT_DIR}/demo_client.py"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   License Server Demo Client Launcher${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python 3 is not installed${NC}"
    echo "Please install Python 3 to use this client"
    exit 1
fi

echo -e "${GREEN}✅ Python 3 found: $(python3 --version)${NC}"

# Check if requests library is installed
if ! python3 -c "import requests" &> /dev/null; then
    echo -e "${YELLOW}⚠️  requests library not found${NC}"
    echo -e "${BLUE}Installing requests...${NC}"
    pip3 install requests
    echo -e "${GREEN}✅ requests installed${NC}"
else
    echo -e "${GREEN}✅ requests library found${NC}"
fi

echo ""
echo -e "${BLUE}Select deployment target:${NC}"
echo "1) Localhost (http://localhost:8000)"
echo "2) Fly.io Production (https://license-server-demo.fly.dev)"
echo "3) Custom URL"
echo ""
read -p "Enter choice [1-3]: " choice

case $choice in
    1)
        SERVER_URL="http://localhost:8000"
        echo -e "${BLUE}→ Using localhost${NC}"
        ;;
    2)
        SERVER_URL="https://license-server-demo.fly.dev"
        echo -e "${BLUE}→ Using Fly.io production${NC}"
        ;;
    3)
        read -p "Enter custom URL: " SERVER_URL
        echo -e "${BLUE}→ Using custom URL: ${SERVER_URL}${NC}"
        ;;
    *)
        echo -e "${RED}Invalid choice, using localhost${NC}"
        SERVER_URL="http://localhost:8000"
        ;;
esac

echo ""
echo -e "${BLUE}Select mode:${NC}"
echo "1) Interactive mode (manual testing)"
echo "2) Quick simulation (1 cycle, all tools)"
echo "3) Stress test (10 cycles, all tools)"
echo "4) Custom simulation"
echo ""
read -p "Enter choice [1-4]: " mode_choice

case $mode_choice in
    1)
        echo -e "${GREEN}→ Launching interactive mode...${NC}"
        echo ""
        python3 "${CLIENT_SCRIPT}" --url "${SERVER_URL}" --interactive
        ;;
    2)
        echo -e "${GREEN}→ Running quick simulation...${NC}"
        echo ""
        python3 "${CLIENT_SCRIPT}" --url "${SERVER_URL}"
        ;;
    3)
        echo -e "${GREEN}→ Running stress test (10 cycles)...${NC}"
        echo ""
        python3 "${CLIENT_SCRIPT}" --url "${SERVER_URL}" --loop 10 --duration 2
        ;;
    4)
        read -p "Enter tool name (or press Enter for all): " tool
        read -p "Enter duration in seconds [5]: " duration
        duration=${duration:-5}
        read -p "Enter number of loops [1]: " loops
        loops=${loops:-1}
        read -p "Enter username [demo-client]: " username
        username=${username:-demo-client}
        
        echo -e "${GREEN}→ Running custom simulation...${NC}"
        echo ""
        
        cmd="python3 \"${CLIENT_SCRIPT}\" --url \"${SERVER_URL}\" --user \"${username}\" --duration ${duration} --loop ${loops}"
        
        if [ -n "$tool" ]; then
            cmd="${cmd} --tool \"${tool}\""
        fi
        
        eval $cmd
        ;;
    *)
        echo -e "${RED}Invalid choice, running quick simulation${NC}"
        echo ""
        python3 "${CLIENT_SCRIPT}" --url "${SERVER_URL}"
        ;;
esac

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ Demo client session complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Useful links:"
if [ "$SERVER_URL" == "http://localhost:8000" ]; then
    echo "  Dashboard:   http://localhost:8000"
    echo "  Grafana:     http://localhost:3000"
    echo "  Prometheus:  http://localhost:9090"
    echo "  API Docs:    http://localhost:8000/docs"
elif [ "$SERVER_URL" == "https://license-server-demo.fly.dev" ]; then
    echo "  Dashboard:   https://license-server-demo.fly.dev"
    echo "  Presentation: https://license-server-demo.fly.dev/presentation"
    echo "  API Docs:    https://license-server-demo.fly.dev/docs"
else
    echo "  Dashboard:   ${SERVER_URL}"
    echo "  API Docs:    ${SERVER_URL}/docs"
fi
echo ""


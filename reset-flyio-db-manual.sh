#!/usr/bin/env bash
set -e

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Reset Fly.io Database (Manual Steps)                  ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}⚠ This will guide you through resetting the database${NC}"
echo ""

echo -e "${BLUE}Step 1: Open SSH console${NC}"
echo -e "${YELLOW}Run this command:${NC}"
echo ""
echo "  flyctl ssh console -a license-server-demo"
echo ""
read -p "Press Enter when you're in the SSH console..."

echo ""
echo -e "${BLUE}Step 2: In the SSH console, run:${NC}"
echo ""
echo "  rm -f /data/licenses.db"
echo "  exit"
echo ""
read -p "Press Enter after you've deleted the database and exited..."

echo ""
echo -e "${BLUE}Step 3: Restarting the app...${NC}"
flyctl apps restart license-server-demo
echo -e "${GREEN}✓ App restarting${NC}"
echo ""

echo -e "${BLUE}Waiting for app to initialize (15 seconds)...${NC}"
sleep 15
echo ""

echo -e "${BLUE}Step 4: Verifying...${NC}"
echo ""

if curl -s -f https://license-server-demo.fly.dev/licenses/status > /dev/null 2>&1; then
    echo -e "${GREEN}✓ App is responding${NC}"
    echo ""
    echo -e "${BLUE}📊 New Products:${NC}"
    curl -s https://license-server-demo.fly.dev/licenses/status | jq -r '.[] | "  • \(.tool): \(.total) total (\(.commit) commit, \(.max_overage) overage)"' 2>/dev/null || \
        echo "  (Install jq to see formatted output: brew install jq)"
    echo ""
else
    echo -e "${RED}✗ App not responding yet${NC}"
    echo -e "${YELLOW}Wait a bit longer and check: flyctl logs${NC}"
fi

echo ""
echo -e "${GREEN}✓ Complete!${NC}"
echo -e "${GREEN}View at: ${NC}https://license-server-demo.fly.dev/dashboard"
echo ""


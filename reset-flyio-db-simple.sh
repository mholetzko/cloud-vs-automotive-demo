#!/usr/bin/env bash
set -e

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Reset Fly.io Database (Simple Method)                 ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}⚠ This will reset the database on next app start${NC}"
echo -e "${YELLOW}⚠ All existing license data will be lost${NC}"
echo ""
read -p "Continue? (yes/no): " -r
echo

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${RED}Aborted${NC}"
    exit 1
fi

echo -e "${BLUE}Method: We'll destroy and recreate the volume${NC}"
echo ""

echo -e "${BLUE}1️⃣  Scaling down to 0 machines...${NC}"
flyctl scale count 0 -a license-server-demo
echo -e "${GREEN}✓ Scaled down${NC}"
echo ""

sleep 3

echo -e "${BLUE}2️⃣  Destroying old volume...${NC}"
flyctl volumes destroy license_data -y -a license-server-demo 2>/dev/null || echo -e "${YELLOW}Volume already removed or doesn't exist${NC}"
echo -e "${GREEN}✓ Volume removed${NC}"
echo ""

sleep 2

echo -e "${BLUE}3️⃣  Creating new volume...${NC}"
flyctl volumes create license_data --size 1 --region fra -a license-server-demo
echo -e "${GREEN}✓ New volume created${NC}"
echo ""

sleep 2

echo -e "${BLUE}4️⃣  Scaling back up to 1 machine...${NC}"
flyctl scale count 1 -a license-server-demo
echo -e "${GREEN}✓ Scaled up${NC}"
echo ""

echo -e "${BLUE}5️⃣  Waiting for app to start (20 seconds)...${NC}"
sleep 20
echo ""

echo -e "${BLUE}6️⃣  Verifying new products...${NC}"
echo ""

if curl -s -f https://license-server-demo.fly.dev/licenses/status > /dev/null 2>&1; then
    echo -e "${GREEN}✓ App is responding${NC}"
    echo ""
    echo -e "${BLUE}📊 New Products:${NC}"
    curl -s https://license-server-demo.fly.dev/licenses/status | \
        python3 -c "import sys, json; data = json.load(sys.stdin); [print(f\"  • {d['tool']}: {d['total']} total ({d['commit']} commit, {d['max_overage']} overage) - Commit: \${d['commit_price']:.0f}\") for d in data]" 2>/dev/null || \
        curl -s https://license-server-demo.fly.dev/licenses/status | jq -r '.[] | "  • \(.tool): \(.total) total (\(.commit) commit, \(.max_overage) overage)"'
    echo ""
else
    echo -e "${RED}✗ App not responding yet${NC}"
    echo -e "${YELLOW}Give it another minute, then check: flyctl logs -a license-server-demo${NC}"
    echo ""
fi

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}✓ Database Reset Complete!${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}🌐 URLs:${NC}"
echo "  • Dashboard:    https://license-server-demo.fly.dev/dashboard"
echo "  • API Status:   https://license-server-demo.fly.dev/licenses/status"
echo "  • Grafana:      https://mholetzko.grafana.net"
echo ""

echo -e "${GREEN}📊 Monitor:${NC}"
echo "  • Logs:         flyctl logs -a license-server-demo"
echo "  • Status:       flyctl status -a license-server-demo"
echo ""


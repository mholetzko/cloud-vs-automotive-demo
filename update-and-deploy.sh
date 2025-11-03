#!/usr/bin/env bash
set -e

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Deploy Updates & Reset Database                        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if there are changes to commit
if [[ -z $(git status -s) ]]; then
    echo -e "${YELLOW}⚠ No changes to commit${NC}"
    echo ""
else
    echo -e "${BLUE}1️⃣  Committing changes...${NC}"
    git add .
    git status --short
    echo ""
    read -p "Commit message (or press Enter for default): " COMMIT_MSG
    COMMIT_MSG=${COMMIT_MSG:-"Update products and configuration"}
    git commit -m "$COMMIT_MSG"
    echo -e "${GREEN}✓ Changes committed${NC}"
    echo ""
fi

echo -e "${BLUE}2️⃣  Pushing to GitHub...${NC}"
git push origin main
echo -e "${GREEN}✓ Pushed to GitHub${NC}"
echo ""

echo -e "${BLUE}3️⃣  GitHub Actions will deploy automatically${NC}"
echo -e "${YELLOW}   → Watch: https://github.com/mholetzko/cloud-vs-automotive-demo/actions${NC}"
echo ""

read -p "Wait for deployment to complete, then press Enter to continue..."
echo ""

echo -e "${BLUE}4️⃣  Resetting database with new products...${NC}"
echo ""

echo -e "${YELLOW}⚠ This will delete all existing license data${NC}"
read -p "Continue? (yes/no): " -r
echo

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${RED}Aborted - code deployed but database not reset${NC}"
    exit 1
fi

echo -e "${BLUE}Removing old database...${NC}"
flyctl ssh console -C "rm -f /data/licenses.db" || true
echo -e "${GREEN}✓ Database removed${NC}"
echo ""

echo -e "${BLUE}Restarting app...${NC}"
flyctl apps restart license-server-demo
echo -e "${GREEN}✓ App restarting${NC}"
echo ""

echo -e "${BLUE}Waiting for app to initialize (15 seconds)...${NC}"
sleep 15
echo ""

echo -e "${BLUE}5️⃣  Verifying deployment...${NC}"
echo ""

# Check if app is responding
if curl -s -f https://license-server-demo.fly.dev/licenses/status > /dev/null 2>&1; then
    echo -e "${GREEN}✓ App is responding${NC}"
    echo ""
    
    # Show the new products
    echo -e "${BLUE}📊 New Products:${NC}"
    curl -s https://license-server-demo.fly.dev/licenses/status | \
        python3 -c "import sys, json; data = json.load(sys.stdin); [print(f\"  • {d['tool']}: {d['total']} total ({d['commit']} commit, {d['max_overage']} overage)\") for d in data]" 2>/dev/null || \
        curl -s https://license-server-demo.fly.dev/licenses/status | jq -r '.[] | "  • \(.tool): \(.total) total (\(.commit) commit, \(.max_overage) overage)"'
    echo ""
else
    echo -e "${RED}✗ App not responding yet${NC}"
    echo -e "${YELLOW}Check logs: flyctl logs${NC}"
    echo ""
fi

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}✓ Deployment Complete!${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}🌐 Live at:${NC}"
echo "  • Dashboard:     https://license-server-demo.fly.dev/dashboard"
echo "  • Status API:    https://license-server-demo.fly.dev/licenses/status"
echo "  • Metrics:       https://license-server-demo.fly.dev/metrics"
echo "  • Presentation:  https://license-server-demo.fly.dev/presentation"
echo ""

echo -e "${GREEN}📊 Monitoring:${NC}"
echo "  • Logs:          flyctl logs -f"
echo "  • Status:        flyctl status"
echo "  • SSH:           flyctl ssh console"
echo ""

echo -e "${GREEN}🧪 Test with clients:${NC}"
echo "  • Python:        cd clients/python && ./run_example.sh"
echo "  • Stress test:   cd stress-test && ./run_stress_test.sh"
echo ""


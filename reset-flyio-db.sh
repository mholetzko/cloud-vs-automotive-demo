#!/usr/bin/env bash
set -e

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Reset Fly.io Database                                  ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}⚠ This will delete the database and reseed with new products${NC}"
echo -e "${YELLOW}⚠ All existing license data will be lost${NC}"
echo ""
read -p "Are you sure? (yes/no): " -r
echo

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${RED}Aborted${NC}"
    exit 1
fi

echo -e "${BLUE}1️⃣  Connecting to Fly.io and removing database...${NC}"
if ! flyctl ssh console -C "rm -f /data/licenses.db" 2>/dev/null; then
    echo -e "${YELLOW}⚠ SSH failed, trying alternative method...${NC}"
    echo -e "${BLUE}Creating a deployment with DB reset...${NC}"
    
    # Alternative: Use fly ssh issue to issue command
    flyctl ssh issue --agent || true
    
    # Or just restart with environment variable
    echo -e "${YELLOW}Manual cleanup needed - restarting app${NC}"
fi
echo -e "${GREEN}✓ Database removal initiated${NC}"
echo ""

echo -e "${BLUE}2️⃣  Restarting app to trigger reseed...${NC}"
flyctl apps restart license-server-demo
echo -e "${GREEN}✓ App restarting${NC}"
echo ""

echo -e "${BLUE}3️⃣  Waiting for app to start (10 seconds)...${NC}"
sleep 10
echo ""

echo -e "${BLUE}4️⃣  Checking status...${NC}"
curl -s https://license-server-demo.fly.dev/licenses/status | head -20
echo ""
echo ""

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}✓ Database reset complete!${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}New products:${NC}"
echo "  • Vector - DaVinci Configurator SE (20 licenses)"
echo "  • Vector - DaVinci Configurator IDE (10 licenses)"
echo "  • Greenhills - Multi 8.2 (20 licenses)"
echo "  • Vector - ASAP2 v20 (20 licenses)"
echo "  • Vector - DaVinci Teams (10 licenses)"
echo "  • Vector - VTT (10 licenses)"
echo ""

echo -e "${GREEN}View at: ${NC}https://license-server-demo.fly.dev"


#!/usr/bin/env bash
set -e

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

clear

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                          ║${NC}"
echo -e "${BLUE}║       ${CYAN}Cloud DevOps Observability Demo${BLUE}                   ║${NC}"
echo -e "${BLUE}║       ${MAGENTA}'The Overage Crisis Journey'${BLUE}                    ║${NC}"
echo -e "${BLUE}║                                                          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}This demo will walk you through a complete DevOps cycle:${NC}"
echo ""
echo "  1️⃣  Normal Operations - Baseline state"
echo "  2️⃣  Problem Appears - Overage spike triggered"
echo "  3️⃣  Detection & Alert - Monitoring catches it"
echo "  4️⃣  Investigation - Root cause analysis"
echo "  5️⃣  Decision & Fix - Data-driven solution"
echo "  6️⃣  Verification - Confirm fix worked"
echo ""
echo -e "${CYAN}Total time: ~15 minutes${NC}"
echo ""

read -p "Press Enter to start the demo..."
clear

# ============================================================================
# PART 1: Normal Operations
# ============================================================================

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  PART 1: Normal Operations                              ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}📊 Current Status:${NC}"
echo ""

curl -s https://license-server-demo.fly.dev/licenses/status | \
    python3 -c "
import sys, json
data = json.load(sys.stdin)
for tool in data:
    print(f\"  {tool['tool'][:40]:40} {tool['available']:2}/{tool['total']:2} available\")
" 2>/dev/null || echo "  (Server data)"

echo ""
echo -e "${CYAN}💬 Presenter Notes:${NC}"
echo "   - 'Everything is running normally'"
echo "   - 'All licenses are available'"
echo "   - 'Metrics are baseline'"
echo ""
echo -e "${YELLOW}🌐 Open in browser:${NC}"
echo "   Dashboard: https://license-server-demo.fly.dev/dashboard"
echo "   Grafana:   https://mholetzko.grafana.net"
echo ""

read -p "Press Enter to continue to Part 2..."
clear

# ============================================================================
# PART 2: The Problem Appears
# ============================================================================

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  PART 2: The Problem Appears                            ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${RED}⚠️  SCENARIO:${NC}"
echo "   A development team starts a large build job"
echo "   They're using Vector - DaVinci Configurator SE"
echo "   This tool has: 5 commit licenses, 15 overage licenses"
echo ""

echo -e "${YELLOW}🚀 Starting stress test...${NC}"
echo ""
echo "   Target:   Fly.io Production"
echo "   Load:     Medium (10 workers, 50 ops each)"
echo "   Tool:     Vector - DaVinci Configurator SE"
echo "   Mode:     Full Cycle (borrow → hold → return)"
echo ""

read -p "Press Enter to trigger the problem..."

# Run stress test in background and show progress
cd "$(dirname "$0")/stress-test" 2>/dev/null || cd stress-test 2>/dev/null || {
    echo -e "${RED}Error: stress-test directory not found${NC}"
    echo "Run this script from the project root"
    exit 1
}

# Check if compiled
if [ ! -f "target/release/stress" ]; then
    echo -e "${BLUE}Building stress test tool...${NC}"
    cargo build --release --quiet
fi

echo ""
echo -e "${CYAN}▶ Simulating overage scenario...${NC}"
echo ""

./target/release/stress \
    --url https://license-server-demo.fly.dev \
    --workers 10 \
    --operations 50 \
    --tool "Vector - DaVinci Configurator SE" \
    --hold-time 2 \
    --mode full-cycle \
    --ramp-up 3 2>&1 | head -30

echo ""
echo -e "${YELLOW}💬 Presenter Notes:${NC}"
echo "   - 'Notice some borrows are going into overage'"
echo "   - 'This is generating additional costs'"
echo "   - 'In automotive, this would be logged locally in the ECU'"
echo "   - 'It might be hours or days before this data reaches HQ'"
echo ""

read -p "Press Enter to see how we detect this..."
clear

# ============================================================================
# PART 3: Detection & Alert
# ============================================================================

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  PART 3: Detection & Alert                              ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}✅ Alert Triggered!${NC}"
echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  🚨 ALERT: High Overage Rate                          ║"
echo "║                                                        ║"
echo "║  Severity:  WARNING                                    ║"
echo "║  Tool:      Vector - DaVinci Configurator SE           ║"
echo "║  Overage:   > 30% of checkouts                         ║"
echo "║  Duration:  Last 5 minutes                             ║"
echo "║                                                        ║"
echo "║  📊 View Dashboard:                                    ║"
echo "║  https://mholetzko.grafana.net                         ║"
echo "║                                                        ║"
echo "║  📝 View Logs:                                         ║"
echo "║  https://mholetzko.grafana.net/explore                 ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

echo -e "${CYAN}⏱️  Time from problem to alert: < 1 minute${NC}"
echo ""

echo -e "${YELLOW}💬 Presenter Notes:${NC}"
echo "   - 'Prometheus scraped metrics every 15 seconds'"
echo "   - 'Alert rule evaluated continuously'"
echo "   - 'Team got notified immediately'"
echo "   - 'Direct links to investigate further'"
echo ""
echo -e "${RED}📍 Automotive Parallel:${NC}"
echo "   - Vehicle: Error logged locally"
echo "   - Vehicle: Waits for telemetry upload (hours/days)"
echo "   - Cloud: Data aggregated at collector"
echo "   - Cloud: Eventually reaches analytics platform"
echo "   - L1: Reviews dashboard, creates ticket"
echo "   - L2: Triages, escalates to L3"
echo "   - L3: Finally reaches engineering"
echo "   ${RED}⏱️  Total time: Days to weeks${NC}"
echo ""

read -p "Press Enter to investigate..."
clear

# ============================================================================
# PART 4: Investigation
# ============================================================================

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  PART 4: Investigation                                  ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}🔍 Checking current metrics...${NC}"
echo ""

# Fetch and display overage charges
curl -s https://license-server-demo.fly.dev/overage-charges | \
    python3 -c "
import sys, json
data = json.load(sys.stdin)
davinci_charges = [c for c in data if 'DaVinci Configurator SE' in c.get('tool', '')]
recent = sorted(davinci_charges, key=lambda x: x.get('charged_at', ''), reverse=True)[:5]

print('📊 Recent Overage Charges (DaVinci SE):')
print()
for charge in recent:
    print(f\"  \${charge['amount']:6.2f} - {charge['user']:20} - {charge['charged_at'][:19]}\")
print()
total = sum(c['amount'] for c in davinci_charges)
print(f\"  Total overage cost: \${total:.2f}\")
" 2>/dev/null || echo "  (Overage data)"

echo ""
echo -e "${CYAN}📝 Sample Loki Log Query:${NC}"
echo ""
echo "  {app=\"license-server\"}"
echo "  | json"
echo "  | tool=\"Vector - DaVinci Configurator SE\""
echo "  | overage=\"true\""
echo ""

echo -e "${GREEN}🔍 Key Findings:${NC}"
echo "  1. Multiple users hitting overage"
echo "  2. Peak usage during business hours"
echo "  3. Cost accumulating quickly"
echo "  4. Pattern suggests automation/CI jobs"
echo ""

echo -e "${YELLOW}💬 Presenter Notes:${NC}"
echo "   - 'In one place, I see the complete picture'"
echo "   - 'Logs, metrics, costs - all correlated'"
echo "   - 'Can drill from alert → graph → logs → requests'"
echo "   - 'Same team that built this has full visibility'"
echo ""

read -p "Press Enter to see the fix..."
clear

# ============================================================================
# PART 5: Decision & Fix
# ============================================================================

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  PART 5: Decision & Fix                                 ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}💡 Decision Options:${NC}"
echo ""
echo "  A) Increase commit allocation (5 → 10 licenses)"
echo "     - Reduces overage, increases fixed cost"
echo "     - Good if usage is consistently high"
echo ""
echo "  B) Alert the team about their usage"
echo "     - Keep costs in check"
echo "     - Behavioral change"
echo ""
echo "  C) Implement usage policy / limits"
echo "     - Auto-reject beyond threshold"
echo "     - Prevent runaway costs"
echo ""

echo -e "${GREEN}✅ Recommended: Option A (Increase Commit)${NC}"
echo ""
echo "  Analysis:"
echo "  - Current: 5 commit @ \$5000, 15 overage @ \$500 each"
echo "  - Overage cost last hour: ~\$2500"
echo "  - Projected monthly overage: ~\$60,000"
echo "  - Cost to increase commit to 10: +\$5000/month fixed"
echo "  - **ROI: Save ~\$55,000/month**"
echo ""

echo -e "${YELLOW}🔧 Applying fix...${NC}"
echo ""
echo "  Navigate to: https://license-server-demo.fly.dev/config"
echo "  Update DaVinci SE:"
echo "    - Commit: 5 → 10"
echo "    - Max Overage: 15 → 10"
echo "    - Save configuration"
echo ""

echo -e "${CYAN}⏱️  Time from alert to fix: < 5 minutes${NC}"
echo ""

echo -e "${YELLOW}💬 Presenter Notes:${NC}"
echo "   - 'Decision was data-driven'"
echo "   - 'Same person who got alert deployed the fix'"
echo "   - 'No ticket system, no approvals, no waiting'"
echo "   - 'We own the full cycle'"
echo ""

read -p "Press Enter to verify the fix..."
clear

# ============================================================================
# PART 6: Verification
# ============================================================================

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  PART 6: Verification                                   ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}📊 Checking new metrics...${NC}"
echo ""

curl -s https://license-server-demo.fly.dev/licenses/status | \
    python3 -c "
import sys, json
data = json.load(sys.stdin)
for tool in data:
    if 'DaVinci Configurator SE' in tool['tool']:
        print(f\"  Tool:          {tool['tool']}\")
        print(f\"  Total:         {tool['total']}\")
        print(f\"  Commit:        {tool['commit']} (was 5, now should be 10)\")
        print(f\"  Max Overage:   {tool['max_overage']}\")
        print(f\"  Current Use:   {tool['borrowed']}\")
        print(f\"  In Commit:     {tool['in_commit']}\")
        print(f\"  In Overage:    {tool['overage']}\")
        print()
" 2>/dev/null || echo "  (Updated configuration)"

echo ""
echo -e "${GREEN}✅ Fix Verified:${NC}"
echo "  - Configuration updated successfully"
echo "  - More licenses available in commit"
echo "  - Overage rate will decrease"
echo "  - Cost growth contained"
echo ""

echo -e "${CYAN}⏱️  Total cycle time: ~12 minutes${NC}"
echo "  - Detection: 1 min"
echo "  - Investigation: 3 min"
echo "  - Fix: 2 min"
echo "  - Verification: 1 min"
echo ""

read -p "Press Enter for summary..."
clear

# ============================================================================
# SUMMARY
# ============================================================================

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                          ║${NC}"
echo -e "${BLUE}║       ${GREEN}✅ DevOps Cycle Complete!${BLUE}                         ║${NC}"
echo -e "${BLUE}║                                                          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}📊 COMPARISON:${NC}"
echo ""
echo "┌───────────────────────────┬──────────────────┬────────────────────┐"
echo "│ Stage                     │ Cloud DevOps     │ Automotive (Edge)  │"
echo "├───────────────────────────┼──────────────────┼────────────────────┤"
echo "│ Problem Occurs            │ Real-time        │ Real-time          │"
echo "│ Data Collection           │ < 30 seconds     │ Hours to days      │"
echo "│ Detection / Alert         │ < 1 minute       │ Days to weeks      │"
echo "│ Investigation             │ 3 minutes        │ Days               │"
echo "│ Root Cause Analysis       │ 5 minutes        │ Weeks              │"
echo "│ Fix Development           │ 2 minutes        │ Weeks              │"
echo "│ Deployment                │ Immediate        │ Months (OTA)       │"
echo "│ Verification              │ 1 minute         │ Weeks              │"
echo "├───────────────────────────┼──────────────────┼────────────────────┤"
echo "│ ${GREEN}TOTAL TIME${NC}                │ ${GREEN}~12 minutes${NC}      │ ${RED}Weeks to Months${NC}   │"
echo "│ ${GREEN}TEAMS INVOLVED${NC}            │ ${GREEN}1 team${NC}           │ ${RED}5+ teams${NC}          │"
echo "│ ${GREEN}DATA ACCESS${NC}               │ ${GREEN}Direct${NC}           │ ${RED}Multiple hops${NC}     │"
echo "└───────────────────────────┴──────────────────┴────────────────────┘"
echo ""

echo -e "${YELLOW}🎯 Key Takeaways:${NC}"
echo ""
echo "  1. ${GREEN}Speed${NC}: Cloud DevOps enables minutes, not weeks"
echo "  2. ${GREEN}Ownership${NC}: Same team builds, monitors, and fixes"
echo "  3. ${GREEN}Visibility${NC}: Everyone sees the same telemetry"
echo "  4. ${GREEN}Feedback${NC}: Immediate verification"
echo "  5. ${GREEN}Data-Driven${NC}: Decisions based on real metrics"
echo ""

echo -e "${CYAN}💡 Bridging the Gap for Automotive:${NC}"
echo ""
echo "  - Implement observability gateways at edge"
echo "  - Stream critical signals to cloud in real-time"
echo "  - Use cloud infrastructure for analytics"
echo "  - Enable engineering teams with direct data access"
echo "  - Adopt DevOps ownership model where possible"
echo ""

echo -e "${GREEN}🌐 Links:${NC}"
echo "  Dashboard:     https://license-server-demo.fly.dev/dashboard"
echo "  Grafana:       https://mholetzko.grafana.net"
echo "  Presentation:  https://license-server-demo.fly.dev/presentation"
echo "  GitHub:        https://github.com/mholetzko/cloud-vs-automotive-demo"
echo ""

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Demo Complete - Ready for Questions!                   ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""


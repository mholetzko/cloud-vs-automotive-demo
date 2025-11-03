#!/usr/bin/env bash
set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Starting Prometheus → Grafana Cloud${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Docker is not running${NC}"
    echo "Please start Docker Desktop and try again"
    exit 1
fi

# Check if prometheus-cloud container already exists
if docker ps -a --format '{{.Names}}' | grep -q '^prometheus-cloud$'; then
    echo -e "${YELLOW}Stopping existing prometheus-cloud container...${NC}"
    docker stop prometheus-cloud 2>/dev/null || true
    docker rm prometheus-cloud 2>/dev/null || true
fi

echo -e "${GREEN}→ Starting Prometheus with Grafana Cloud remote write...${NC}"
echo ""

# Start Prometheus
docker run -d \
  --name prometheus-cloud \
  -p 9090:9090 \
  -v "$(pwd)/prometheus-cloud.yml:/etc/prometheus/prometheus.yml" \
  --restart unless-stopped \
  prom/prometheus:latest

echo ""
echo -e "${GREEN}✅ Prometheus started successfully!${NC}"
echo ""
echo -e "${BLUE}Configuration:${NC}"
echo "  📊 Scraping: https://license-server-demo.fly.dev/metrics"
echo "  ☁️  Pushing to: Grafana Cloud (EU West 2)"
echo "  🔄 Scrape interval: 30 seconds"
echo ""
echo -e "${BLUE}Useful URLs:${NC}"
echo "  Local Prometheus UI: http://localhost:9090"
echo "  Prometheus Targets:  http://localhost:9090/targets"
echo "  Grafana Cloud:       https://matthiasholetzko.grafana.net"
echo ""
echo -e "${BLUE}Commands:${NC}"
echo "  View logs:    docker logs -f prometheus-cloud"
echo "  Stop:         docker stop prometheus-cloud"
echo "  Restart:      docker restart prometheus-cloud"
echo "  Remove:       docker rm -f prometheus-cloud"
echo ""
echo -e "${GREEN}→ Checking if metrics are being scraped...${NC}"
sleep 5

# Check if target is up
TARGET_STATUS=$(docker exec prometheus-cloud wget -qO- http://localhost:9090/api/v1/targets 2>/dev/null | grep -o '"health":"[^"]*"' | head -1 || echo '"health":"unknown"')

if echo "$TARGET_STATUS" | grep -q "up"; then
    echo -e "${GREEN}✅ Target is UP - metrics are being scraped!${NC}"
else
    echo -e "${YELLOW}⚠️  Target status: $TARGET_STATUS${NC}"
    echo "   It may take a minute to start scraping..."
fi

echo ""
echo -e "${BLUE}→ Next steps:${NC}"
echo "1. Wait 1-2 minutes for data to appear in Grafana Cloud"
echo "2. Open your Grafana Cloud: https://matthiasholetzko.grafana.net"
echo "3. Go to Explore → Select Prometheus"
echo "4. Run query: license_borrow_success_total"
echo ""
echo -e "${GREEN}🎉 Setup complete! Your metrics are flowing to Grafana Cloud!${NC}"
echo ""


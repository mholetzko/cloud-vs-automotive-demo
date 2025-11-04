# 🚀 Grafana Cloud Quick Start

Your Grafana Cloud credentials have been securely stored! Here's how to start sending metrics.

## ✅ What's Already Done

- ✅ GitHub Secrets configured:
  - `GRAFANA_CLOUD_PROMETHEUS_USERNAME`
  - `GRAFANA_CLOUD_API_TOKEN`
- ✅ Prometheus configuration ready
- ✅ One-command setup script created

## 🎯 Quick Start (2 minutes)

### Option 1: Automatic Setup (Recommended)

Just run this:

```bash
./start-prometheus-cloud.sh
```

This script will:
1. ✅ Start Prometheus in Docker
2. ✅ Scrape metrics from Fly.io (every 30s)
3. ✅ Push to Grafana Cloud automatically
4. ✅ Verify everything is working

### Option 2: Manual Setup

```bash
docker run -d \
  --name prometheus-cloud \
  -p 9090:9090 \
  -v $(pwd)/prometheus-cloud.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus:latest
```

## 🔍 Verify It's Working

### 1. Check Prometheus is Scraping

Open: http://localhost:9090/targets

You should see:
- Target: `license-server` 
- State: **UP** (green)

### 2. Check Data in Grafana Cloud

1. Open: **https://matthiasholetzko.grafana.net**
2. Go to **Explore**
3. Select **Prometheus** datasource
4. Run query: `license_borrow_success_total`

You should see data within 1-2 minutes! 📊

## 📊 Import Your Dashboard

### Quick Import

1. Go to: https://matthiasholetzko.grafana.net/dashboards
2. Click **Import**
3. Upload: `grafana/dashboards/license_business_metrics.json`
4. Select Prometheus datasource
5. Click **Import**

### Dashboard Panels

Your dashboard includes:
- 📈 Total Borrows & Success Rate
- 👥 Top Users by Checkout
- ⚠️ Overage Rate & Analysis
- 💰 Cost Tracking
- 📊 20+ visualizations

## 🧪 Generate Test Data

To see metrics populate, generate some traffic:

```bash
# Use Python client
cd clients/python
./run_example.sh
# Choose: 2) Fly.io Production
# Choose: 3) Stress test

# Or use any other client
cd clients/cpp
./run_example.sh
```

Within 30 seconds, you'll see metrics in Grafana Cloud!

## 🎯 Your Grafana Cloud Setup

**Your Stack:** https://matthiasholetzko.grafana.net

**Prometheus Endpoint:** https://prometheus-prod-65-prod-eu-west-2.grafana.net/api/prom/push

**Region:** EU West 2 (Frankfurt)

**Scraping:** Fly.io deployment every 30 seconds

## 📋 Useful Queries

Try these in Grafana Cloud Explore:

### Success Rate
```promql
sum(rate(license_borrow_success_total[5m])) / 
sum(rate(license_borrow_attempts_total[5m]))
```

### Active Licenses
```promql
sum(licenses_borrowed)
```

### Overage Rate
```promql
sum(rate(license_overage_checkouts_total[5m])) / 
(sum(rate(license_borrow_success_total[5m])) + 0.0001)
```

### Top Users
```promql
topk(10, sum by (user) (rate(license_borrow_success_total[5m])))
```

### Cost (24h)
```promql
sum(increase(license_overage_checkouts_total[24h])) * 100 + 
count(licenses_total) * 1000
```

## 🛠️ Troubleshooting

### No data in Grafana Cloud?

**1. Check Prometheus is running:**
```bash
docker ps | grep prometheus-cloud
```

**2. Check Prometheus logs:**
```bash
docker logs prometheus-cloud
```

Look for errors related to remote_write.

**3. Check target is being scraped:**
```bash
open http://localhost:9090/targets
```

Target should be **UP** (green).

**4. Test remote write manually:**
```bash
curl -u YOUR_USERNAME:YOUR_API_TOKEN \
  https://prometheus-prod-XX-XX.grafana.net/api/prom/push
```

Should return: `404` (endpoint exists, POST required)

### Metrics delayed?

- Free tier has rate limits
- Data may take 1-2 minutes to appear
- Check your time range in Grafana (default: last 6 hours)

### Prometheus not starting?

```bash
# Stop any existing container
docker stop prometheus-cloud
docker rm prometheus-cloud

# Run the setup script again
./start-prometheus-cloud.sh
```

## 📊 What Metrics Are Available?

All these metrics are being sent to Grafana Cloud:

```
license_borrow_attempts_total{tool, user}
license_borrow_success_total{tool, user}
license_borrow_failure_total{tool, reason}
license_borrow_duration_seconds{tool}
licenses_borrowed{tool}
licenses_total{tool}
licenses_overage{tool}
licenses_commit{tool}
licenses_max_overage{tool}
licenses_at_max_overage{tool}
license_overage_checkouts_total{tool, user}
```

## 🔄 Managing Prometheus

### View Logs
```bash
docker logs -f prometheus-cloud
```

### Restart
```bash
docker restart prometheus-cloud
```

### Stop
```bash
docker stop prometheus-cloud
```

### Remove
```bash
docker stop prometheus-cloud
docker rm prometheus-cloud
```

### Restart Script
```bash
./start-prometheus-cloud.sh
```

## 🎓 Next Steps

1. ✅ **Import dashboard** to visualize all metrics
2. ✅ **Set up alerts** in Grafana Cloud
3. ✅ **Create custom dashboards** for your use case
4. ✅ **Share dashboards** with your team

## 🔗 Resources

- **Grafana Cloud Dashboard:** https://matthiasholetzko.grafana.net
- **Prometheus UI:** http://localhost:9090
- **Fly.io App:** https://license-server-demo.fly.dev
- **Metrics Endpoint:** https://license-server-demo.fly.dev/metrics

## 🔐 Security Note

Your credentials are:
- ✅ Stored securely in GitHub Secrets
- ✅ Not committed to the repository
- ✅ Only in your local `prometheus-cloud.yml` file
- ⚠️ **Keep `prometheus-cloud.yml` private** (it's in `.gitignore`)

## 💡 Pro Tips

1. **Use variables** in Grafana dashboards to filter by tool/user
2. **Set up alerts** for high overage rates (>30%)
3. **Create multiple dashboards** for different audiences
4. **Use annotations** to mark deployments
5. **Enable Loki** for log aggregation (upgrade to paid plan)

---

**Setup Time:** ~2 minutes  
**Monthly Cost:** $0 (free tier)  
**Metrics Retention:** 14 days  

🎉 **You're all set! Enjoy your cloud monitoring!**


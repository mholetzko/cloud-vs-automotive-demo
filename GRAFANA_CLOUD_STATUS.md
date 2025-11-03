# ✅ Grafana Cloud - ACTIVE

## Status: 🟢 Connected and Sending Data

Your metrics are now flowing from **Fly.io → Prometheus (local) → Grafana Cloud**!

---

## 📊 Current Setup

```
Fly.io App (license-server-demo.fly.dev)
    ↓ scrape every 30s
Prometheus (localhost:9090)
    ↓ remote_write
Grafana Cloud (EU West 2)
```

### What's Happening:

1. **Prometheus scrapes** `https://license-server-demo.fly.dev/metrics` every 30 seconds
2. **Metrics are pushed** to Grafana Cloud via remote_write
3. **Data appears** in your Grafana Cloud dashboard

---

## 🌐 Access Your Dashboards

**Grafana Cloud:** https://matthiasholetzko.grafana.net

**Local Prometheus:** http://localhost:9090

---

## ✅ Verify It's Working

### 1. Check Prometheus Target

```bash
open http://localhost:9090/targets
```

You should see:
- **Target:** `license-server-flyio`
- **State:** UP (green)
- **Endpoint:** `https://license-server-demo.fly.dev/metrics`

### 2. Check Data in Grafana Cloud

1. Go to: https://matthiasholetzko.grafana.net/explore
2. Select **Prometheus** datasource
3. Run query: `license_borrow_success_total`
4. You should see data! 📈

---

## 📊 Import Your Dashboard

### Quick Steps:

1. Download: `grafana/dashboards/license_business_metrics.json`
2. Go to: https://matthiasholetzko.grafana.net/dashboards
3. Click **"Import"** → **"Upload JSON file"**
4. Select the downloaded JSON
5. Choose **Prometheus** as the datasource
6. Click **"Import"**

### Your Dashboard Includes:

- 📈 License Checkout Overview (6 panels)
- 👥 Client Sources & Users (3 panels)  
- ⚠️ Overage Analysis (5 panels)
- 💰 Cost Tracking (6 panels)

**Total: 20+ visualizations!**

---

## 🧪 Generate Test Data

To see metrics populate, run some traffic:

```bash
# Quick test
cd clients/python
./run_example.sh
# Choose: 2) Fly.io Production

# Stress test (generates lots of data)
cd clients/python  
./run_example.sh
# Choose: 2) Fly.io Production
# Choose: 3) Stress test
```

Within 30 seconds, you'll see the data in Grafana Cloud!

---

## 📋 Available Metrics

All these are being sent to Grafana Cloud:

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

---

## 🎯 Useful Queries

Try these in Grafana Cloud:

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

### Daily Cost
```promql
sum(increase(license_overage_checkouts_total[24h])) * 100 + 
count(licenses_total) * 1000
```

---

## 🔧 Configuration Files

### Prometheus Config
**File:** `prometheus.yml`

```yaml
global:
  scrape_interval: 30s
  external_labels:
    cluster: 'fly-io'
    environment: 'production'

scrape_configs:
  - job_name: "license-server-flyio"
    scheme: https
    static_configs:
      - targets: ["license-server-demo.fly.dev"]
    metrics_path: /metrics

remote_write:
  - url: https://prometheus-prod-65-prod-eu-west-2.grafana.net/api/prom/push
    basic_auth:
      username: 2776113
      password: [REDACTED]
```

### Docker Compose
Prometheus is running via docker-compose. To restart:

```bash
docker-compose restart prometheus
```

---

## 🛠️ Troubleshooting

### No data in Grafana Cloud?

**1. Check Prometheus is running:**
```bash
docker-compose ps | grep prometheus
```

**2. Check Prometheus logs:**
```bash
docker-compose logs prometheus | tail -50
```

Look for `remote_write` errors.

**3. Check target status:**
```bash
open http://localhost:9090/targets
```

Target should be **UP** (green).

**4. Check Fly.io metrics endpoint:**
```bash
curl https://license-server-demo.fly.dev/metrics | head -20
```

Should return Prometheus metrics.

### Metrics delayed?

- Data appears within 30-60 seconds
- Check time range in Grafana (default: last 6 hours)
- Free tier may have rate limits

### Prometheus stopped?

```bash
# Restart everything
docker-compose restart

# Or just Prometheus
docker-compose restart prometheus
```

---

## 💡 Important Notes

1. **Prometheus must be running** on your laptop for data to flow
2. **When you stop docker-compose**, metrics stop flowing
3. **Historical data** in Grafana Cloud is preserved (14 days free tier)
4. **Credentials** are in `prometheus.yml` (keep this file private)

---

## 🔄 Managing the Setup

### Start Everything
```bash
docker-compose up -d
```

### Stop Everything
```bash
docker-compose down
```

### View Prometheus Logs
```bash
docker-compose logs -f prometheus
```

### Check Status
```bash
docker-compose ps
open http://localhost:9090
```

---

## 📈 What's Next?

1. ✅ **Import dashboard** to Grafana Cloud
2. ✅ **Generate traffic** to see metrics populate
3. ✅ **Set up alerts** in Grafana Cloud for high overage rates
4. ✅ **Share dashboards** with your team
5. ✅ **Create custom views** for different audiences

---

## 🎓 Resources

- **Grafana Cloud:** https://matthiasholetzko.grafana.net
- **Prometheus Docs:** https://prometheus.io/docs/
- **PromQL Guide:** https://prometheus.io/docs/prometheus/latest/querying/basics/
- **Your Dashboard JSON:** `grafana/dashboards/license_business_metrics.json`

---

**Status:** ✅ **ACTIVE**  
**Last Updated:** 2025-11-03  
**Data Flowing:** Yes 🟢  
**Retention:** 14 days (free tier)

🎉 **Your metrics are now in the cloud!**


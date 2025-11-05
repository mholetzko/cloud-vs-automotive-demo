# Troubleshooting: Traces Not Found

If you're getting "Trace Not Found" errors, here's how to diagnose and fix it.

## 🔍 Your Situation

**Error:** `failed to get trace with id: a8611dfc2f7d408fe9519c845f66e19a Status: Not Found`

**New Trace ID:** `1a55e1ddbbd7da8cc732b16d72b68a5f`

This means traces are being generated (you see trace IDs in headers), but they're not reaching Tempo.

---

## ✅ Step 1: Verify Traces Are Being Sent

### Check App Logs

**Local:**
```bash
docker-compose logs api | grep -i "trace\|otel\|tempo"
```

**Fly.io:**
```bash
flyctl logs | grep -i "trace\|otel\|tempo"
```

**What to look for:**
- ✅ No errors = Good
- ❌ Connection errors = Bad (traces not reaching Tempo)
- ❌ Authentication errors = Bad (wrong credentials)

---

## ✅ Step 2: Check OpenTelemetry Configuration

### Verify Environment Variables

**Local (docker-compose):**
The app should default to `http://tempo:4318/v1/traces` automatically.

**Fly.io (Grafana Cloud):**
Check if these are set:
```bash
flyctl secrets list | grep OTEL
```

You should see:
```
OTEL_EXPORTER_OTLP_ENDPOINT
OTEL_EXPORTER_OTLP_HEADERS
```

**If missing, set them:**
```bash
# Get Tempo endpoint from Grafana Cloud
# Go to: Grafana Cloud → Tempo → Details

flyctl secrets set OTEL_EXPORTER_OTLP_ENDPOINT="https://tempo-us-central1-XX.grafana.net:443"
flyctl secrets set OTEL_EXPORTER_OTLP_HEADERS="Authorization: Basic $(echo -n 'username:token' | base64)"
```

---

## ✅ Step 3: Test Trace Sending

### Option 1: Check Tempo Directly

**Local:**
```bash
# Check if Tempo is receiving traces
curl http://localhost:3200/api/traces/1a55e1ddbbd7da8cc732b16d72b68a5f

# Check Tempo metrics
curl http://localhost:3200/metrics | grep tempo_distributor
```

**Fly.io (Grafana Cloud):**
```bash
# Use Grafana Cloud Tempo API
curl -H "Authorization: Basic ..." \
  "https://tempo-us-central1-XX.grafana.net/api/traces/1a55e1ddbbd7da8cc732b16d72b68a5f"
```

### Option 2: Check App Logs for Errors

**Look for these errors in app logs:**
```
ERROR opentelemetry.exporter.otlp.proto.http.trace_exporter - Failed to export traces
```

If you see connection errors, traces aren't reaching Tempo.

---

## 🔧 Common Issues & Fixes

### Issue 1: Traces Not Being Sent (Local)

**Symptoms:**
- Trace IDs in headers ✅
- But no traces in Tempo ❌

**Fix:**
1. Check Tempo is running:
   ```bash
   docker-compose ps tempo
   ```

2. Check Tempo logs:
   ```bash
   docker-compose logs tempo | tail -20
   ```

3. Verify app can reach Tempo:
   ```bash
   docker-compose exec api curl http://tempo:4318/health
   ```

4. Restart everything:
   ```bash
   docker-compose restart
   ```

---

### Issue 2: Traces Not Being Sent (Fly.io)

**Symptoms:**
- Trace IDs in headers ✅
- But "Trace Not Found" in Grafana Cloud ❌

**Fix:**

**1. Check if OTEL secrets are set:**
```bash
flyctl secrets list
```

**2. If missing, set them:**
```bash
# Get credentials from Grafana Cloud → Tempo → Details
flyctl secrets set OTEL_EXPORTER_OTLP_ENDPOINT="https://tempo-XX.grafana.net:443"
flyctl secrets set OTEL_EXPORTER_OTLP_HEADERS="Authorization: Basic base64encoded"
```

**3. Restart app:**
```bash
flyctl apps restart license-server-demo
```

**4. Check logs:**
```bash
flyctl logs | grep -i "otel\|trace"
```

**5. Test a new request:**
```bash
curl https://license-server-demo.fly.dev/faulty
# Check the x-trace-id header
# Then search for it in Grafana Cloud
```

---

### Issue 3: Wrong Tempo Endpoint

**Symptoms:**
- Connection errors in logs
- Traces never arrive

**Fix:**

**Local:**
- Should be: `http://tempo:4318/v1/traces`
- Check `docker-compose.yml` - Tempo should be on port 4318

**Fly.io:**
- Get correct endpoint from Grafana Cloud
- Format: `https://tempo-REGION-XX.grafana.net:443`
- Make sure it includes `/v1/traces` (handled by OpenTelemetry SDK)

---

### Issue 4: Authentication Issues

**Symptoms:**
- 401/403 errors in logs
- Traces not reaching Tempo

**Fix:**

**Check header format:**
```bash
# Should be Base64 encoded username:token
flyctl secrets set OTEL_EXPORTER_OTLP_HEADERS="Authorization: Basic $(echo -n 'username:token' | base64)"
```

**Or use Bearer token:**
```bash
flyctl secrets set OTEL_EXPORTER_OTLP_HEADERS="Authorization: Bearer your-token"
```

**Verify:**
```bash
# Check what's actually set
flyctl secrets list | grep OTEL
```

---

### Issue 5: Time Window Too Short

**Symptoms:**
- Trace exists but can't find it
- Different time range shows it

**Fix:**
1. In Grafana Explore, expand time range
2. Try "Last 1 hour" or "Last 6 hours"
3. Traces might be older than default time window

---

## 🧪 Quick Diagnostic Script

### Test Trace Sending

```bash
#!/bin/bash
# test-trace.sh

echo "Testing trace sending..."

# Make a request
TRACE_ID=$(curl -s -I https://license-server-demo.fly.dev/faulty | grep -i x-trace-id | cut -d' ' -f2 | tr -d '\r\n')

echo "Trace ID: $TRACE_ID"

# Wait a moment for trace to be sent
sleep 2

# Check if trace exists in Grafana Cloud
# (Replace with your Grafana Cloud Tempo endpoint)
curl -H "Authorization: Basic ..." \
  "https://tempo-XX.grafana.net/api/traces/$TRACE_ID"

echo ""
echo "If you see JSON, trace exists. If 404, trace not sent."
```

---

## 📊 Verify Trace Configuration

### Check App Code

Verify OpenTelemetry is initialized:
```python
# app/main.py should have:
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter

# And should be configured with:
OTLPSpanExporter(
    endpoint=os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://tempo:4318/v1/traces"),
    headers=os.getenv("OTEL_EXPORTER_OTLP_HEADERS", ""),
)
```

---

## 🎯 Step-by-Step Fix for Fly.io

**1. Get Grafana Cloud Tempo credentials:**
- Go to: https://grafana.com → My Account → Stacks
- Click your stack → Tempo → Details
- Copy: OTLP Endpoint and Token

**2. Set secrets:**
```bash
flyctl secrets set OTEL_EXPORTER_OTLP_ENDPOINT="https://tempo-XX.grafana.net:443"
flyctl secrets set OTEL_EXPORTER_OTLP_HEADERS="Authorization: Basic $(echo -n 'username:token' | base64)"
```

**3. Restart:**
```bash
flyctl apps restart license-server-demo
```

**4. Wait 30 seconds, then test:**
```bash
curl -I https://license-server-demo.fly.dev/faulty
# Copy x-trace-id from response

# Search in Grafana Cloud
# Explore → Tempo → Paste trace ID
```

**5. Check logs:**
```bash
flyctl logs | grep -i "otel\|trace"
# Should see no errors
```

---

## ✅ Success Indicators

**You'll know it's working when:**
- ✅ No errors in app logs
- ✅ Trace IDs appear in response headers
- ✅ Traces appear in Grafana Tempo Explore
- ✅ Can search for trace by ID successfully
- ✅ Can see trace details (spans, duration, etc.)

---

## 🐛 Still Not Working?

### Enable Debug Logging

**Local:**
```bash
# Add to docker-compose.yml api service:
environment:
  - OTEL_LOG_LEVEL=debug
```

**Fly.io:**
```bash
flyctl secrets set OTEL_LOG_LEVEL=debug
flyctl apps restart license-server-demo
flyctl logs | grep -i "otel"
```

### Check Network Connectivity

**Fly.io to Grafana Cloud:**
```bash
flyctl ssh console
curl -v https://tempo-XX.grafana.net:443
# Should connect (even if 401/403, that's OK - means network works)
```

---

## 📚 Next Steps

1. **Verify configuration** - Check all environment variables
2. **Test locally first** - Use docker-compose to verify it works
3. **Check Grafana Cloud** - Verify Tempo datasource is configured
4. **Read logs** - Look for connection/auth errors
5. **Test with new trace** - Make a fresh request and search immediately

---

**If you're still stuck, check:**
- [Quick Start Guide](./QUICKSTART_LOGS_TRACES.md)
- [Find Trace by ID](./FIND_TRACE_BY_ID.md)
- [Grafana Cloud Tempo Docs](https://grafana.com/docs/tempo/latest/)


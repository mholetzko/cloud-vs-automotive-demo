# Loki Setup for Fly.io - Quick Fix

## ❌ Problem: "No logs volume available" in Grafana

This means Loki isn't receiving logs because the `LOKI_URL` and `LOKI_AUTH` secrets are not configured in Fly.io.

## ✅ Solution: Configure Loki Secrets

### Step 1: Get Grafana Cloud Loki Credentials

1. Go to: https://grafana.com/auth/sign-in/
2. Navigate to **My Account** → **Stacks** → Select your stack
3. Under **Loki**, click **"Details"** or **"Send Logs"**
4. You'll see:
   - **Push URL**: `https://logs-prod-XX-XX.grafana.net/loki/api/v1/push`
   - **Username**: A number (e.g., `1578794`)
   - **Password/API Key**: Click "Generate now" or "Reset" to get a token

### Step 2: Set Secrets in Fly.io

```bash
# Set the Loki push URL (replace with your actual URL)
flyctl secrets set LOKI_URL="https://logs-prod-XX-XX.grafana.net/loki/api/v1/push" --app license-server-demo

# Set the authentication (format: username:api-key)
flyctl secrets set LOKI_AUTH="1578794:your-api-key-here" --app license-server-demo
```

**Or if you have a Bearer token:**
```bash
flyctl secrets set LOKI_AUTH="Bearer your-token-here" --app license-server-demo
```

### Step 3: Verify Secrets Are Set

```bash
flyctl secrets list --app license-server-demo
```

You should see:
```
NAME                       	DIGEST           
LOKI_URL                   	...
LOKI_AUTH                  	...
OTEL_EXPORTER_OTLP_ENDPOINT	...
OTEL_EXPORTER_OTLP_HEADERS 	...
OTEL_RESOURCE_ATTRIBUTES   	...
```

### Step 4: Restart the App (Auto-restarts on secret change)

The app will automatically restart when secrets are updated. You can verify:

```bash
flyctl logs --app license-server-demo | grep -i loki
```

You should see:
```
INFO license-server Loki push handler configured
```

### Step 5: Generate Some Log Traffic

```bash
# Make some API requests to generate logs
curl https://license-server-demo.fly.dev/licenses/status
curl https://license-server-demo.fly.dev/licenses/status/all
```

### Step 6: Check Logs in Grafana

1. Go to: https://matthiasholetzko.grafana.net/explore
2. Select **Loki** datasource
3. Run query: `{app="license-server"}`
4. Set time range to **Last 5 minutes**
5. You should see logs appearing!

## 🔍 Troubleshooting

### Still No Logs?

**1. Check if secrets are set:**
```bash
flyctl secrets list --app license-server-demo
```

**2. Check app logs for errors:**
```bash
flyctl logs --app license-server-demo | grep -i "loki\|error"
```

**3. Verify credentials are correct:**
- Make sure the username is just the number (no extra characters)
- Make sure the API key is the full token (not truncated)
- Try regenerating the API key in Grafana Cloud

**4. Test the query in Grafana:**
- Try a broader query: `{}` (all logs)
- Check if the label name is correct: `{app="license-server"}`
- Try: `{job="license-server"}` (if Grafana Cloud uses different labels)

**5. Check Grafana Cloud Loki datasource:**
- Go to: Grafana → Configuration → Data Sources → Loki
- Verify the datasource is configured correctly
- Test the datasource connection

### Wrong Label Selector?

If logs are appearing but your query doesn't work, try:

**Option 1: Check actual labels in Loki:**
```logql
{}  # Show all logs and their labels
```

**Option 2: Use different label names:**
```logql
{job="license-server"}
{service="license-server"}
{app="license-server"}
```

**Option 3: Use label matcher:**
```logql
{job=~".*license.*"}
```

## 📊 Quick Test Query

Once logs are flowing, try these queries:

```logql
# All logs
{app="license-server"}

# Errors only
{app="license-server"} |= "ERROR"

# Recent requests
{app="license-server"} |= "request route="

# Last 5 minutes
{app="license-server"}
```

## ✅ Success Checklist

- [ ] `LOKI_URL` secret is set in Fly.io
- [ ] `LOKI_AUTH` secret is set in Fly.io
- [ ] App logs show "Loki push handler configured"
- [ ] Logs appear in Grafana Cloud Loki
- [ ] Query `{app="license-server"}` returns results

## 🔗 Related Docs

- [Loki Filter Guide](./LOKI_FILTERS.md)
- [Loki Push Setup](./LOKI_PUSH_SETUP.md)
- [Log Filtering Examples](./LOKI_LOG_FILTERING.md)


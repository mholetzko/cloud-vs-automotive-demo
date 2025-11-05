# Loki Direct Push Setup

This guide explains how to configure direct log pushing to Grafana Cloud Loki from the Fly.io application.

## 🎯 Why Direct Push?

- ✅ Logs appear in Grafana Cloud immediately
- ✅ No need for Promtail on Fly.io
- ✅ Works seamlessly with Fly.io deployments
- ✅ Structured logs with automatic tagging

## 📋 Setup Steps

### 1. Get Grafana Cloud Loki Credentials

1. Go to your Grafana Cloud portal: https://grafana.com
2. Navigate to **My Account** → **Stacks**
3. Click on your stack
4. Under **Loki**, click **"Details"** or **"Send Logs"**
5. Copy these values:
   ```
   Push URL: https://logs-prod-XX-XX.grafana.net/loki/api/v1/push
   Username: 123456
   Password/API Key: (click "Generate now" if needed)
   ```

### 2. Configure Fly.io Environment Variables

Set the following secrets in Fly.io:

```bash
# Set Loki push URL
flyctl secrets set LOKI_URL="https://logs-prod-XX-XX.grafana.net/loki/api/v1/push"

# Set Loki authentication (format: username:password)
flyctl secrets set LOKI_AUTH="123456:your-api-key-here"
```

Or if you prefer Bearer token format:

```bash
flyctl secrets set LOKI_AUTH="Bearer your-token-here"
```

### 3. Verify It's Working

1. **Check logs in Grafana Cloud:**
   - Go to: https://matthiasholetzko.grafana.net/explore
   - Select **Loki** datasource
   - Run query: `{app="license-server"}`

2. **Generate some log traffic:**
   ```bash
   # Make some API requests
   curl https://license-server-demo.fly.dev/licenses/status
   ```

3. **Check logs appear:**
   - Logs should appear in Grafana Cloud within seconds
   - You'll see structured logs with tags: `app="license-server"`, `version="dev"`

## 🔍 Log Query Examples

### View all application logs:
```logql
{app="license-server"}
```

### Filter by log level:
```logql
{app="license-server"} |= "ERROR"
```

### Find specific trace IDs:
```logql
{app="license-server"} |= "trace_id=abc123"
```

### Correlate with traces:
- Click on a trace in Grafana Tempo
- Click "Logs" to see related logs for that trace
- Logs are automatically correlated via trace_id

## 📊 Local Development

For local development, you can also push to local Loki:

```bash
export LOKI_URL="http://localhost:3100/loki/api/v1/push"
# No auth needed for local Loki
python -m uvicorn app.main:app --reload
```

Or use Promtail (current setup) - both work!

## ✅ Verification Checklist

- [ ] `LOKI_URL` environment variable set in Fly.io
- [ ] `LOKI_AUTH` environment variable set in Fly.io
- [ ] Application logs appear in Grafana Cloud Loki
- [ ] Logs include trace IDs for correlation
- [ ] Logs can be correlated with traces in Tempo

## 🐛 Troubleshooting

### Logs not appearing in Grafana Cloud

1. **Check environment variables:**
   ```bash
   flyctl secrets list
   ```

2. **Check application logs:**
   ```bash
   flyctl logs
   ```
   Look for: `"Loki push handler configured"` or error messages

3. **Verify credentials:**
   - Make sure username and API key are correct
   - Check if API key has expired (regenerate if needed)

### Authentication errors

- Ensure `LOKI_AUTH` format is correct:
  - Basic auth: `username:password`
  - Bearer token: `Bearer your-token`
  
### Logs appear but can't query

- Check Loki datasource is configured in Grafana Cloud
- Verify the query syntax: `{app="license-server"}`

## 🔗 Related Documentation

- [Grafana Cloud Loki Documentation](https://grafana.com/docs/grafana-cloud/logs/)
- [Loki Query Language (LogQL)](https://grafana.com/docs/loki/latest/logql/)
- [Trace-to-Logs Correlation](../docs/LOKI_LOG_FILTERING.md)


# Grafana Alloy Setup

This directory contains the Grafana Alloy configuration for collecting logs from the license server and forwarding them to Grafana Cloud Loki.

## Quick Start

### 1. Get Grafana Cloud Loki Credentials

From Grafana Cloud → My Account → Stacks → Loki → "Send Logs":
- Push URL: `https://logs-prod-XX-XX.grafana.net/loki/api/v1/push`
- Username: Your user ID
- API Key: Generate or copy existing

### 2. Update `fly.toml` with Your Credentials

```toml
[env]
  LOKI_ENDPOINT = "https://logs-prod-XX-XX.grafana.net/loki/api/v1/push"
  LOKI_USERNAME = "1578794"
  LOKI_PASSWORD = "your-api-key-here"
```

### 3. Deploy Alloy to Fly.io

```bash
cd alloy
flyctl launch --app license-alloy
# Or if already exists:
flyctl deploy --app license-alloy
```

### 4. Get Alloy's Internal URL

```bash
flyctl status --app license-alloy
```

The internal URL will be: `http://license-alloy.internal:3100`

### 5. Configure License Server to Use Alloy

```bash
flyctl secrets set ALLOY_URL="http://license-alloy.internal:3100" --app license-server-demo
```

### 6. Verify

1. Check Alloy logs: `flyctl logs --app license-alloy`
2. Check license server logs: `flyctl logs --app license-server-demo | grep -i alloy`
3. Query logs in Grafana: `{app="license-server"}`

## Files

- `config.alloy` - Alloy configuration
- `Dockerfile` - Alloy container
- `fly.toml` - Fly.io deployment config

## Documentation

See [docs/ALLOY_SETUP.md](../docs/ALLOY_SETUP.md) for detailed instructions.


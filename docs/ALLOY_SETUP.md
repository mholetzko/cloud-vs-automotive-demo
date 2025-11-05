# Grafana Alloy Setup for Fly.io

This guide walks you through setting up Grafana Alloy to collect logs from your license server and forward them to Grafana Cloud Loki.

## 🎯 Architecture

```
┌─────────────────────┐
│  License Server     │
│  (Fly.io)           │─── HTTP POST ───> ┌──────────────┐
│  Python App         │                    │   Grafana    │
│                     │                    │    Alloy     │
│                     │                    │  (Fly.io)    │
└─────────────────────┘                    └──────┬───────┘
                                                   │
                                                   │ Loki Push
                                                   ▼
                                         ┌─────────────────┐
                                         │ Grafana Cloud   │
                                         │      Loki       │
                                         └─────────────────┘
```

## 📋 Prerequisites

1. **Grafana Cloud Account** with Loki enabled
2. **Loki credentials** from Grafana Cloud:
   - Push URL: `https://logs-prod-XX-XX.grafana.net/loki/api/v1/push`
   - Username: Your user ID
   - API Key: Your Loki API key

## 🚀 Setup Steps

### Step 1: Get Grafana Cloud Loki Credentials

1. Go to: https://grafana.com → **My Account** → **Stacks**
2. Select your stack
3. Under **Loki**, click **"Details"** or **"Send Logs"**
4. Copy these values:
   - **Push URL**: `https://logs-prod-XX-XX.grafana.net/loki/api/v1/push`
   - **Username**: Your user ID (number)
   - **API Key**: Generate or copy existing

### Step 2: Configure Alloy

1. **Edit `alloy/config.alloy`:**
   - The config is already set up to receive HTTP logs
   - It will forward to Grafana Cloud Loki

2. **Update `alloy/fly.toml`** with your credentials:
   ```toml
   [env]
     LOKI_ENDPOINT = "https://logs-prod-XX-XX.grafana.net/loki/api/v1/push"
     LOKI_USERNAME = "1578794"
     LOKI_PASSWORD = "your-api-key-here"
   ```

### Step 3: Deploy Alloy to Fly.io

```bash
cd alloy
flyctl launch --app license-alloy

# If the app already exists, deploy:
flyctl deploy --app license-alloy
```

### Step 4: Get Alloy's Internal URL

After deployment, get Alloy's internal URL:

```bash
flyctl status --app license-alloy
```

The internal URL will be something like: `https://license-alloy.internal:3100`

Or get the full internal hostname:

```bash
flyctl status --app license-alloy | grep Hostname
```

The internal URL format is: `http://license-alloy.internal:3100`

### Step 5: Update License Server to Send Logs to Alloy

Update your license server to send logs to Alloy instead of directly to Loki.

**Option A: Update app to send HTTP logs to Alloy**

Modify `app/main.py` to send logs to Alloy's HTTP endpoint:

```python
# Instead of direct Loki push, send to Alloy
alloy_url = os.getenv("ALLOY_URL", "http://license-alloy.internal:3100/loki/api/v1/push")

# Use HTTP handler to send logs to Alloy
import requests
import json
from datetime import datetime

class AlloyLogHandler(logging.Handler):
    def emit(self, record):
        try:
            log_entry = {
                "streams": [{
                    "stream": {
                        "app": "license-server",
                        "level": record.levelname,
                    },
                    "values": [[
                        str(int(datetime.now().timestamp() * 1000000000)),
                        self.format(record)
                    ]]
                }]
            }
            requests.post(
                f"{alloy_url}/loki/api/v1/push",
                json=log_entry,
                timeout=5
            )
        except Exception:
            pass  # Don't fail if Alloy is down

if alloy_url:
    logger.addHandler(AlloyLogHandler())
```

**Option B: Use syslog (if preferred)**

Configure Alloy to receive syslog and update the app accordingly.

### Step 6: Set Environment Variables

Set the Alloy URL in your license server:

```bash
flyctl secrets set ALLOY_URL="http://license-alloy.internal:3100" --app license-server-demo
```

### Step 7: Verify It's Working

1. **Check Alloy is running:**
   ```bash
   flyctl logs --app license-alloy
   ```

2. **Check Alloy is receiving logs:**
   ```bash
   flyctl logs --app license-alloy | grep -i "license-server"
   ```

3. **Generate some log traffic:**
   ```bash
   curl https://license-server-demo.fly.dev/licenses/status
   ```

4. **Check logs in Grafana Cloud:**
   - Go to: https://matthiasholetzko.grafana.net/explore
   - Select **Loki** datasource
   - Run query: `{app="license-server"}`
   - You should see logs appearing!

## 🔍 Troubleshooting

### Alloy not receiving logs

1. **Check Alloy is running:**
   ```bash
   flyctl status --app license-alloy
   ```

2. **Check Alloy logs:**
   ```bash
   flyctl logs --app license-alloy
   ```

3. **Verify internal networking:**
   - Alloy and license server must be in the same Fly.io organization
   - Use `.internal` hostname for internal communication

### Logs not appearing in Grafana Cloud

1. **Check Alloy configuration:**
   ```bash
   flyctl ssh console --app license-alloy
   cat /etc/alloy/config.alloy
   ```

2. **Verify Loki credentials:**
   ```bash
   flyctl secrets list --app license-alloy
   ```

3. **Check Alloy logs for errors:**
   ```bash
   flyctl logs --app license-alloy | grep -i error
   ```

### License server can't reach Alloy

1. **Verify internal URL:**
   ```bash
   flyctl status --app license-alloy
   ```

2. **Check ALLOY_URL secret:**
   ```bash
   flyctl secrets list --app license-server-demo | grep ALLOY
   ```

3. **Test connectivity:**
   ```bash
   flyctl ssh console --app license-server-demo
   curl http://license-alloy.internal:3100/ready
   ```

## 📊 Querying Logs in Grafana

Once logs are flowing, use these queries:

```logql
# All logs
{app="license-server"}

# Errors only
{app="license-server"} |= "ERROR"

# Recent requests
{app="license-server"} |= "request route="
```

## 🔄 Alternative: Keep Direct Push + Add Alloy

You can also run both:
- Keep direct push as primary
- Use Alloy as backup/alternative
- Or use Alloy for additional log processing

## 📝 Configuration Files

- `alloy/config.alloy` - Alloy configuration
- `alloy/Dockerfile` - Alloy container
- `alloy/fly.toml` - Fly.io deployment config

## ✅ Success Checklist

- [ ] Grafana Cloud Loki credentials obtained
- [ ] Alloy deployed to Fly.io
- [ ] Alloy receiving logs from license server
- [ ] Logs appearing in Grafana Cloud
- [ ] Queries working in Grafana Explore

## 🔗 Related Documentation

- [Grafana Alloy Documentation](https://grafana.com/docs/alloy/latest/)
- [Loki Filter Guide](./LOKI_FILTERS.md)
- [Loki Setup for Fly.io](./LOKI_SETUP_FLYIO.md)


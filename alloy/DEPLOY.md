# Deploy Grafana Alloy to Fly.io

## 🎯 Quick Deploy

### Option 1: Using Hardcoded Credentials (Current)

Credentials are already in `config.alloy`. Just deploy:

```bash
cd alloy
flyctl launch --app license-alloy
# Or if already exists:
flyctl deploy --app license-alloy
```

### Option 2: Using Fly.io Secrets (Recommended for Production)

1. **Update Dockerfile to use environment-based config:**
   ```dockerfile
   FROM grafana/alloy:latest
   COPY config.alloy.env /etc/alloy/config.alloy
   EXPOSE 3100
   ENTRYPOINT ["/bin/alloy", "run", "/etc/alloy/config.alloy"]
   ```

2. **Set secrets in Fly.io:**
   ```bash
   flyctl secrets set LOKI_ENDPOINT="https://logs-prod-XX-XX.grafana.net/loki/api/v1/push" --app license-alloy
   flyctl secrets set LOKI_USERNAME="YOUR_USER_ID" --app license-alloy
   flyctl secrets set LOKI_PASSWORD="YOUR_API_KEY" --app license-alloy
   ```

3. **Deploy:**
   ```bash
   flyctl deploy --app license-alloy
   ```

## 📋 Credentials Configuration

Get your credentials from Grafana Cloud → My Account → Stacks → Loki → "Send Logs":
- **Loki URL**: `https://logs-prod-XX-XX.grafana.net/loki/api/v1/push`
- **Username**: Your user ID
- **API Key**: Generate or copy from Grafana Cloud

## ✅ Verify Deployment

1. **Check Alloy is running:**
   ```bash
   flyctl status --app license-alloy
   ```

2. **Check Alloy logs:**
   ```bash
   flyctl logs --app license-alloy
   ```

3. **Get Alloy's internal URL:**
   ```bash
   flyctl status --app license-alloy | grep Hostname
   ```
   Internal URL: `http://license-alloy.internal:3100`

## 🔗 Configure License Server

Once Alloy is deployed, configure the license server:

```bash
flyctl secrets set ALLOY_URL="http://license-alloy.internal:3100" --app license-server-demo
```

## 🔍 Test Logs

1. **Generate some logs:**
   ```bash
   curl https://license-server-demo.fly.dev/licenses/status
   ```

2. **Check in Grafana:**
   - Go to: https://matthiasholetzko.grafana.net/explore
   - Select **Loki** datasource
   - Query: `{app="license-server"}`


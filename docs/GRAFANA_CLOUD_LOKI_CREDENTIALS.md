# How to Get Grafana Cloud Loki Credentials for Direct Push

## 🎯 For Fly.io (Platform as a Service) - Direct Push Method

Since your app already has direct Loki push implemented (using `python-logging-loki`), you **don't need Grafana Alloy**. You just need the Loki API push credentials.

## 📋 Step-by-Step: Finding Your Loki Push Credentials

### Option 1: Via Grafana Cloud Portal (Recommended)

1. **Go to Grafana Cloud Portal:**
   - Visit: https://grafana.com/auth/sign-in/
   - Sign in to your account

2. **Navigate to Your Stack:**
   - Click **"My Account"** (top right)
   - Click **"Stacks"** in the left menu
   - Select your stack (e.g., "matthiasholetzko")

3. **Find Loki Section:**
   - Scroll down to the **"Loki"** section
   - Look for **"Send Logs"** or **"Details"** button
   - Click it

4. **Get Push Endpoint:**
   - You'll see a section like **"Push logs via Grafana Alloy"** or **"Push logs via API"**
   - Look for **"Push URL"** or **"Loki API endpoint"**
   - Example: `https://logs-prod-XX-XX.grafana.net/loki/api/v1/push`
   - Copy this URL

5. **Get Authentication:**
   - **Username**: Your user ID (a number, e.g., `1578794`)
   - **API Key**: 
     - If you see a "Generate now" or "Reset" button, click it
     - Or look for an existing API key
     - Copy the full token (it's long, looks like: `glc_eyJv...`)

### Option 2: Via Grafana UI (Alternative)

1. **Open Grafana:**
   - Go to: https://matthiasholetzko.grafana.net

2. **Go to Connections:**
   - Click **"Connections"** in the left menu (or "Configuration" → "Data Sources")
   - Click **"Add new connection"** or find **"Loki"**

3. **Find Loki Connection:**
   - Look for your Loki datasource
   - Click on it to see details

4. **Check Settings:**
   - Look for **"URL"** or **"Endpoint"**
   - The push URL is typically: `https://logs-prod-XX-XX.grafana.net/loki/api/v1/push`
   - For authentication, you may need to go back to the Grafana Cloud portal

### Option 3: Direct URL (If You Know Your Stack Details)

If you know your Grafana Cloud instance URL, you can construct it:

- **Grafana URL**: `https://matthiasholetzko.grafana.net`
- **Loki Push URL**: `https://logs-prod-XX-XX.grafana.net/loki/api/v1/push`
  - Replace `XX-XX` with your region (e.g., `eu-west-2`, `us-central-0`)

To find your region:
- Check your Grafana URL: `https://matthiasholetzko.grafana.net`
- The region is usually in the Loki endpoint URL shown in Grafana Cloud portal

## 🔑 Authentication Format

Grafana Cloud Loki uses **Basic Authentication**:

- **Format**: `username:api-key`
- **Example**: `1578794:your-api-key-here`

## ✅ Setting Secrets in Fly.io

Once you have the credentials:

```bash
# Set Loki push URL
flyctl secrets set LOKI_URL="https://logs-prod-XX-XX.grafana.net/loki/api/v1/push" --app license-server-demo

# Set authentication (username:api-key format)
flyctl secrets set LOKI_AUTH="1578794:your-api-key-here" --app license-server-demo
```

## 🔍 Quick Verification

After setting secrets, check app logs:

```bash
flyctl logs --app license-server-demo | grep -i loki
```

You should see:
```
INFO license-server Loki push handler configured
```

## ❓ Can't Find the Credentials?

If you're stuck on the Grafana Alloy setup page:

1. **Skip Alloy setup** - You don't need it for direct push
2. **Look for "Send Logs"** or **"Push API"** section instead
3. **Try "Other"** infrastructure option and look for API push instructions
4. **Check Grafana Cloud documentation**: https://grafana.com/docs/grafana-cloud/logs/

## 📝 What You Need

To configure direct push, you need:

- ✅ **LOKI_URL**: `https://logs-prod-XX-XX.grafana.net/loki/api/v1/push`
- ✅ **LOKI_AUTH**: `username:api-key` (Basic auth format)

That's it! No Alloy, no collectors, just direct push from your app.

## 🔗 Related Documentation

- [Loki Setup for Fly.io](./LOKI_SETUP_FLYIO.md)
- [Loki Filter Guide](./LOKI_FILTERS.md)
- [Loki Push Setup](./LOKI_PUSH_SETUP.md)


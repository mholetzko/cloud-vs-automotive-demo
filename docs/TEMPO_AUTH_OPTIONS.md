# Tempo Authentication Options

## Why Username + Token?

Grafana Cloud uses **Basic Authentication** which requires:
- **Username:** Your Grafana Cloud user ID (e.g., `1378044`)
- **Token:** Your OTLP token (e.g., `glc_eyJvIjoi...`)

This is combined as: `username:token` then base64 encoded.

## Option 1: Basic Auth (Username + Token) ✅ Recommended

This is what Grafana Cloud expects by default:

```bash
# Format: username:token
flyctl secrets set OTEL_EXPORTER_OTLP_HEADERS="Authorization: Basic $(echo -n 'YOUR_USERNAME:YOUR_TOKEN' | base64)"
```

**Why:** Grafana Cloud's OTLP gateway uses Basic Auth, which requires both username and password (token).

---

## Option 2: Bearer Token (Token Only) 🤔 Try This

Some OTLP endpoints support Bearer tokens directly:

```bash
# Format: Just the token
flyctl secrets set OTEL_EXPORTER_OTLP_HEADERS="Authorization: Bearer YOUR_TOKEN_HERE"
```

**Try this first!** If it works, you don't need the username.

---

## 🔍 How to Test

### Test Basic Auth:
```bash
# Replace YOUR_USERNAME and YOUR_TOKEN with actual values
flyctl secrets set OTEL_EXPORTER_OTLP_HEADERS="Authorization: Basic $(echo -n 'YOUR_USERNAME:YOUR_TOKEN' | base64)"
flyctl apps restart license-server-demo
curl -I https://license-server-demo.fly.dev/faulty
# Check if trace appears in Grafana Cloud
```

### Test Bearer Token:
```bash
# Replace YOUR_TOKEN with actual token
flyctl secrets set OTEL_EXPORTER_OTLP_HEADERS="Authorization: Bearer YOUR_TOKEN"
flyctl apps restart license-server-demo
curl -I https://license-server-demo.fly.dev/faulty
# Check if trace appears in Grafana Cloud
```

---

## ✅ Quick Answer

**Short answer:** Grafana Cloud's Basic Auth requires both username and token. But you can try Bearer token first (just the token) - it might work!

**Try Bearer first:**
```bash
flyctl secrets set OTEL_EXPORTER_OTLP_HEADERS="Authorization: Bearer YOUR_TOKEN_HERE"
```

**If that doesn't work, use Basic:**
```bash
flyctl secrets set OTEL_EXPORTER_OTLP_HEADERS="Authorization: Basic $(echo -n 'YOUR_USERNAME:YOUR_TOKEN' | base64)"
```

---

## 🤔 Why Does Basic Auth Need Username?

Basic Authentication is an HTTP standard that requires:
- **Username:** Identifier (your Grafana Cloud user ID)
- **Password:** Secret (your token)

It's combined as `username:password` then base64 encoded. This is how HTTP Basic Auth works - it's not specific to Grafana Cloud, it's the standard.

But for tokens, many APIs support Bearer authentication which only needs the token. Worth trying!


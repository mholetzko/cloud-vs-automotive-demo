# Grafana Cloud Exact Setup (From Grafana Cloud UI)

This uses the **exact format** provided by Grafana Cloud.

## ✅ Exact Configuration from Grafana Cloud

```bash
# Set all environment variables exactly as Grafana Cloud provides
flyctl secrets set OTEL_RESOURCE_ATTRIBUTES="service.name=license-server"

flyctl secrets set OTEL_EXPORTER_OTLP_ENDPOINT="https://otlp-gateway-prod-eu-west-2.grafana.net/otlp"

flyctl secrets set OTEL_EXPORTER_OTLP_HEADERS="Authorization=Basic%20MTQyNTkzOTpnbGNfZXlKdklqb2lNVFUzT0RjNU5DSXNJbTRpT2lKdmRHeHdMWFJ2YTJWdUlpd2lheUk2SWpNd1JIVTBiVEJLYTJ3NFVuUlBZbXd4TTBjNU5UbG5XU0lzSW0waU9uc2ljaUk2SW5CeWIyUXRaWFV0ZDJWemRDMHlJbjE5"

flyctl secrets set OTEL_EXPORTER_OTLP_PROTOCOL="http/protobuf"

# Restart app
flyctl apps restart license-server-demo
```

## ⚠️ Important Notes

1. **Header Format:** Grafana Cloud uses URL-encoded format (`Authorization=Basic%20...`). This is correct for their OTLP gateway.

2. **Service Name:** You can override the service name with `OTEL_RESOURCE_ATTRIBUTES`. Our code already sets `service.name=license-server`, but you can change it.

3. **Protocol:** `http/protobuf` is the default, but we can set it explicitly.

4. **No opentelemetry-instrument needed:** We're using manual instrumentation, so we don't need the wrapper command.

## 🔧 How Our Code Handles This

Our code reads these environment variables:
- `OTEL_EXPORTER_OTLP_ENDPOINT` ✅
- `OTEL_EXPORTER_OTLP_HEADERS` ✅
- `OTEL_RESOURCE_ATTRIBUTES` - Used if set, otherwise we use our default

The OpenTelemetry SDK will parse the URL-encoded header format correctly.

## ✅ Quick Setup

Just run these three commands (replace with your actual values):

```bash
flyctl secrets set OTEL_EXPORTER_OTLP_ENDPOINT="https://otlp-gateway-prod-eu-west-2.grafana.net/otlp"
flyctl secrets set OTEL_EXPORTER_OTLP_HEADERS="Authorization=Basic%20YOUR_BASE64_ENCODED_STRING"
flyctl secrets set OTEL_RESOURCE_ATTRIBUTES="service.name=license-server"
flyctl apps restart license-server-demo
```

## 🧪 Test

```bash
# Make a request
curl -I https://license-server-demo.fly.dev/faulty

# Check logs
flyctl logs | grep -i "otel\|trace"

# Copy x-trace-id and search in Grafana Cloud
```

---

**That's it!** Use Grafana Cloud's exact format and it should work.


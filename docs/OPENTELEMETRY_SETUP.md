# OpenTelemetry Setup - Manual vs Auto-Instrumentation

## ✅ Current Setup: Manual Instrumentation

We're using **manual instrumentation** which is already configured in the code. This is better than auto-instrumentation because:
- ✅ More control over configuration
- ✅ Works with FastAPI properly
- ✅ No need for wrapper scripts
- ✅ Easier to debug

## 📦 What We Have

### Dependencies (already installed):
```python
opentelemetry-api
opentelemetry-sdk
opentelemetry-instrumentation-fastapi
opentelemetry-instrumentation-httpx
opentelemetry-exporter-otlp-proto-http
```

### Configuration (already in code):
```python
# app/main.py
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

# Initialize OpenTelemetry
resource = Resource.create({
    "service.name": "license-server",
    "service.version": APP_VERSION,
})

trace_provider = TracerProvider(resource=resource)
processor = BatchSpanProcessor(
    OTLPSpanExporter(
        endpoint=os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://tempo:4318/v1/traces"),
        headers=os.getenv("OTEL_EXPORTER_OTLP_HEADERS", ""),
    )
)
trace_provider.add_span_processor(processor)
trace.set_tracer_provider(trace_provider)

app = FastAPI(title="License Server", version="0.1.0")

# Instrument FastAPI app
FastAPIInstrumentor.instrument_app(app)
```

## ⚠️ What We DON'T Need

### Auto-Instrumentation Wrapper (NOT needed):
Grafana Cloud's instructions show:
```bash
opentelemetry-instrument uvicorn app.main:app
```

**We don't need this** because we're already instrumenting manually with `FastAPIInstrumentor.instrument_app(app)`.

### Bootstrap Package (NOT needed):
```bash
pip install opentelemetry-bootstrap -i https://pypi.org/simple
```

**We don't need this** because we're manually configuring everything.

## ✅ What We DO Need

### Just Environment Variables:

**For Fly.io:**
```bash
# Set OTLP endpoint
flyctl secrets set OTEL_EXPORTER_OTLP_ENDPOINT="https://otlp-gateway-prod-eu-west-2.grafana.net/otlp"

# Set authentication
flyctl secrets set OTEL_EXPORTER_OTLP_HEADERS="Authorization: Basic MTM3ODA0NDpnbGNfZXlKdklqb2lNVFUzT0RjNU5DSXNJbTRpT2lKdmRHeHdMWFJ2YTJWdUlpd2lheUk2SWpNd1JIVTBiVEJLYTJ3NFVuUlBZbXd4TTBjNU5UbG5XU0lzSW0waU9uc2ljaUk2SW5CeWIyUXRaWFV0ZDJWemRDMHlJbjE5"

# Restart
flyctl apps restart license-server-demo
```

**For Local Development:**
```bash
# No env vars needed - defaults to local Tempo
docker-compose up -d
```

## 🔄 How It Works

### Current Setup (Manual):
```
FastAPI App Startup
    ↓
OpenTelemetry SDK Initializes
    ↓
FastAPIInstrumentor.instrument_app(app) ← Instruments all routes
    ↓
Traces automatically captured on every request
    ↓
OTLPSpanExporter sends to Grafana Cloud
```

### Auto-Instrumentation (NOT using):
```
opentelemetry-instrument wrapper
    ↓
Auto-instruments imports
    ↓
Runs: uvicorn app.main:app
    ↓
Traces captured
```

**Our manual approach is cleaner and more explicit.**

## ✅ Verification

After setting environment variables, verify:

1. **Check logs:**
   ```bash
   flyctl logs | grep -i "otel\|trace"
   ```
   Should see no errors.

2. **Make a request:**
   ```bash
   curl -I https://license-server-demo.fly.dev/faulty
   ```

3. **Check trace ID in headers:**
   ```
   x-trace-id: abc123...
   ```

4. **Search in Grafana Cloud:**
   - Go to: https://matthiasholetzko.grafana.net/explore
   - Select **Tempo** datasource
   - Paste trace ID
   - Should see the trace!

## 📚 Summary

- ✅ **Dependencies:** Already installed
- ✅ **Instrumentation:** Already configured in code
- ✅ **Configuration:** Just need environment variables
- ❌ **Auto-instrumentation wrapper:** NOT needed
- ❌ **Bootstrap package:** NOT needed

**Just set the environment variables and restart!**


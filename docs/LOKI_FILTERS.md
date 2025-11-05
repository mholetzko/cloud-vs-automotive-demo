# Loki Log Filters - Quick Reference

Quick copy-paste LogQL queries for filtering logs in Grafana Loki.

## 🔍 Basic Filters

### All Application Logs
```logql
{app="license-server"}
```

### Errors Only
```logql
{app="license-server"} |= "ERROR"
```

### Warnings Only
```logql
{app="license-server"} |= "WARNING"
```

### Info Logs Only
```logql
{app="license-server"} |= "INFO"
```

---

## 🚨 Error & Debug Filters

### 500 Errors
```logql
{app="license-server"} |= "500 response"
```

### All Errors (with stack traces)
```logql
{app="license-server"} | json | level="ERROR"
```

### Faulty Endpoint (Demo)
```logql
{app="license-server"} |= "faulty endpoint"
```

### Unhandled Exceptions
```logql
{app="license-server"} |= "unhandled exception"
```

---

## 📊 Request Filters

### All HTTP Requests
```logql
{app="license-server"} |= "request route="
```

### Specific Route (e.g., /faulty)
```logql
{app="license-server"} |= "route=/faulty"
```

### Slow Requests (>1 second)
```logql
{app="license-server"} |~ "duration=([1-9]|\\d{2,})\\."
```

### Requests by Method (GET, POST, etc.)
```logql
{app="license-server"} |= "method=GET"
{app="license-server"} |= "method=POST"
```

---

## 🔐 License Operations

### Borrow Operations
```logql
{app="license-server"} |= "borrow"
```

### Borrow Success
```logql
{app="license-server"} |= "borrow success"
```

### Borrow Failures
```logql
{app="license-server"} |= "borrow failed"
```

### Return Operations
```logql
{app="license-server"} |= "return success"
```

### Overage Checkouts
```logql
{app="license-server"} |= "overage"
```

---

## 👤 User & Tool Filters

### By Specific User
```logql
{app="license-server"} |~ "user=alice"
```

### By Specific Tool
```logql
{app="license-server"} |~ "tool=ECU Development Suite"
```

### By Tool (using regex)
```logql
{app="license-server"} |~ "tool=.*Development.*"
```

---

## 🔗 Trace & Request ID Filters

### By Request ID
```logql
{app="license-server"} |~ "request_id=debe3916"
```

### By Trace ID
```logql
{app="license-server"} |~ "trace_id=a8611dfc2f7d408fe9519c845f66e19a"
```

### All Requests with Trace IDs
```logql
{app="license-server"} |~ "trace_id="
```

---

## 🔒 Security & Authentication

### Security Failures
```logql
{app="license-server"} |= "Security check failed"
```

### Invalid API Keys
```logql
{app="license-server"} |= "invalid api key"
```

### API Key Operations
```logql
{app="license-server"} |= "api_key"
```

---

## 💰 Budget & Cost Filters

### Budget Updates
```logql
{app="license-server"} |= "budget"
```

### Max Spend Blocked
```logql
{app="license-server"} |= "max spend"
```

### Customer Requests
```logql
{app="license-server"} |= "customer_request_more"
```

---

## 📈 Advanced Filters

### Combine Multiple Conditions (AND)
```logql
{app="license-server"} |~ "borrow" |~ "failed" |~ "tool=ECU"
```

### Combine Multiple Conditions (OR)
```logql
{app="license-server"} |~ "ERROR" or |= "WARNING"
```

### Exclude Specific Route
```logql
{app="license-server"} != "route=/metrics"
```

### Rate Calculation (Errors per minute)
```logql
sum(count_over_time({app="license-server"} |= "ERROR" [1m]))
```

### Count by Level
```logql
sum by (level) (count_over_time({app="license-server"} [1m]))
```

---

## 🎯 Most Useful Queries

### 1. All Errors from Last Hour
```logql
{app="license-server"} |= "ERROR"
```
Time range: Last 1 hour

### 2. Slow Requests (>500ms)
```logql
{app="license-server"} |~ "duration=([5-9]|\\d{2,})\\."
```

### 3. Find All Logs for a Specific Request
```logql
{app="license-server"} |~ "request_id=YOUR_REQUEST_ID"
```

### 4. Find All Logs for a Specific Trace
```logql
{app="license-server"} |~ "trace_id=YOUR_TRACE_ID"
```

### 5. Failed Borrow Attempts
```logql
{app="license-server"} |= "borrow failed"
```

### 6. Recent Activity (Last 5 minutes)
```logql
{app="license-server"}
```
Time range: Last 5 minutes

---

## 🔍 Finding Specific Issues

### Find Startup Errors
```logql
{app="license-server"} |~ "startup" or |= "initialization"
```

### Find Database Errors
```logql
{app="license-server"} |~ "database" or |= "sqlite"
```

### Find OpenTelemetry Issues
```logql
{app="license-server"} |~ "otel" or |= "OpenTelemetry"
```

### Find Loki Issues
```logql
{app="license-server"} |~ "loki" or |= "Loki"
```

---

## 💡 Pro Tips

### Use Time Range
- Set time range in Grafana UI (top right)
- Or use `[$__range]` in LogQL

### Use Line Filters
- `|=` - Contains (case-sensitive)
- `|~` - Regex match
- `!=` - Not contains
- `!~` - Not regex match

### Combine with Labels
```logql
{app="license-server", version="dev"} |= "ERROR"
```

### Extract Fields
```logql
{app="license-server"} | json | route="/faulty"
```

---

## 📋 Quick Copy-Paste

**Most common:**
```logql
{app="license-server"} |= "ERROR"
```

**Find specific request:**
```logql
{app="license-server"} |~ "request_id=YOUR_ID"
```

**Find specific trace:**
```logql
{app="license-server"} |~ "trace_id=YOUR_TRACE_ID"
```

**All recent activity:**
```logql
{app="license-server"}
```


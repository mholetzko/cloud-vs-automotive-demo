# Log Scraping Options

This document explains the different ways to collect logs from the application, especially for Fly.io deployments.

## 📊 Available Methods

### 1. ✅ Direct Push to Loki (Recommended)

**How it works:**
- Application pushes logs directly to Grafana Cloud Loki
- No intermediate service needed
- Works everywhere (local, Fly.io, any cloud)

**Setup:**
```bash
# Set environment variables in Fly.io
flyctl secrets set LOKI_URL="https://logs-prod-XX-XX.grafana.net/loki/api/v1/push"
flyctl secrets set LOKI_AUTH="username:api-key"
```

**Pros:**
- ✅ Simple setup
- ✅ Works on Fly.io
- ✅ No additional infrastructure
- ✅ Real-time delivery

**Cons:**
- ❌ Requires Grafana Cloud credentials
- ❌ Adds small latency per log entry

---

### 2. ✅ HTTP Scraping via `/logs` Endpoint

**How it works:**
- Application exposes `/logs` endpoint with recent log entries
- External scraper polls this endpoint
- Can be used with custom scrapers or tools

**Endpoint:**
```
GET /logs?limit=100
```

**Response Format:**
```
2024-01-01T12:00:00.000Z INFO license-server request route=/api/status method=GET status=200 duration=0.023 request_id=abc123 trace_id=def456
2024-01-01T12:00:01.000Z WARNING license-server 500 response route=/api/faulty method=GET request_id=xyz789 trace_id=uvw012
```

**Example Scraper Script:**
```python
#!/usr/bin/env python3
"""Simple log scraper that polls /logs and pushes to Loki"""
import requests
import time
from datetime import datetime

APP_URL = "https://license-server-demo.fly.dev"
LOKI_URL = "http://localhost:3100/loki/api/v1/push"  # or Grafana Cloud
LOKI_AUTH = None  # or "username:password"

def scrape_and_push():
    """Poll /logs endpoint and push to Loki"""
    last_position = 0
    
    while True:
        try:
            # Fetch logs
            response = requests.get(f"{APP_URL}/logs?limit=100")
            if response.status_code == 200:
                logs = response.text.strip().split('\n')
                
                # Push to Loki (simple implementation)
                if logs:
                    # Format as Loki push payload
                    payload = {
                        "streams": [{
                            "stream": {"job": "license-server", "source": "http-scrape"},
                            "values": [[str(int(datetime.now().timestamp() * 1e9)), log] for log in logs]
                        }]
                    }
                    
                    headers = {}
                    if LOKI_AUTH:
                        headers["Authorization"] = f"Basic {LOKI_AUTH}"
                    
                    requests.post(LOKI_URL, json=payload, headers=headers)
                    print(f"Pushed {len(logs)} log entries")
            
            time.sleep(30)  # Poll every 30 seconds
        except Exception as e:
            print(f"Error: {e}")
            time.sleep(60)

if __name__ == "__main__":
    scrape_and_push()
```

**Pros:**
- ✅ Works with any HTTP client
- ✅ Can be used for debugging
- ✅ No app changes needed

**Cons:**
- ❌ Requires external scraper
- ❌ Polling introduces delay
- ❌ Not real-time

---

### 3. ✅ Promtail HTTP Push API

**How it works:**
- Application pushes logs directly to Promtail
- Promtail then forwards to Loki
- Useful when you want to run Promtail locally

**Setup:**

1. Configure Promtail to accept HTTP push:
```yaml
# promtail-config.yml
server:
  http_listen_port: 9080

clients:
  - url: http://loki:3100/loki/api/v1/push

positions:
  filename: /tmp/positions.yaml

# HTTP push receiver
server:
  http_listen_port: 9080
  grpc_listen_port: 0
```

2. Configure app to push to Promtail:
```bash
# Set Promtail URL instead of Loki URL
flyctl secrets set LOKI_URL="http://your-promtail:9080/loki/api/v1/push"
```

**Pros:**
- ✅ Centralized log collection
- ✅ Can add processing/transformation
- ✅ Works with existing Promtail setup

**Cons:**
- ❌ Requires Promtail to be running
- ❌ More complex setup

---

### 4. ✅ Fly.io Log Streaming (Future)

**How it works:**
- Use Fly.io's log streaming API
- Forward to Loki or Promtail

**Note:** This would require implementing Fly.io's log streaming API integration.

---

## 🎯 Recommended Approach

### For Fly.io Production:
**Use Direct Push (Option 1)** - Simplest and most reliable

### For Local Development:
**Use Docker Logs + Promtail (default)** - Already configured in docker-compose.yml

### For Custom Scenarios:
**Use HTTP Scraping (Option 2)** - Most flexible for custom integrations

---

## 📝 Summary Table

| Method | Fly.io | Local | Real-time | Complexity |
|--------|--------|-------|-----------|------------|
| Direct Push | ✅ | ✅ | ✅ | Low |
| HTTP Scrape | ✅ | ✅ | ❌ | Medium |
| Promtail Push | ✅ | ✅ | ✅ | Medium |
| Docker Logs | ❌ | ✅ | ✅ | Low |

---

## 🔧 Troubleshooting

### Logs not appearing in Loki?

1. **Check direct push:**
   ```bash
   flyctl logs | grep "Loki push handler"
   ```

2. **Test `/logs` endpoint:**
   ```bash
   curl https://license-server-demo.fly.dev/logs
   ```

3. **Verify Loki connection:**
   ```bash
   # Check if app can reach Loki
   flyctl ssh console
   curl -v $LOKI_URL
   ```

### High log volume?

- Adjust `limit` parameter in `/logs` endpoint
- Use direct push (more efficient)
- Consider log sampling for high-volume scenarios

---

## 📚 Related Documentation

- [Loki Push Setup Guide](./LOKI_PUSH_SETUP.md)
- [Loki Log Filtering](./LOKI_LOG_FILTERING.md)
- [Promtail Documentation](https://grafana.com/docs/loki/latest/clients/promtail/)


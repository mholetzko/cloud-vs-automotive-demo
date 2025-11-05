# Grafana Alert Setup Guide

This guide explains how to set up alerts in Grafana Cloud for the license server.

## 🎯 Setting Up the 500 Error Alert

### Option 1: Enable Alert from Dashboard (Recommended)

1. **Open the Dashboard**:
   - Navigate to: https://mholetzko.grafana.net/d/mhkzbqq/license-ops-overview
   - The "500s last minute (max)" panel already has an alert configured

2. **Enable the Alert**:
   - Click on the "500s last minute (max)" panel
   - Click the **Edit** button (pencil icon)
   - Go to the **Alert** tab
   - The alert is already configured with:
     - **Name**: "High 500 Error Rate"
     - **Condition**: Value > 5
     - **Duration**: 1 minute

3. **Add Notification Channel**:
   - Click **Add contact point** or select an existing one
   - Choose notification type:
     - **Email**: Send alerts to your email
     - **Slack**: Send to a Slack channel
     - **Webhook**: Send to any HTTP endpoint
     - **PagerDuty**: For on-call management
     - **Discord**: Send to Discord channel

4. **Save the Alert**:
   - Click **Save** to enable the alert
   - The alert will now trigger when the max count of 500 errors exceeds 5

### Option 2: Create Alert Rule Manually

1. **Go to Alerting**:
   - Navigate to: https://mholetzko.grafana.net/alerting
   - Click **New alert rule**

2. **Configure the Query**:
   ```
   Query A:
   max_over_time(sum(increase(license_http_500_total[1m]))[5m:1m])
   ```
   - Data source: `grafanacloud-prom`
   - Type: Range

3. **Set the Condition**:
   - Reduce: Last
   - When: is above
   - Threshold: 5

4. **Configure Evaluation**:
   - Evaluate every: 1 minute
   - For: 1 minute (alert must be above threshold for 1 minute)

5. **Add Labels**:
   ```
   severity: critical
   service: license-server
   ```

6. **Add Annotations**:
   ```
   summary: High 500 error rate detected
   description: Maximum 500 errors in last minute exceeded 5: {{ $value }}
   dashboard: https://mholetzko.grafana.net/d/mhkzbqq/license-ops-overview
   ```

7. **Add Notification Channel**:
   - Select or create a contact point
   - Choose notification type (Email, Slack, etc.)

8. **Save the Rule**:
   - Click **Save** to create the alert rule

## 📧 Setting Up Email Notifications

1. **Go to Alerting → Contact points**:
   - https://mholetzko.grafana.net/alerting/notifications

2. **Add Contact Point**:
   - Click **New contact point**
   - Name: `Email`
   - Type: **Email**
   - Email addresses: `your-email@example.com`
   - Click **Test** to verify
   - Click **Save**

## 💬 Setting Up Slack Notifications

1. **Create Slack Webhook**:
   - Go to https://api.slack.com/apps
   - Create a new app or use existing
   - Go to "Incoming Webhooks"
   - Create webhook URL for your channel

2. **Add Contact Point in Grafana**:
   - Go to Alerting → Contact points
   - Click **New contact point**
   - Name: `Slack`
   - Type: **Webhook**
   - URL: `https://hooks.slack.com/services/YOUR/WEBHOOK/URL`
   - Click **Save**

## 🔔 Testing the Alert

### Manual Test

1. **Trigger 500 Errors**:
   ```bash
   # Use the faulty endpoint multiple times
   curl -X POST https://license-server-demo.fly.dev/faulty
   # Repeat 6+ times quickly
   ```

2. **Check Alert**:
   - Go to Alerting → Alert rules
   - Find "High 500 Error Rate"
   - Should show as **Firing** after 1 minute

3. **Verify Notification**:
   - Check your email/Slack/configured channel
   - You should receive an alert notification

### View Alert History

- Go to: https://mholetzko.grafana.net/alerting/history
- See all fired alerts and their status

## 📊 Alert Query Explanation

The alert uses this PromQL query:
```promql
max_over_time(sum(increase(license_http_500_total[1m]))[5m:1m])
```

- `increase(license_http_500_total[1m])`: Count of 500 errors in the last 1 minute
- `sum(...)`: Sum across all routes
- `max_over_time(...[5m:1m])`: Maximum value over the last 5 minutes, evaluated every 1 minute

**When it triggers**: When the maximum count of 500 errors in any 1-minute window exceeds 5.

## 🎛️ Alert Configuration in Dashboard JSON

The alert is already configured in `grafana/license_ops_dashboard.json`:

```json
{
  "alert": {
    "conditions": [
      {
        "evaluator": { "params": [5], "type": "gt" },
        "operator": { "type": "and" },
        "query": { "params": ["A", "1m", "now"] },
        "reducer": { "params": [], "type": "last" },
        "type": "query"
      }
    ],
    "executionErrorState": "alerting",
    "for": "1m",
    "frequency": "10s",
    "name": "High 500 Error Rate",
    "noDataState": "no_data",
    "notifications": []
  }
}
```

**Note**: `"notifications": []` means no notification channel is configured. You need to add a contact point in Grafana Cloud UI.

## 🚀 Quick Start

1. Import the dashboard (if not already done):
   - Go to Dashboards → Import
   - Upload `grafana/license_ops_dashboard.json`
   - Set datasource variables

2. Enable the alert:
   - Edit the "500s last minute (max)" panel
   - Go to Alert tab
   - Add a contact point (Email, Slack, etc.)
   - Save

3. Test:
   - Trigger 6+ 500 errors quickly
   - Wait 1 minute
   - Check alert status and notifications

## 📚 Additional Resources

- [Grafana Alerting Documentation](https://grafana.com/docs/grafana/latest/alerting/)
- [Grafana Cloud Alerting Guide](https://grafana.com/docs/grafana-cloud/alerting/)
- [Contact Points](https://grafana.com/docs/grafana/latest/alerting/set-up/notifications/)


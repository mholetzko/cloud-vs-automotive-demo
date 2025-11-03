# Grafana Dashboards

This project includes two comprehensive Grafana dashboards that are automatically provisioned when you start the Docker stack.

## 📊 Available Dashboards

### 1. License Server Overview (Technical Metrics)

**Purpose:** Monitor technical performance and system health

**Location:** `grafana/dashboards/license_server.json`

**Metrics:**
- **Borrow Attempts** - Rate of license borrow attempts
- **Borrow Success** - Success rate of borrows
- **Current Borrowed per Tool** - Bar gauge showing active checkouts
- **Borrow Failures by Reason** - Timeseries of failure reasons (exhausted, max_overage, unknown_tool)
- **Borrow Duration (p95)** - 95th percentile response time
- **Pool Status** - Table showing total/borrowed/available licenses

**Best For:**
- DevOps engineers monitoring system performance
- Identifying bottlenecks and performance issues
- Tracking SLA compliance (response times)

---

### 2. License Business Metrics ⭐ NEW

**Purpose:** Track business KPIs, costs, and user behavior

**Location:** `grafana/dashboards/license_business_metrics.json`

**Sections:**

#### 📈 License Checkout Overview
- **Total Active Checkouts** - Current number of borrowed licenses (with thresholds)
- **Checkouts (Last Hour)** - Recent activity
- **Checkout Success Rate** - Percentage of successful borrows
- **Overage Checkouts** - Count of out-of-budget checkouts
- **Overage Rate** - Percentage of checkouts that are overage
- **Accumulated Overage Cost** - Total overage charges ($ USD)

#### 👥 Client Sources & Users
- **Checkouts by Client Type** - Pie chart showing distribution
- **Top Users by Checkout Count** - Bar gauge of most active users
- **User Activity Summary** - Table with detailed user statistics

#### ⚠️ Overage Analysis
- **Overage Rate by Tool** - Timeseries showing overage trends
- **Commit vs Overage Usage** - Stacked area chart (green = commit, orange = overage)
- **Overage Checkouts by Tool** - Bar gauge per tool
- **Tools Hitting Max Overage** - Alert count for tools at capacity
- **Peak Overage Usage** - Maximum overage reached

#### 💰 Cost Analysis
- **Total Cost (24h)** - Combined commit + overage costs
- **Commit Cost (Fixed)** - Base license fees
- **Overage Cost (Variable)** - Usage-based charges
- **Cost Efficiency** - Gauge showing cost optimization (higher is better)
- **Cost Over Time** - Hourly breakdown (stacked bars)
- **Cost Breakdown by Tool** - Table with per-tool costs

**Best For:**
- Business stakeholders and finance teams
- Product managers tracking usage patterns
- License administrators optimizing budgets
- Identifying cost-saving opportunities

---

## 🎨 Accessing the Dashboards

1. **Start the stack:**
   ```bash
   ./scripts/local_devops_demo.sh
   # OR
   docker-compose up
   ```

2. **Open Grafana:**
   ```
   http://localhost:3000
   ```
   - Username: `admin`
   - Password: `admin` (change on first login)

3. **Navigate to dashboards:**
   - Click "Dashboards" in the left sidebar
   - Both dashboards should appear automatically
   - Or use the search (tags: `license`, `business`, `demo`)

---

## 📊 Available Prometheus Metrics

The backend exposes these metrics at `/metrics`:

### Counters (cumulative)
- `license_borrow_attempts_total{tool, user}` - Total borrow attempts
- `license_borrow_success_total{tool, user}` - Successful borrows
- `license_borrow_failure_total{tool, reason}` - Failed attempts by reason
- `license_overage_checkouts_total{tool, user}` - Overage checkouts ⭐ NEW

### Gauges (current state)
- `licenses_borrowed{tool}` - Currently borrowed licenses
- `licenses_total{tool}` - Total available licenses ⭐ NEW
- `licenses_overage{tool}` - Current overage count ⭐ NEW
- `licenses_commit{tool}` - Commit quantity ⭐ NEW
- `licenses_max_overage{tool}` - Max overage allowed ⭐ NEW
- `licenses_at_max_overage{tool}` - Alert flag (0 or 1) ⭐ NEW

### Histograms
- `license_borrow_duration_seconds{tool}` - Operation latency (p50, p95, p99)

---

## 🔍 Example Queries

### Business Metrics

**Overage Rate:**
```promql
sum(rate(license_overage_checkouts_total[5m])) / 
(sum(rate(license_borrow_success_total[5m])) + 0.0001)
```

**Total Cost (24h):**
```promql
sum(increase(license_overage_checkouts_total[24h])) * 100 + 
count(licenses_total) * 1000
```

**Top Users:**
```promql
topk(10, sum by (user) (increase(license_borrow_success_total[1h])))
```

**Cost Efficiency:**
```promql
(count(licenses_total) * 1000) / 
(sum(increase(license_overage_checkouts_total[24h])) * 100 + 
 count(licenses_total) * 1000 + 1)
```

### Technical Metrics

**Success Rate:**
```promql
sum(rate(license_borrow_success_total[5m])) / 
sum(rate(license_borrow_attempts_total[5m]))
```

**P95 Latency:**
```promql
histogram_quantile(0.95, 
  sum by (le) (rate(license_borrow_duration_seconds_bucket[5m])))
```

**Failure Breakdown:**
```promql
sum by (reason) (rate(license_borrow_failure_total[5m]))
```

---

## 🎯 Key Insights from Dashboards

### What to Watch:

1. **High Overage Rate (>20%)** → Consider increasing commit quantity
2. **Low Cost Efficiency (<85%)** → Too many overage charges
3. **Tools at Max Overage** → Users being blocked, need more licenses
4. **Spike in Checkout Rate** → Potential load issue or new use case
5. **Checkout Success Rate <95%** → Capacity problems

### Optimization Strategies:

- **Move frequently used tools from overage to commit** → Lower cost per use
- **Identify power users** → Dedicated licenses or user training
- **Peak usage patterns** → Right-size license pools
- **Unused commit capacity** → Reduce fixed costs

---

## 🔧 Customization

### Adding Your Own Panels

1. Edit dashboards in Grafana UI
2. Export JSON: Dashboard Settings → JSON Model → Copy to clipboard
3. Save to `grafana/dashboards/*.json`
4. Restart Grafana to re-provision

### Changing Refresh Rate

Default: `10s`

Change in JSON:
```json
"refresh": "5s"  // or "30s", "1m", etc.
```

### Adding Alerts

1. Click panel title → Edit
2. Go to Alert tab
3. Create alert rule with conditions
4. Configure notification channels in Grafana settings

---

## 📚 Learn More

- [Prometheus Query Language](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Grafana Documentation](https://grafana.com/docs/)
- [PromQL Functions](https://prometheus.io/docs/prometheus/latest/querying/functions/)

---

## 🎓 Demo Scenarios

### Scenario 1: Cost Analysis
1. Generate traffic: `./scripts/launch_client.sh` → stress test
2. Watch overage costs accumulate in real-time
3. Show cost breakdown by tool
4. Demonstrate ROI of increasing commit quantity

### Scenario 2: User Behavior
1. Run different client types (Python, C++, Rust)
2. Show client distribution in pie chart
3. Identify top users
4. Track user activity patterns

### Scenario 3: Capacity Planning
1. Slowly increase load
2. Watch when tools hit max overage
3. Show impact on success rate
4. Demonstrate need for scaling

---

**Pro Tip:** Use the time range selector (top right) to zoom into specific incidents or compare time periods!


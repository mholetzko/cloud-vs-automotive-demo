# Per-Tool Real-Time Dashboard

## ✅ **NEW: Tool-Specific Analysis**

The real-time dashboard now supports **per-tool filtering** with detailed analytics and user annotations!

---

## 🎯 **Features**

### **1. Tool Selector Dropdown**
- Select "All Tools (Overview)" for system-wide view
- Or select any specific tool for detailed analysis
- Dynamically populated with available tools

### **2. Overview Mode (All Tools)**
Shows system-wide metrics:
- **License Borrows** - Total borrow rate across all tools
- **Overage Checkouts** - Total overage across all tools  
- **License Utilization** - Stacked bar chart by tool

### **3. Tool-Specific Mode** 
When you select a tool, you get:

#### **A. Borrow Chart with User Annotations** ⭐
- Line chart showing borrows over time for that tool
- **Hover over data points** to see:
  - Number of borrows
  - List of users who borrowed
- Points show actual checkout activity

#### **B. Active Checkouts by User**
- Doughnut chart showing current distribution
- See which users have active checkouts
- Real-time updates as users borrow/return

#### **C. Commit vs Overage**
- Doughnut chart showing breakdown:
  - In Commit (blue)
  - In Overage (orange)
  - Available (grey)

#### **D. Recent Activity Table**
- Scrollable table of recent events
- Shows: Time, Event Type (Borrow/Return), User, Type (Commit/Overage)
- Color-coded for easy scanning
- Last 20 events displayed

---

## 🎨 **User Experience**

### **Workflow:**

1. **Start with Overview**
   - See all tools at a glance
   - Identify which tools are busy

2. **Drill Down**
   - Click tool dropdown
   - Select specific tool (e.g., "Vector - DaVinci Configurator SE")

3. **Investigate**
   - See borrow trends over time
   - Identify which users are active
   - Check commit vs overage split
   - Review recent activity

4. **Switch Back**
   - Select "All Tools" to return to overview

---

## 💡 **Use Cases**

### **Use Case 1: Identify Heavy Users**
```
Problem: Licenses running out for DaVinci SE
Solution:
1. Select "Vector - DaVinci Configurator SE"
2. Look at "Active Checkouts by User" chart
3. See: "alice" has 5 checkouts, "bob" has 8
4. Contact bob about returning unused licenses
```

### **Use Case 2: Monitor Overage**
```
Problem: Overage costs increasing
Solution:
1. Select tool with high overage
2. Check "Commit vs Overage" chart
3. See: 80% in overage!
4. Decision: Increase commit allocation
```

### **Use Case 3: Investigate Checkout Patterns**
```
Problem: When are licenses being used?
Solution:
1. Select tool
2. Watch "Borrows Over Time" chart
3. See: Spike at 9am and 2pm (team build times)
4. Insight: Need more licenses during peak hours
```

### **Use Case 4: Track Specific User**
```
Problem: Did alice return her licenses?
Solution:
1. Select the tool
2. Look at "Recent Activity" table
3. See: alice borrowed at 10:15, returned at 10:45
4. Confirmed: Licenses returned
```

---

## 🎯 **Demo Script**

### **For Your Automotive Presentation:**

**Scene: Overage Crisis Investigation**

1. **Start with Overview**
   - "Here's our real-time dashboard showing all tools"
   - "Notice the overage rate is high (red)"

2. **Select DaVinci Configurator SE**
   - "Let's drill down into this specific tool"
   - *Click dropdown, select tool*

3. **Show Borrow Chart**
   - "Here's the borrow pattern over the last 30 minutes"
   - *Hover over data points*
   - "See? Each point shows who borrowed"
   - "alice, bob, carol - all checking out at the same time"

4. **Show User Distribution**
   - "And here's who currently has licenses checked out"
   - "bob has 8, alice has 5 - these are our power users"

5. **Show Commit/Overage**
   - "This tool has 5 commit licenses, 15 overage"
   - "Right now: 3 in commit, 10 in overage"
   - "That's costing us money!"

6. **Show Activity Table**
   - "Here's the last 20 events"
   - "See the orange 'Overage' tags?"
   - "Each one is a cost hit"

7. **Compare with Automotive**
   - "In automotive edge/IoT, you wouldn't have THIS level of detail"
   - "You'd get: 'Tool X used 100 times today' (maybe)"
   - "No users, no timestamps, no drill-down"
   - "Cloud DevOps gives you INSTANT, DETAILED visibility"

---

## 🔧 **Technical Implementation**

### **User Annotations**
Data points store metadata:
```javascript
{
  users: ['alice', 'bob'],
  count: 2
}
```

Tooltip callback adds user info:
```javascript
afterLabel: function(context) {
  const dataPoint = context.dataset.metadata?.[context.dataIndex];
  if (dataPoint && dataPoint.user) {
    return `User: ${dataPoint.user}`;
  }
  return '';
}
```

### **Dynamic Chart Switching**
- Overview charts remain in DOM (hidden when not selected)
- Tool-specific charts created on page load
- Switching updates `display` property
- Data cleared when switching to avoid stale info

### **Real-Time Updates**
- SSE stream provides data every second
- `updateToolSelector()` populates dropdown
- `updateToolSpecificCharts()` updates all tool charts
- Activity table rebuilt on each update (last 20 events)

---

## 📊 **Chart Details**

### **1. Borrows Over Time (Line Chart)**
- **X-axis:** Time (HH:MM:SS)
- **Y-axis:** Number of borrows
- **Points:** Clickable/hoverable
- **Tooltip:** Shows time + user list
- **Window:** Configurable (1min to 6 hours)

### **2. Active Checkouts by User (Doughnut)**
- **Segments:** One per user
- **Size:** Proportional to checkout count
- **Colors:** 8 distinct colors (cycles if > 8 users)
- **Tooltip:** User + count
- **Updates:** Real-time as borrows/returns happen

### **3. Commit vs Overage (Doughnut)**
- **In Commit:** Blue - licenses within commit allocation
- **In Overage:** Orange - licenses beyond commit
- **Available:** Grey - unused capacity
- **Total:** Always equals tool's total licenses

### **4. Recent Activity (Table)**
- **Time:** When event occurred
- **Event:** Borrow (blue dot) or Return (green dot)
- **User:** Who performed the action
- **Type:** Commit, Overage, or - (for returns)
- **Scrollable:** Max 300px height, shows 20 events

---

## 🎯 **Perfect for Your Demo!**

### **Key Benefits:**

1. **Granular Visibility**
   - Not just "system is busy"
   - But "bob is using 8 DaVinci SE licenses"

2. **Actionable Insights**
   - See patterns over time
   - Identify heavy users
   - Track overage costs

3. **Real-Time Investigation**
   - No waiting for reports
   - Drill down immediately
   - Make informed decisions

4. **Cloud DevOps Advantage**
   - This level of detail is HARD in edge/IoT
   - Automotive would need: data upload, aggregation, analysis (days)
   - Cloud: Instant (< 1 second)

---

## 🚀 **Usage**

```bash
# Start server
uvicorn app.main:app --reload

# Open dashboard
open http://localhost:8000/realtime

# Select a tool from dropdown
# Watch real-time updates!
```

---

## 💡 **Tips**

1. **Start Broad, Then Narrow**
   - Use "All Tools" to spot issues
   - Switch to specific tool to investigate

2. **Watch During Stress Test**
   - Run stress test
   - Switch between tools
   - See live activity

3. **Use for Troubleshooting**
   - "Who's holding licenses?"
   - "When did the spike occur?"
   - "Is this commit or overage?"

4. **Present to Management**
   - Show user activity (accountability)
   - Show overage costs (ROI for more licenses)
   - Show usage patterns (capacity planning)

---

## 🎬 **Demo Impact**

**Before (no per-tool view):**
- "System is experiencing high overage"
- *Generic, hard to act on*

**After (per-tool view):**
- "DaVinci SE has 10 overage checkouts"
- "bob has 8 active, alice has 5"
- "Spike started at 10:15am"
- "Cost: $500/hour in overage"
- *Specific, actionable, compelling!*

---

**This level of observability is what sets cloud DevOps apart from traditional edge/IoT monitoring!** 🎯✨


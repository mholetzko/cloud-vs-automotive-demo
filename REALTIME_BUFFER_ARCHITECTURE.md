# Real-Time Dashboard: Server-Side Buffer Architecture

## Overview

The real-time dashboard now uses **server-side buffering** to persist per-tool historical metrics. This ensures that when users switch between tool views, they don't lose the historical chart data.

## Architecture

### Server-Side (`app/main.py`)

#### `RealtimeMetricsBuffer` Class

The buffer stores:
- **Raw events**: Individual borrow/return/failure events with full details
- **Aggregated metrics**: Per-tool, per-minute time-series data

Key methods:
```python
def add_borrow(tool, user, is_overage, borrow_id):
    """Records a borrow event"""

def aggregate_tool_metrics(window_seconds=60):
    """Aggregates borrow events into per-tool, per-minute data points
    
    Returns:
        {
            "Tool Name": [
                {
                    "timestamp": "2025-11-04T10:30:00Z",
                    "count": 5,
                    "users": ["alice", "bob"],
                    "overage_count": 2
                },
                ...
            ]
        }
    """

def get_tool_history(tool, window_seconds=1800):
    """Get aggregated history for a specific tool"""
```

#### SSE Stream Enhancement

The `/realtime/stream` endpoint now includes:
```json
{
  "timestamp": "...",
  "tools": [...],
  "rates": {...},
  "recent_events": {...},
  "buffer_stats": {...},
  "tool_metrics": {
    "Vector - DaVinci Configurator SE": [
      {
        "timestamp": "2025-11-04T10:30:00Z",
        "count": 3,
        "users": ["alice", "bob"],
        "overage_count": 1
      }
    ]
  }
}
```

### Client-Side (`app/static/realtime.js`)

#### Data Flow

1. **SSE Connection**: Client receives full `tool_metrics` payload every second
2. **Caching**: `toolMetricsCache` stores the latest complete history
3. **View Switching**: When user selects a tool, historical data is loaded from cache
4. **Filtering**: Client filters data based on selected time window (30 min, 1hr, 6hr, etc.)

#### Key Changes

**Before** (Browser-side buffer):
- Data was accumulated in the browser
- Switching tools lost historical data
- Required complex browser-side state management

**After** (Server-side buffer):
```javascript
// Server maintains the buffer
let toolMetricsCache = null;

eventSource.onmessage = (event) => {
  const data = JSON.parse(event.data);
  
  // Cache server-provided history
  if (data.tool_metrics) {
    toolMetricsCache = data.tool_metrics;
  }
  
  updateDashboard(data);
};

function updateToolSpecificCharts(tool, toolMetrics) {
  // Get server-buffered history for this tool
  const toolHistory = toolMetrics[tool] || [];
  
  // Filter based on selected time window
  const cutoff = new Date(Date.now() - WINDOW_SIZE * 1000);
  const filteredHistory = toolHistory.filter(point => 
    new Date(point.timestamp) >= cutoff
  );
  
  // Update charts with persistent data
  toolBorrowChart.data.labels = filteredHistory.map(...);
  toolBorrowChart.data.datasets[0].data = filteredHistory.map(...);
  toolBorrowChart.update();
}
```

## Benefits

### 1. **Persistence**
- Historical data is maintained on the server for up to 6 hours
- Switching tool views doesn't lose chart history
- Charts repopulate instantly when returning to a previously viewed tool

### 2. **Scalability**
- Server aggregates data efficiently (one aggregation per tool, per minute)
- Clients don't need to maintain complex state
- Reduces browser memory usage

### 3. **Consistency**
- All clients see the same historical data
- Data survives browser refresh (as long as it's within the 6-hour retention window)
- Time windows work correctly across all views

### 4. **Performance**
- Data is aggregated once on the server, sent to all clients
- Charts update smoothly without flickering
- No expensive client-side recomputations

## Data Retention

- **Raw events**: Up to 100,000 borrows, 100,000 returns, 10,000 failures (6-hour window)
- **Aggregated metrics**: Per-tool, per-minute data points (up to 360 points per tool for 6 hours)
- **Automatic cleanup**: Old data is automatically removed as new data arrives

## User Experience

When a user:
1. **Opens the dashboard**: Sees real-time overview charts
2. **Selects a tool**: Instantly sees full 30-minute (or selected window) history
3. **Switches to another tool**: Previous tool's history is retained
4. **Changes time window**: All charts adjust to show correct historical range
5. **Refreshes browser**: Reconnects and receives full history from server

## Technical Details

### Aggregation Logic

Events are grouped into 1-minute buckets:
- **Timestamp**: Rounded to the minute (e.g., `10:30:00`, `10:31:00`)
- **Count**: Total borrows in that minute
- **Users**: Unique users who borrowed in that minute
- **Overage Count**: How many were overage borrows

### Time Window Filtering

Client-side filtering allows dynamic time windows without re-aggregation:
- 1 minute: Last 60 seconds
- 5 minutes: Last 300 seconds
- 10 minutes: Last 600 seconds
- **30 minutes**: Default, last 1800 seconds
- 1 hour: Last 3600 seconds
- 3 hours: Last 10,800 seconds
- 6 hours: Full retention window (21,600 seconds)

### Tooltip Annotations

Each data point in the "Borrows Over Time" chart includes:
- **Count**: Number of borrows
- **Users**: List of users who borrowed in that time period

This metadata is preserved in the server buffer and displayed in Chart.js tooltips.

## Future Enhancements

Possible improvements:
1. **Persistent Storage**: Store aggregated metrics in SQLite for retention beyond 6 hours
2. **Compression**: Use WebSocket compression for large payloads
3. **Partial Updates**: Send only delta updates instead of full history
4. **Configurable Retention**: Allow admins to adjust the 6-hour window
5. **Export Functionality**: Export historical data to CSV/JSON


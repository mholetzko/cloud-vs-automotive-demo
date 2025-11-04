// Real-Time Dashboard JavaScript
// Uses Server-Sent Events (SSE) for zero-lag updates

// Chart.js setup with smooth animations
const borrowRateChart = new Chart(document.getElementById('borrowRateChart'), {
  type: 'line',
  data: {
    labels: [],
    datasets: [{
      label: 'Borrows/min',
      data: [],
      borderColor: '#00adef',
      backgroundColor: 'rgba(0, 173, 239, 0.1)',
      tension: 0.4,
      fill: true,
      borderWidth: 2,
      pointRadius: 0,
      pointHoverRadius: 4
    }]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    animation: {
      duration: 300,
      easing: 'easeInOutQuad'
    },
    scales: {
      x: { 
        display: true,
        grid: { display: false }
      },
      y: { 
        beginAtZero: true,
        ticks: { precision: 0 }
      }
    },
    plugins: {
      legend: { display: false },
      tooltip: { mode: 'index', intersect: false }
    }
  }
});

const overageChart = new Chart(document.getElementById('overageChart'), {
  type: 'line',
  data: {
    labels: [],
    datasets: [{
      label: 'Overage Checkouts',
      data: [],
      borderColor: '#d32f2f',
      backgroundColor: 'rgba(211, 47, 47, 0.1)',
      tension: 0.4,
      fill: true,
      borderWidth: 2,
      pointRadius: 0,
      pointHoverRadius: 4
    }]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    animation: {
      duration: 300,
      easing: 'easeInOutQuad'
    },
    scales: {
      x: { 
        display: true,
        grid: { display: false }
      },
      y: { 
        beginAtZero: true,
        ticks: { precision: 0 }
      }
    },
    plugins: {
      legend: { display: false },
      tooltip: { mode: 'index', intersect: false }
    }
  }
});

const utilizationChart = new Chart(document.getElementById('utilizationChart'), {
  type: 'bar',
  data: {
    labels: [],
    datasets: [{
      label: 'In Commit',
      data: [],
      backgroundColor: '#00adef',
      stack: 'stack1'
    }, {
      label: 'In Overage',
      data: [],
      backgroundColor: '#f57c00',
      stack: 'stack1'
    }, {
      label: 'Available',
      data: [],
      backgroundColor: '#e0e0e0',
      stack: 'stack1'
    }]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    animation: {
      duration: 300,
      easing: 'easeInOutQuad'
    },
    indexAxis: 'y',
    scales: {
      x: { 
        stacked: true,
        beginAtZero: true,
        ticks: { precision: 0 }
      },
      y: { 
        stacked: true,
        ticks: {
          autoSkip: false,
          font: { size: 11 }
        }
      }
    },
    plugins: {
      legend: { 
        display: true,
        position: 'bottom'
      },
      tooltip: { 
        mode: 'index',
        intersect: false
      }
    }
  }
});

// Per-Tool Charts (created on demand)
let toolBorrowChart = new Chart(document.getElementById('toolBorrowChart'), {
  type: 'line',
  data: {
    labels: [],
    datasets: [{
      label: 'Borrows',
      data: [],
      borderColor: '#00adef',
      backgroundColor: 'rgba(0, 173, 239, 0.1)',
      tension: 0.4,
      fill: true,
      borderWidth: 2,
      pointRadius: 4,
      pointHoverRadius: 6,
      pointBackgroundColor: '#00adef'
    }]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    animation: { duration: 300 },
    scales: {
      x: { display: true },
      y: { beginAtZero: true, ticks: { precision: 0 } }
    },
    plugins: {
      legend: { display: false },
      tooltip: {
        mode: 'index',
        intersect: false,
        callbacks: {
          afterLabel: function(context) {
            // Add user info to tooltip
            const dataPoint = context.dataset.metadata?.[context.dataIndex];
            if (dataPoint && dataPoint.user) {
              return `User: ${dataPoint.user}`;
            }
            return '';
          }
        }
      }
    }
  }
});

let toolUserChart = new Chart(document.getElementById('toolUserChart'), {
  type: 'doughnut',
  data: {
    labels: [],
    datasets: [{
      data: [],
      backgroundColor: [
        '#00adef', '#667eea', '#f093fb', '#4facfe', 
        '#43e97b', '#fa709a', '#fee140', '#30cfd0'
      ]
    }]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { position: 'right' },
      tooltip: {
        callbacks: {
          label: function(context) {
            return `${context.label}: ${context.formattedValue} checkouts`;
          }
        }
      }
    }
  }
});

let toolCommitChart = new Chart(document.getElementById('toolCommitChart'), {
  type: 'doughnut',
  data: {
    labels: ['In Commit', 'In Overage', 'Available'],
    datasets: [{
      data: [0, 0, 0],
      backgroundColor: ['#00adef', '#f57c00', '#e0e0e0']
    }]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { position: 'bottom' }
    }
  }
});

// Metrics tracking
let WINDOW_SIZE = 1800; // Default: 30 minutes (in seconds)
let lastBorrowRate = 0;
let lastOverageRate = 0;
let selectedTool = 'all'; // Current tool filter
let allTools = []; // List of all available tools

// Time range selector
const timeRangeSelector = document.getElementById('time-range');
timeRangeSelector.addEventListener('change', (e) => {
  const newRange = parseInt(e.target.value);
  WINDOW_SIZE = newRange;
  
  // Update chart titles
  const label = getTimeRangeLabel(newRange);
  document.getElementById('borrow-chart-title').textContent = `License Borrows (Last ${label})`;
  document.getElementById('overage-chart-title').textContent = `Overage Checkouts (Last ${label})`;
  
  // Clear charts to start fresh with new range
  borrowRateChart.data.labels = [];
  borrowRateChart.data.datasets[0].data = [];
  overageChart.data.labels = [];
  overageChart.data.datasets[0].data = [];
  borrowRateChart.update();
  overageChart.update();
  
  console.log(`Time range changed to: ${label} (${newRange} seconds)`);
});

function getTimeRangeLabel(seconds) {
  if (seconds < 60) return `${seconds} seconds`;
  if (seconds < 3600) return `${Math.round(seconds / 60)} minutes`;
  return `${Math.round(seconds / 3600)} hour${seconds > 3600 ? 's' : ''}`;
}

// Tool filter selector
const toolFilterSelector = document.getElementById('tool-filter');
toolFilterSelector.addEventListener('change', (e) => {
  selectedTool = e.target.value;
  
  if (selectedTool === 'all') {
    // Show overview charts
    document.getElementById('overview-charts').style.display = 'block';
    document.getElementById('tool-specific-charts').style.display = 'none';
    document.getElementById('tool-info').textContent = '';
  } else {
    // Show tool-specific charts
    document.getElementById('overview-charts').style.display = 'none';
    document.getElementById('tool-specific-charts').style.display = 'block';
    
    // Clear tool-specific charts
    toolBorrowChart.data.labels = [];
    toolBorrowChart.data.datasets[0].data = [];
    toolBorrowChart.data.datasets[0].metadata = [];
    toolUserChart.data.labels = [];
    toolUserChart.data.datasets[0].data = [];
    toolCommitChart.data.datasets[0].data = [0, 0, 0];
    
    toolBorrowChart.update();
    toolUserChart.update();
    toolCommitChart.update();
  }
  
  console.log(`Tool filter changed to: ${selectedTool}`);
});

function updateToolSelector(tools) {
  // Update tool list
  allTools = tools;
  
  // Get current selection
  const currentSelection = toolFilterSelector.value;
  
  // Clear and rebuild options
  toolFilterSelector.innerHTML = '<option value="all">All Tools (Overview)</option>';
  
  tools.forEach(tool => {
    const option = document.createElement('option');
    option.value = tool.tool;
    option.textContent = tool.tool;
    toolFilterSelector.appendChild(option);
  });
  
  // Restore selection if it still exists
  if (currentSelection !== 'all') {
    const stillExists = tools.some(t => t.tool === currentSelection);
    if (stillExists) {
      toolFilterSelector.value = currentSelection;
    }
  }
}

function updateToolSpecificCharts(data) {
  if (selectedTool === 'all') return;
  
  // Find the selected tool
  const toolData = data.tools.find(t => t.tool === selectedTool);
  if (!toolData) return;
  
  // Update tool info
  document.getElementById('tool-info').textContent = 
    `${toolData.borrowed}/${toolData.total} in use (${toolData.in_commit} commit, ${toolData.overage} overage)`;
  
  // Update borrow chart with user annotations
  const toolBorrows = data.recent_events.borrows.filter(b => b.tool === selectedTool);
  if (toolBorrows.length > 0) {
    const now = new Date();
    const label = now.toLocaleTimeString();
    
    toolBorrowChart.data.labels.push(label);
    toolBorrowChart.data.datasets[0].data.push(toolBorrows.length);
    
    // Store metadata for tooltip
    if (!toolBorrowChart.data.datasets[0].metadata) {
      toolBorrowChart.data.datasets[0].metadata = [];
    }
    toolBorrowChart.data.datasets[0].metadata.push({
      users: toolBorrows.map(b => b.user),
      count: toolBorrows.length
    });
    
    // Keep only last WINDOW_SIZE points
    const maxPoints = Math.floor(WINDOW_SIZE / 60); // One point per minute
    if (toolBorrowChart.data.labels.length > maxPoints) {
      toolBorrowChart.data.labels.shift();
      toolBorrowChart.data.datasets[0].data.shift();
      toolBorrowChart.data.datasets[0].metadata.shift();
    }
    
    toolBorrowChart.update('none');
  }
  
  // Update user distribution (from current borrows)
  fetch(`/borrows?user=all`)
    .then(res => res.json())
    .then(borrows => {
      const toolBorrows = borrows.filter(b => b.tool === selectedTool);
      const userCounts = {};
      toolBorrows.forEach(b => {
        userCounts[b.user] = (userCounts[b.user] || 0) + 1;
      });
      
      toolUserChart.data.labels = Object.keys(userCounts);
      toolUserChart.data.datasets[0].data = Object.values(userCounts);
      toolUserChart.update('none');
    })
    .catch(err => console.error('Error fetching borrows:', err));
  
  // Update commit vs overage chart
  const inCommit = Math.min(toolData.borrowed, toolData.commit);
  const inOverage = toolData.overage;
  const available = toolData.available;
  
  toolCommitChart.data.datasets[0].data = [inCommit, inOverage, available];
  toolCommitChart.update('none');
  
  // Update recent events table
  const recentToolEvents = [
    ...toolBorrows.map(b => ({
      time: new Date(b.timestamp).toLocaleTimeString(),
      event: 'Borrow',
      user: b.user,
      type: b.is_overage ? 'Overage' : 'Commit'
    })),
    ...data.recent_events.returns
      .filter(r => {
        // Match returns by checking if any borrow from this tool matches the ID
        return toolBorrows.some(b => b.id === r.id);
      })
      .map(r => ({
        time: new Date(r.timestamp).toLocaleTimeString(),
        event: 'Return',
        user: r.user || 'Unknown',
        type: '-'
      }))
  ].sort((a, b) => b.time.localeCompare(a.time)).slice(0, 20);
  
  const tbody = document.getElementById('events-tbody');
  if (recentToolEvents.length === 0) {
    tbody.innerHTML = '<tr><td colspan="4" style="text-align: center; padding: 20px; color: #999;">No recent activity</td></tr>';
  } else {
    tbody.innerHTML = recentToolEvents.map(event => `
      <tr style="border-bottom: 1px solid #f0f0f0;">
        <td style="padding: 8px;">${event.time}</td>
        <td style="padding: 8px;">
          <span style="display: inline-block; width: 8px; height: 8px; border-radius: 50%; background: ${event.event === 'Borrow' ? '#00adef' : '#4caf50'}; margin-right: 6px;"></span>
          ${event.event}
        </td>
        <td style="padding: 8px;">${event.user}</td>
        <td style="padding: 8px;">
          ${event.type === 'Overage' ? '<span style="color: #f57c00; font-weight: 500;">Overage</span>' : 
            event.type === 'Commit' ? '<span style="color: #00adef;">Commit</span>' : '-'}
        </td>
      </tr>
    `).join('');
  }
}

// Connect to SSE stream
let eventSource = null;
let reconnectAttempts = 0;
const MAX_RECONNECT_ATTEMPTS = 10;

function connectSSE() {
  console.log('Connecting to real-time stream...');
  
  eventSource = new EventSource('/realtime/stream');
  
  eventSource.onopen = () => {
    console.log('✅ Connected to real-time stream');
    reconnectAttempts = 0;
    updateConnectionStatus(true);
  };
  
  eventSource.onerror = (error) => {
    console.error('❌ SSE connection error:', error);
    updateConnectionStatus(false);
    
    // Attempt reconnection
    if (reconnectAttempts < MAX_RECONNECT_ATTEMPTS) {
      reconnectAttempts++;
      const delay = Math.min(1000 * Math.pow(2, reconnectAttempts), 30000);
      console.log(`Reconnecting in ${delay/1000}s... (attempt ${reconnectAttempts}/${MAX_RECONNECT_ATTEMPTS})`);
      
      setTimeout(() => {
        if (eventSource) {
          eventSource.close();
        }
        connectSSE();
      }, delay);
    } else {
      console.error('Max reconnection attempts reached');
      document.getElementById('status-text').textContent = 'Connection failed';
    }
  };
  
  eventSource.onmessage = (event) => {
    try {
      const data = JSON.parse(event.data);
      updateDashboard(data);
    } catch (error) {
      console.error('Error parsing SSE data:', error);
    }
  };
}

function updateConnectionStatus(connected) {
  const statusEl = document.getElementById('connection-status');
  const textEl = document.getElementById('status-text');
  
  if (connected) {
    statusEl.className = 'connection-status connected';
    textEl.textContent = 'Connected (real-time)';
  } else {
    statusEl.className = 'connection-status disconnected';
    textEl.textContent = 'Disconnected (retrying...)';
  }
}

function updateDashboard(data) {
  // Update tool selector (if tools changed)
  if (data.tools && data.tools.length > 0) {
    updateToolSelector(data.tools);
  }
  
  // Update metric cards
  updateMetricCards(data.rates, data.tools, data.buffer_stats);
  
  // Update charts based on selected view
  if (selectedTool === 'all') {
    // Update overview charts
    updateBorrowRateChart(data.rates.borrow_per_min);
    updateOverageChart(data.recent_events.borrows);
    updateUtilizationChart(data.tools);
  } else {
    // Update tool-specific charts
    updateToolSpecificCharts(data);
  }
}

function updateMetricCards(rates, tools, bufferStats) {
  // Borrow rate
  const borrowRate = Math.round(rates.borrow_per_min);
  document.getElementById('borrow-rate').textContent = borrowRate;
  
  // Pulse animation when activity detected
  const borrowCard = document.getElementById('borrow-card');
  if (borrowRate > lastBorrowRate) {
    borrowCard.classList.add('pulse-active');
    setTimeout(() => borrowCard.classList.remove('pulse-active'), 1000);
  }
  lastBorrowRate = borrowRate;
  
  // Overage rate with color coding
  const overageRate = rates.overage_percent;
  const overageEl = document.getElementById('overage-rate');
  const overageCard = document.getElementById('overage-card');
  overageEl.textContent = overageRate.toFixed(1) + '%';
  
  // Color code based on threshold
  overageEl.className = 'metric-value';
  if (overageRate > 30) {
    overageEl.classList.add('critical');
    overageCard.classList.add('pulse-active');
  } else if (overageRate > 15) {
    overageEl.classList.add('warning');
  }
  
  // Pulse when overage increases
  if (overageRate > lastOverageRate) {
    overageCard.classList.add('pulse-active');
    setTimeout(() => overageCard.classList.remove('pulse-active'), 1000);
  }
  lastOverageRate = overageRate;
  
  // Return rate
  document.getElementById('return-rate').textContent = Math.round(rates.return_per_min);
  
  // Failure rate
  document.getElementById('failure-rate').textContent = Math.round(rates.failure_per_min);
  
  // Active licenses (total borrowed across all tools)
  const totalBorrowed = tools.reduce((sum, t) => sum + t.borrowed, 0);
  document.getElementById('active-licenses').textContent = totalBorrowed;
  
  // Buffer size
  document.getElementById('buffer-size').textContent = bufferStats.total_events.toLocaleString();
}

function updateBorrowRateChart(borrowRate) {
  const now = new Date();
  const label = now.toLocaleTimeString();
  
  // Add data point
  borrowRateChart.data.labels.push(label);
  borrowRateChart.data.datasets[0].data.push(borrowRate);
  
  // Keep only last WINDOW_SIZE points
  if (borrowRateChart.data.labels.length > WINDOW_SIZE) {
    borrowRateChart.data.labels.shift();
    borrowRateChart.data.datasets[0].data.shift();
  }
  
  borrowRateChart.update('none'); // Update without animation for smoothness
}

function updateOverageChart(recentBorrows) {
  const now = new Date();
  const label = now.toLocaleTimeString();
  
  // Count overage borrows in recent events
  const overageCount = recentBorrows.filter(b => b.is_overage).length;
  
  // Add data point
  overageChart.data.labels.push(label);
  overageChart.data.datasets[0].data.push(overageCount);
  
  // Keep only last WINDOW_SIZE points
  if (overageChart.data.labels.length > WINDOW_SIZE) {
    overageChart.data.labels.shift();
    overageChart.data.datasets[0].data.shift();
  }
  
  overageChart.update('none');
}

function updateUtilizationChart(tools) {
  // Sort tools by name for consistent ordering
  const sortedTools = [...tools].sort((a, b) => a.tool.localeCompare(b.tool));
  
  // Shorten tool names for better display
  utilizationChart.data.labels = sortedTools.map(t => {
    const parts = t.tool.split(' - ');
    return parts.length > 1 ? parts[1] : t.tool;
  });
  
  // Calculate stacked bar data
  const inCommit = sortedTools.map(t => Math.min(t.borrowed, t.commit));
  const inOverage = sortedTools.map(t => t.overage);
  const available = sortedTools.map(t => t.available);
  
  utilizationChart.data.datasets[0].data = inCommit;
  utilizationChart.data.datasets[1].data = inOverage;
  utilizationChart.data.datasets[2].data = available;
  
  utilizationChart.update('none');
}

// Initialize connection
connectSSE();

// Cleanup on page unload
window.addEventListener('beforeunload', () => {
  if (eventSource) {
    eventSource.close();
  }
});

// Log for debugging
console.log('Real-Time Dashboard initialized');
console.log('- SSE endpoint: /realtime/stream');
console.log('- Update interval: 1 second');
console.log('- Data retention: 6 hours');
console.log('- Default chart window: 30 minutes (configurable)');
console.log('- Available ranges: 1min, 5min, 10min, 30min, 1h, 3h, 6h');


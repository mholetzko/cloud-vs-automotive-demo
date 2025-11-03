function toggleOverageCharges() {
  const list = document.getElementById('overage-charges-list');
  const toggle = document.getElementById('overage-toggle');
  if (list.style.display === 'none') {
    list.style.display = 'block';
    toggle.textContent = '▼';
  } else {
    list.style.display = 'none';
    toggle.textContent = '▶';
  }
}

async function borrow(e) {
  e.preventDefault();
  const tool = document.getElementById('borrow-tool').value;
  const user = document.getElementById('borrow-user').value.trim();
  const out = document.getElementById('borrow-result');
  out.className = 'result';
  out.textContent = 'Processing…';
  try {
    const r = await fetch('/licenses/borrow', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ tool, user })
    });
    if (!r.ok) throw new Error((await r.json()).detail || 'Failed');
    const data = await r.json();
    out.classList.add('success');
    out.textContent = `Borrowed ${tool} for ${user}. ID: ${data.id}`;
    document.getElementById('return-id').value = data.id;
    await refreshStatusAll();
    await refreshBorrows();
    await refreshCosts();
  } catch (err) {
    out.classList.add('error');
    out.textContent = String(err.message || err);
  }
}

async function returnLicense(e) {
  e.preventDefault();
  const id = document.getElementById('return-id').value.trim();
  const out = document.getElementById('return-result');
  out.className = 'result';
  out.textContent = 'Processing…';
  try {
    const r = await fetch('/licenses/return', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id })
    });
    if (!r.ok) throw new Error((await r.json()).detail || 'Failed');
    const data = await r.json();
    out.classList.add('success');
    out.textContent = `Returned OK for tool: ${data.tool}`;
    await refreshStatusAll();
    await refreshBorrows();
    await refreshCosts();
  } catch (err) {
    out.classList.add('error');
    out.textContent = String(err.message || err);
  }
}

async function refreshStatusAll() {
  const out = document.getElementById('status');
  try {
    const r = await fetch('/licenses/status');
    if (!r.ok) throw new Error('Status fetch failed');
    const list = await r.json();
    if (!Array.isArray(list) || list.length === 0) {
      out.textContent = 'No tools found';
      return;
    }
    // Render pies
    out.classList.remove('status');
    out.classList.add('status-pies');
    out.innerHTML = '';
    const frag = document.createDocumentFragment();
    list.forEach(s => {
      const pctBorrowed = s.total > 0 ? Math.round((s.borrowed / s.total) * 100) : 0;
      const pieCard = document.createElement('div');
      pieCard.className = 'pie-card';
      const pie = document.createElement('div');
      pie.className = 'pie';
      // Create SVG donut pie
      const size = 64; const r = 26; const cx = 32; const cy = 32;
      const circumference = 2 * Math.PI * r;
      const borrowedLen = (pctBorrowed / 100) * circumference;
      const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
      svg.setAttribute('viewBox', '0 0 64 64');
      const bg = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
      bg.setAttribute('cx', cx); bg.setAttribute('cy', cy); bg.setAttribute('r', r);
      bg.setAttribute('fill', 'none'); bg.setAttribute('stroke', 'var(--mb-gray-300)'); bg.setAttribute('stroke-width', '12');
      const arc = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
      arc.setAttribute('cx', cx); arc.setAttribute('cy', cy); arc.setAttribute('r', r);
      arc.setAttribute('fill', 'none'); arc.setAttribute('stroke', 'var(--mb-blue)'); arc.setAttribute('stroke-width', '12');
      arc.setAttribute('stroke-dasharray', `${borrowedLen} ${circumference - borrowedLen}`);
      arc.setAttribute('stroke-linecap', 'butt');
      svg.appendChild(bg); svg.appendChild(arc);
      const pct = document.createElement('div'); pct.className = 'pct'; pct.textContent = `${pctBorrowed}%`;
      pie.appendChild(svg); pie.appendChild(pct);
      const legend = document.createElement('div');
      legend.className = 'pie-legend';
      const tool = document.createElement('div');
      tool.className = 'tool';
      tool.textContent = s.tool;
      const meta = document.createElement('div');
      meta.className = 'meta';
      const overageInfo = s.overage > 0 ? ` • ${s.overage} overage` : '';
      const budgetInfo = s.commit > 0 ? ` (commit: ${s.commit}, max overage: ${s.max_overage})` : '';
      meta.textContent = `borrowed ${s.borrowed}/${s.total}${overageInfo}${budgetInfo}`;
      if (s.overage > 0) {
        meta.style.color = '#c62828';
        meta.style.fontWeight = '600';
      }
      legend.appendChild(tool);
      legend.appendChild(meta);
      pieCard.appendChild(pie);
      pieCard.appendChild(legend);
      frag.appendChild(pieCard);
    });
    out.appendChild(frag);
  } catch (err) {
    out.textContent = 'Unable to load status';
  }
}

async function refreshBorrows() {
  try {
    const r = await fetch('/borrows');
    if (!r.ok) throw new Error('Load borrows failed');
    const list = await r.json();
    const out = document.getElementById('borrows');
    out.textContent = list.map(b => `${b.borrowed_at}  ${b.user} -> ${b.tool}  (${b.id})`).join('\n') || 'No current borrows';
  } catch (e) {
    document.getElementById('borrows').textContent = 'Unable to load borrows';

  }
}

async function refreshCosts() {
  console.log('Refreshing costs');
  const out = document.getElementById('costs');
  out.textContent = 'Loading costs...';
  try {
    const r = await fetch('/licenses/status');
    if (!r.ok) throw new Error('Load costs failed');
    const list = await r.json();
    if (!Array.isArray(list) || list.length === 0) {
      out.textContent = 'No tools found';
      return;
    }
    console.log('List:', list);
    let totalCommitCost = 0;
    let totalOverageCost = 0;
    let grandTotal = 0;
    const items = [];
    list.forEach(s => {
      totalCommitCost += s.commit_price || 0;
      totalOverageCost += s.current_overage_cost || 0;
      grandTotal += s.total_cost || 0;
      items.push({
        tool: s.tool,
        commit: s.commit_price || 0,
        overage: s.current_overage_cost || 0,
        total: s.total_cost || 0,
        overageCount: s.overage || 0
      });
    });
    out.innerHTML = '';
    const frag = document.createDocumentFragment();
    items.forEach(item => {
      const row = document.createElement('div');
      row.style.display = 'grid';
      row.style.gridTemplateColumns = '2fr 1fr 1fr 1fr';
      row.style.gap = '8px';
      row.style.padding = '8px';
      row.style.borderBottom = '1px solid var(--mb-gray-200)';
      row.style.fontSize = '13px';
      row.innerHTML = `
        <div style="font-weight:600">${item.tool}</div>
        <div>Commit: $${item.commit.toFixed(2)}</div>
        <div>${item.overageCount > 0 ? `<span style="color:#c62828">Overage: $${item.overage.toFixed(2)}</span>` : 'Overage: $0.00'}</div>
        <div style="font-weight:600;color:var(--mb-blue)">Total: $${item.total.toFixed(2)}</div>
      `;
      frag.appendChild(row);
    });
    const summary = document.createElement('div');
    summary.style.display = 'grid';
    summary.style.gridTemplateColumns = '2fr 1fr 1fr 1fr';
    summary.style.gap = '8px';
    summary.style.padding = '12px 8px';
    summary.style.marginTop = '8px';
    summary.style.borderTop = '2px solid var(--mb-gray-400)';
    summary.style.fontWeight = '600';
    summary.style.fontSize = '14px';
    summary.style.backgroundColor = 'var(--mb-gray-50)';
    summary.innerHTML = `
      <div>Total</div>
      <div>Commit: $${totalCommitCost.toFixed(2)}</div>
      <div>${totalOverageCost > 0 ? `<span style="color:#c62828">Overage: $${totalOverageCost.toFixed(2)}</span>` : 'Overage: $0.00'}</div>
      <div style="color:var(--mb-blue);font-size:16px">$${grandTotal.toFixed(2)}</div>
    `;
    frag.appendChild(summary);
    out.appendChild(frag);
  } catch (e) {
    console.error('Error loading costs:', e);
    out.textContent = 'Unable to load costs: ' + e.message;
  }
}

async function refreshMyBorrows() {
  const user = document.getElementById('my-user').value.trim();
  const out = document.getElementById('my-borrows');
  try {
    if (!user) {
      out.textContent = 'Enter a user to view borrows';
      return;
    }
    const r = await fetch(`/borrows?user=${encodeURIComponent(user)}`);
    if (!r.ok) throw new Error('Load my borrows failed');
    const list = await r.json();
    if (!Array.isArray(list) || list.length === 0) {
      out.textContent = 'No current borrows for this user';
      return;
    }
    out.textContent = '';
    // render rows with return buttons
    const frag = document.createDocumentFragment();
    list.forEach(b => {
      const row = document.createElement('div');
      row.style.display = 'flex';
      row.style.justifyContent = 'space-between';
      row.style.alignItems = 'center';
      row.style.gap = '8px';
      const info = document.createElement('div');
      info.textContent = `${b.borrowed_at}  ${b.user} -> ${b.tool}  (${b.id})`;
      const btn = document.createElement('button');
      btn.className = 'btn';
      btn.textContent = 'Return';
      btn.addEventListener('click', async () => {
        try {
          const rr = await fetch('/licenses/return', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ id: b.id })
          });
          if (!rr.ok) throw new Error('Return failed');
          await refreshStatusAll();
          await refreshBorrows();
          await refreshMyBorrows();
          await refreshCosts();
        } catch (e) {
          alert('Return failed');
        }
      });
      row.appendChild(info);
      row.appendChild(btn);
      frag.appendChild(row);
    });
    out.appendChild(frag);
  } catch (e) {
    out.textContent = 'Unable to load borrows';
  }
}

// Frontend error reporting: capture global errors & unhandled rejections
window.addEventListener('error', (event) => {
  try {
    fetch('/frontend-error', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        message: event.message || 'unknown error',
        stack: event.error && event.error.stack ? event.error.stack : undefined,
        source: event.filename,
        lineno: event.lineno,
        colno: event.colno,
        url: location.href,
        userAgent: navigator.userAgent
      })
    });
  } catch {}
});

window.addEventListener('unhandledrejection', (event) => {
  try {
    const reason = event.reason || {};
    fetch('/frontend-error', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        message: (typeof reason === 'string' ? reason : (reason.message || 'unhandled rejection')),
        stack: reason && reason.stack ? reason.stack : undefined,
        url: location.href,
        userAgent: navigator.userAgent
      })
    });
  } catch {}
});

async function loadOverageCharges() {
  const list = document.getElementById('overage-charges-list');
  list.innerHTML = '<div style="text-align:center;color:var(--mb-gray-700);padding:20px">Loading...</div>';
  
  try {
    const r = await fetch('/overage-charges');
    if (!r.ok) throw new Error('Failed to load charges');
    const data = await r.json();
    const charges = data.charges || [];
    
    if (charges.length === 0) {
      list.innerHTML = '<div style="text-align:center;color:var(--mb-gray-700);padding:12px;background:var(--mb-gray-100);border-radius:6px">No overage charges yet</div>';
      return;
    }
    
    let totalAmount = 0;
    charges.forEach(c => totalAmount += c.amount);
    
    let html = `
      <div style="border:1px solid var(--mb-gray-300);border-radius:6px;overflow:hidden">
        <table style="width:100%;border-collapse:collapse;font-size:13px">
          <thead>
            <tr style="background:var(--mb-gray-100);border-bottom:2px solid var(--mb-gray-300);text-align:left">
              <th style="padding:10px 8px">Date</th>
              <th style="padding:10px 8px">Tool</th>
              <th style="padding:10px 8px">User</th>
              <th style="padding:10px 8px">Borrow ID</th>
              <th style="padding:10px 8px;text-align:right">Amount</th>
            </tr>
          </thead>
          <tbody style="background:var(--mb-white)">
    `;
    
    charges.forEach(c => {
      const date = new Date(c.charged_at).toLocaleString();
      html += `
        <tr style="border-bottom:1px solid var(--mb-gray-200)">
          <td style="padding:8px">${date}</td>
          <td style="padding:8px">${c.tool}</td>
          <td style="padding:8px">${c.user}</td>
          <td style="padding:8px;font-family:monospace;font-size:11px">${c.borrow_id.substring(0,8)}...</td>
          <td style="padding:8px;text-align:right;color:#c62828;font-weight:600">$${c.amount.toFixed(2)}</td>
        </tr>
      `;
    });
    
    html += `
          </tbody>
          <tfoot>
            <tr style="border-top:2px solid var(--mb-gray-400);font-weight:600;background:var(--mb-gray-50)">
              <td colspan="4" style="padding:12px 8px">Total Overage Charges</td>
              <td style="padding:12px 8px;text-align:right;color:var(--mb-blue);font-size:15px">$${totalAmount.toFixed(2)}</td>
            </tr>
          </tfoot>
        </table>
      </div>
    `;
    
    list.innerHTML = html;
  } catch (e) {
    console.error('Error loading overage charges:', e);
    list.innerHTML = '<div style="text-align:center;color:#c62828;padding:20px;background:#fff5f5;border-radius:6px">Failed to load overage charges</div>';
  }
}

// Initialize event listeners and load initial data
document.getElementById('borrow-form').addEventListener('submit', borrow);
document.getElementById('return-form').addEventListener('submit', returnLicense);
document.getElementById('refresh-status').addEventListener('click', refreshStatusAll);
document.getElementById('refresh-borrows').addEventListener('click', refreshBorrows);
document.getElementById('refresh-my-borrows').addEventListener('click', refreshMyBorrows);
document.getElementById('refresh-costs').addEventListener('click', () => {
  refreshCosts();
  loadOverageCharges();
});

refreshStatusAll();
refreshBorrows();
refreshMyBorrows();
refreshCosts();
loadOverageCharges();


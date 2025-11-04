#!/usr/bin/env python3
"""
Multi-Tenant License Server Demo

Demonstrates:
- Subdomain routing (bmw.localhost, mercedes.localhost, audi.localhost)
- Vendor portal (vendor.localhost)
- License provisioning workflow

Run with: python multitenant_demo.py
Then visit:
- http://bmw.localhost:8001       (BMW tenant dashboard)
- http://mercedes.localhost:8001  (Mercedes tenant dashboard)
- http://audi.localhost:8001      (Audi tenant dashboard)
- http://vendor.localhost:8001    (Vector vendor portal)
"""

import os
os.environ["LICENSE_DB_PATH"] = "multitenant_demo.db"

from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from typing import Optional
import logging

from app import db

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI
app = FastAPI(title="Multi-Tenant License Server Demo")

# Pydantic models
class LicenseProvisionRequest(BaseModel):
    tenant_id: str
    product_id: str
    product_name: str
    total: int
    commit_qty: int
    max_overage: int
    commit_price: float = 1000.0
    overage_price_per_license: float = 100.0
    crm_opportunity_id: Optional[str] = None


# Middleware to extract tenant from subdomain
@app.middleware("http")
async def tenant_middleware(request: Request, call_next):
    host = request.headers.get("host", "").split(":")[0]  # Remove port
    subdomain = host.split(".")[0] if "." in host else host
    
    # Determine context: tenant or vendor
    if subdomain in ["bmw", "mercedes", "audi"]:
        request.state.tenant_id = subdomain
        request.state.context = "tenant"
    elif subdomain == "vendor":
        request.state.tenant_id = None
        request.state.context = "vendor"
    else:
        request.state.tenant_id = None
        request.state.context = "unknown"
    
    logger.info(f"Request: {host} → context={request.state.context}, tenant={request.state.tenant_id}")
    response = await call_next(request)
    return response


# ============================================================================
# VENDOR PORTAL ENDPOINTS
# ============================================================================

@app.get("/", response_class=HTMLResponse)
async def root(request: Request):
    """Route based on context (tenant or vendor)"""
    if request.state.context == "vendor":
        return vendor_portal_page()
    elif request.state.context == "tenant":
        return tenant_dashboard_page(request.state.tenant_id)
    else:
        return HTMLResponse("""
        <html>
        <head><title>Multi-Tenant Demo</title></head>
        <body style="font-family: Arial; max-width: 800px; margin: 50px auto;">
            <h1>🚀 Multi-Tenant License Server Demo</h1>
            <p>Please visit one of the following URLs:</p>
            <ul>
                <li><a href="http://bmw.localhost:8001">http://bmw.localhost:8001</a> - BMW Tenant</li>
                <li><a href="http://mercedes.localhost:8001">http://mercedes.localhost:8001</a> - Mercedes Tenant</li>
                <li><a href="http://audi.localhost:8001">http://audi.localhost:8001</a> - Audi Tenant</li>
                <li><a href="http://vendor.localhost:8001">http://vendor.localhost:8001</a> - Vector Vendor Portal</li>
            </ul>
            <p><strong>Note:</strong> These URLs work on localhost. For production, use real subdomains.</p>
        </body>
        </html>
        """)


def vendor_portal_page() -> HTMLResponse:
    """Vendor portal UI"""
    return HTMLResponse("""
    <html>
    <head>
        <title>Vector Vendor Portal</title>
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; background: #f5f5f5; }
            .header { background: #000; color: white; padding: 20px 40px; }
            .header h1 { font-size: 24px; font-weight: 500; }
            .container { max-width: 1200px; margin: 40px auto; padding: 0 20px; }
            .card { background: white; border-radius: 8px; padding: 30px; margin-bottom: 30px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
            .card h2 { font-size: 20px; margin-bottom: 20px; color: #333; }
            table { width: 100%; border-collapse: collapse; }
            th, td { padding: 12px; text-align: left; border-bottom: 1px solid #eee; }
            th { background: #f8f8f8; font-weight: 600; color: #666; font-size: 14px; }
            td { font-size: 14px; color: #333; }
            .btn { background: #000; color: white; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer; font-size: 14px; }
            .btn:hover { background: #333; }
            .badge { display: inline-block; padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: 600; }
            .badge-success { background: #e6f4ea; color: #1e8e3e; }
            .modal { display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 1000; align-items: center; justify-content: center; }
            .modal.show { display: flex; }
            .modal-content { background: white; border-radius: 8px; padding: 30px; max-width: 500px; width: 90%; }
            .form-group { margin-bottom: 20px; }
            .form-group label { display: block; margin-bottom: 8px; font-weight: 600; font-size: 14px; }
            .form-group input, .form-group select { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; font-size: 14px; }
            .btn-secondary { background: #666; }
            .btn-secondary:hover { background: #888; }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>🏢 Vector Informatik GmbH • Vendor Portal</h1>
        </div>
        
        <div class="container">
            <div class="card">
                <h2>📊 My Customers</h2>
                <table id="customers-table">
                    <thead>
                        <tr>
                            <th>Company</th>
                            <th>Tenant ID</th>
                            <th>CRM ID</th>
                            <th>Active Licenses</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr><td colspan="5" style="text-align: center; color: #999;">Loading...</td></tr>
                    </tbody>
                </table>
            </div>
            
            <div class="card">
                <h2>🚀 Quick Actions</h2>
                <button class="btn" onclick="showProvisionModal()">+ Provision New License</button>
            </div>
        </div>
        
        <!-- Provision License Modal -->
        <div id="provision-modal" class="modal">
            <div class="modal-content">
                <h2 style="margin-bottom: 20px;">Provision License to Customer</h2>
                <form id="provision-form">
                    <div class="form-group">
                        <label>Customer</label>
                        <select id="tenant-select" required>
                            <option value="">Select customer...</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Product</label>
                        <select id="product-select" required>
                            <option value="">Select product...</option>
                            <option value="davinci-se|DaVinci Configurator SE">DaVinci Configurator SE</option>
                            <option value="greenhills-multi|Greenhills Multi 8.2">Greenhills Multi 8.2</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Total Licenses</label>
                        <input type="number" id="total-licenses" value="20" required>
                    </div>
                    <div class="form-group">
                        <label>Commit Quantity</label>
                        <input type="number" id="commit-qty" value="5" required>
                    </div>
                    <div class="form-group">
                        <label>Max Overage</label>
                        <input type="number" id="max-overage" value="15" required>
                    </div>
                    <div style="display: flex; gap: 10px; margin-top: 20px;">
                        <button type="submit" class="btn">Provision License</button>
                        <button type="button" class="btn btn-secondary" onclick="hideProvisionModal()">Cancel</button>
                    </div>
                </form>
            </div>
        </div>
        
        <script>
            // Load customers
            async function loadCustomers() {
                try {
                    const response = await fetch('/api/vendor/customers');
                    const data = await response.json();
                    
                    const tbody = document.querySelector('#customers-table tbody');
                    if (data.customers.length === 0) {
                        tbody.innerHTML = '<tr><td colspan="5" style="text-align: center; color: #999;">No customers yet</td></tr>';
                        return;
                    }
                    
                    tbody.innerHTML = data.customers.map(c => `
                        <tr>
                            <td><strong>${c.company_name}</strong></td>
                            <td>${c.tenant_id}</td>
                            <td><code>${c.crm_id}</code></td>
                            <td><span class="badge badge-success">${c.active_licenses} active</span></td>
                            <td>
                                <a href="http://${c.tenant_id}.localhost:8001" target="_blank" style="color: #000; text-decoration: underline;">View Dashboard →</a>
                            </td>
                        </tr>
                    `).join('');
                    
                    // Populate tenant select
                    const select = document.getElementById('tenant-select');
                    select.innerHTML = '<option value="">Select customer...</option>' +
                        data.customers.map(c => `<option value="${c.tenant_id}">${c.company_name} (${c.tenant_id})</option>`).join('');
                } catch (err) {
                    console.error('Error loading customers:', err);
                }
            }
            
            // Show provision modal
            function showProvisionModal() {
                document.getElementById('provision-modal').classList.add('show');
            }
            
            function hideProvisionModal() {
                document.getElementById('provision-modal').classList.remove('show');
            }
            
            // Handle provision form
            document.getElementById('provision-form').addEventListener('submit', async (e) => {
                e.preventDefault();
                
                const tenantId = document.getElementById('tenant-select').value;
                const productValue = document.getElementById('product-select').value;
                const [productId, productName] = productValue.split('|');
                const total = parseInt(document.getElementById('total-licenses').value);
                const commitQty = parseInt(document.getElementById('commit-qty').value);
                const maxOverage = parseInt(document.getElementById('max-overage').value);
                
                try {
                    const response = await fetch('/api/vendor/provision', {
                        method: 'POST',
                        headers: {'Content-Type': 'application/json'},
                        body: JSON.stringify({
                            tenant_id: tenantId,
                            product_id: productId,
                            product_name: productName,
                            total: total,
                            commit_qty: commitQty,
                            max_overage: maxOverage,
                            commit_price: 5000.0,
                            overage_price_per_license: 500.0
                        })
                    });
                    
                    if (response.ok) {
                        alert('✅ License provisioned successfully!');
                        hideProvisionModal();
                        loadCustomers();
                    } else {
                        const error = await response.json();
                        alert('❌ Error: ' + error.detail);
                    }
                } catch (err) {
                    alert('❌ Error provisioning license');
                    console.error(err);
                }
            });
            
            // Load on page load
            loadCustomers();
        </script>
    </body>
    </html>
    """)


def tenant_dashboard_page(tenant_id: str) -> HTMLResponse:
    """Tenant dashboard UI"""
    tenant_info = db.get_all_tenants()
    tenant = next((t for t in tenant_info if t["tenant_id"] == tenant_id), None)
    
    if not tenant:
        raise HTTPException(404, f"Tenant {tenant_id} not found")
    
    return HTMLResponse(f"""
    <html>
    <head>
        <title>{tenant["company_name"]} • License Dashboard</title>
        <style>
            * {{ margin: 0; padding: 0; box-sizing: border-box; }}
            body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; background: #f5f5f5; }}
            .header {{ background: #000; color: white; padding: 20px 40px; }}
            .header h1 {{ font-size: 24px; font-weight: 500; }}
            .header p {{ margin-top: 5px; color: #999; font-size: 14px; }}
            .container {{ max-width: 1200px; margin: 40px auto; padding: 0 20px; }}
            .card {{ background: white; border-radius: 8px; padding: 30px; margin-bottom: 30px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }}
            .card h2 {{ font-size: 20px; margin-bottom: 20px; color: #333; }}
            table {{ width: 100%; border-collapse: collapse; }}
            th, td {{ padding: 12px; text-align: left; border-bottom: 1px solid #eee; }}
            th {{ background: #f8f8f8; font-weight: 600; color: #666; font-size: 14px; }}
            td {{ font-size: 14px; color: #333; }}
            .badge {{ display: inline-block; padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: 600; }}
            .badge-green {{ background: #e6f4ea; color: #1e8e3e; }}
            .badge-blue {{ background: #e3f2fd; color: #1565c0; }}
            .badge-orange {{ background: #fff3e0; color: #e65100; }}
            .vendor-link {{ color: #666; font-size: 12px; text-decoration: none; }}
            .vendor-link:hover {{ text-decoration: underline; }}
        </style>
    </head>
    <body>
        <div class="header">
            <h1>🏢 {tenant["company_name"]} • License Dashboard</h1>
            <p>Tenant ID: {tenant_id} | CRM ID: {tenant["crm_id"]} | <a href="http://vendor.localhost:8001" style="color: #666;">← Back to Vendor Portal</a></p>
        </div>
        
        <div class="container">
            <div class="card">
                <h2>📦 Licensed Products</h2>
                <table id="licenses-table">
                    <thead>
                        <tr>
                            <th>Product</th>
                            <th>Vendor</th>
                            <th>In Use / Total</th>
                            <th>Available</th>
                            <th>Commit / Overage</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr><td colspan="6" style="text-align: center; color: #999;">Loading...</td></tr>
                    </tbody>
                </table>
            </div>
        </div>
        
        <script>
            async function loadLicenses() {{
                try {{
                    const response = await fetch('/api/tenant/licenses');
                    const data = await response.json();
                    
                    const tbody = document.querySelector('#licenses-table tbody');
                    if (data.licenses.length === 0) {{
                        tbody.innerHTML = '<tr><td colspan="6" style="text-align: center; color: #999;">No licenses yet</td></tr>';
                        return;
                    }}
                    
                    tbody.innerHTML = data.licenses.map(l => {{
                        const utilization = (l.borrowed / l.total * 100).toFixed(0);
                        const status = l.borrowed === 0 ? 'idle' : 
                                     l.borrowed <= l.commit ? 'commit' : 'overage';
                        const statusBadge = status === 'idle' ? 'badge-green' :
                                          status === 'commit' ? 'badge-blue' : 'badge-orange';
                        
                        return `
                            <tr>
                                <td><strong>${{l.tool}}</strong></td>
                                <td><span class="vendor-link">${{l.vendor_name || 'Unknown'}}</span></td>
                                <td>${{l.borrowed}} / ${{l.total}} (<strong>${{utilization}}%</strong>)</td>
                                <td><strong>${{l.available}}</strong></td>
                                <td>${{l.commit}} commit / ${{l.max_overage}} overage</td>
                                <td><span class="badge ${{statusBadge}}">${{status.toUpperCase()}}</span></td>
                            </tr>
                        `;
                    }}).join('');
                }} catch (err) {{
                    console.error('Error loading licenses:', err);
                }}
            }}
            
            loadLicenses();
            setInterval(loadLicenses, 5000); // Refresh every 5 seconds
        </script>
    </body>
    </html>
    """)


# ============================================================================
# API ENDPOINTS
# ============================================================================

@app.get("/api/vendor/customers")
async def get_vendor_customers(request: Request):
    """Get all customers for vendor"""
    if request.state.context != "vendor":
        raise HTTPException(403, "Vendor portal only")
    
    customers = db.get_vendor_customers("vector")
    return {"customers": customers}


@app.post("/api/vendor/provision")
async def provision_license(request: Request, provision_request: LicenseProvisionRequest):
    """Provision a new license to a customer"""
    if request.state.context != "vendor":
        raise HTTPException(403, "Vendor portal only")
    
    package_id = db.provision_license_to_tenant(
        vendor_id="vector",
        tenant_id=provision_request.tenant_id,
        product_config={
            "product_id": provision_request.product_id,
            "product_name": provision_request.product_name,
            "total": provision_request.total,
            "commit_qty": provision_request.commit_qty,
            "max_overage": provision_request.max_overage,
            "commit_price": provision_request.commit_price,
            "overage_price_per_license": provision_request.overage_price_per_license,
            "crm_opportunity_id": provision_request.crm_opportunity_id
        }
    )
    
    logger.info(f"Provisioned license package {package_id} to tenant {provision_request.tenant_id}")
    return {"package_id": package_id, "status": "provisioned"}


@app.get("/api/tenant/licenses")
async def get_tenant_licenses(request: Request):
    """Get all licenses for current tenant"""
    if request.state.context != "tenant":
        raise HTTPException(403, "Tenant dashboard only")
    
    licenses = db.get_tenant_licenses(request.state.tenant_id)
    return {"tenant_id": request.state.tenant_id, "licenses": licenses}


# ============================================================================
# STARTUP
# ============================================================================

@app.on_event("startup")
def startup_event():
    """Initialize database and seed demo data"""
    logger.info("Initializing multi-tenant database...")
    db.initialize_database(enable_multitenant=True)
    db.seed_multitenant_demo_data()
    logger.info("✅ Multi-tenant demo ready!")
    logger.info("Visit:")
    logger.info("  - http://bmw.localhost:8001")
    logger.info("  - http://mercedes.localhost:8001")
    logger.info("  - http://audi.localhost:8001")
    logger.info("  - http://vendor.localhost:8001")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)


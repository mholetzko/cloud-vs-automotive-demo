# Customer & Vendor Onboarding Journeys

## Overview

This document outlines the complete onboarding journeys for both customers and vendors, including user management, tenant isolation, subdomain provisioning, and integration with the vendor portal.

---

## 🏢 Customer Onboarding Journey

### Step 1: Initial Registration

**Trigger**: Customer signs up via landing page or vendor referral

**Process**:
1. Customer provides:
   - Company name
   - Contact email
   - Company domain (optional)
   - CRM ID (if referred by vendor)

2. System creates:
   - Pending tenant record
   - Admin user account
   - Verification token

**API Endpoint**:
```http
POST /api/onboarding/customer/register
Content-Type: application/json

{
  "company_name": "Acme Corporation",
  "contact_email": "admin@acme.com",
  "company_domain": "acme.com",
  "crm_id": "CRM-ACME-001",  // Optional, from vendor
  "referral_code": "VECTOR-2024"  // Optional
}
```

**Response**:
```json
{
  "tenant_id": "acme",
  "status": "pending_verification",
  "verification_token": "abc123xyz789",
  "admin_user_id": "user_123",
  "next_steps": [
    "Verify email",
    "Set up admin password",
    "Configure subdomain"
  ]
}
```

### Step 2: Email Verification

**Process**:
1. Customer clicks verification link in email
2. System verifies token
3. Customer sets admin password
4. Tenant status → `verified`

**API Endpoint**:
```http
POST /api/onboarding/customer/verify
Content-Type: application/json

{
  "verification_token": "abc123xyz789",
  "password": "secure_password_123"
}
```

### Step 3: Subdomain Provisioning

**Process**:
1. System generates tenant_id from company name (slugified)
2. Checks subdomain availability
3. Provisions subdomain: `{tenant_id}.permetrix.fly.dev`
4. Updates tenant record with subdomain

**Automatic Process**:
```python
def provision_subdomain(tenant_id: str, company_name: str) -> str:
    """Generate and provision subdomain for tenant"""
    # Generate tenant_id (slugified company name)
    tenant_id = slugify(company_name)  # "Acme Corp" → "acme-corp"
    
    # Check availability
    if tenant_exists(tenant_id):
        tenant_id = f"{tenant_id}-{random_suffix()}"
    
    # Subdomain is automatically available on Fly.io
    subdomain = f"{tenant_id}.permetrix.fly.dev"
    
    # Update tenant record
    update_tenant(tenant_id, domain=subdomain)
    
    return subdomain
```

**Database Update**:
```sql
UPDATE tenants 
SET domain = 'acme.permetrix.fly.dev',
    status = 'active'
WHERE tenant_id = 'acme';
```

### Step 4: User Management

**Admin User Creation**:
- Created during registration
- Has full access to tenant
- Can invite additional users

**Additional Users**:
```http
POST /api/tenant/users/invite
Authorization: Bearer <admin-api-key>
Content-Type: application/json

{
  "email": "developer@acme.com",
  "role": "developer",  // admin, developer, viewer
  "permissions": ["borrow", "return", "view_status"]
}
```

**User Roles**:
- **admin**: Full access, can manage users, configure budgets
- **developer**: Can borrow/return licenses, view status
- **viewer**: Read-only access

### Step 5: Tenant Isolation

**Isolation Mechanisms**:

1. **Database-Level Isolation**:
   ```sql
   -- All queries scoped by tenant_id
   SELECT * FROM licenses WHERE tenant_id = 'acme';
   SELECT * FROM borrows WHERE tenant_id = 'acme';
   SELECT * FROM api_keys WHERE tenant_id = 'acme';
   ```

2. **API Key Isolation**:
   - Each tenant has unique API keys
   - API keys are scoped to tenant_id
   - Keys cannot access other tenants' data

3. **Subdomain-Based Routing**:
   - Middleware extracts tenant from subdomain
   - All requests automatically scoped to tenant
   - No way to access other tenants via subdomain

4. **Row-Level Security**:
   ```python
   def get_tenant_licenses(tenant_id: str):
       """Always filter by tenant_id"""
       with get_connection() as conn:
           cur = conn.cursor()
           cur.execute("""
               SELECT * FROM licenses 
               WHERE tenant_id = ?
           """, (tenant_id,))
           return cur.fetchall()
   ```

### Step 6: Vendor Portal Visibility

**Automatic Process**:
1. When tenant is created, it's visible to all vendors
2. Vendors can see tenant in their customer list
3. Vendors can provision licenses to tenant

**Vendor Portal View**:
```http
GET /api/vendor/customers
Authorization: Bearer <vendor-api-key>

Response:
{
  "customers": [
    {
      "tenant_id": "acme",
      "company_name": "Acme Corporation",
      "domain": "acme.permetrix.fly.dev",
      "status": "active",
      "crm_id": "CRM-ACME-001",
      "active_licenses": 0,
      "created_at": "2025-11-06T10:00:00Z"
    }
  ]
}
```

---

## 🏭 Vendor Onboarding Journey

### Step 1: Vendor Registration

**Trigger**: Vendor signs up via vendor portal or direct contact

**Process**:
1. Vendor provides:
   - Company name
   - Contact email
   - Product catalog (optional, can add later)

2. System creates:
   - Vendor record
   - Admin user account
   - Vendor API key

**API Endpoint**:
```http
POST /api/onboarding/vendor/register
Content-Type: application/json

{
  "vendor_name": "Vector Informatik GmbH",
  "contact_email": "sales@vector.com",
  "products": [
    {
      "product_id": "davinci-se",
      "product_name": "DaVinci Configurator SE"
    }
  ]
}
```

**Response**:
```json
{
  "vendor_id": "vector",
  "status": "pending_verification",
  "verification_token": "vendor_abc123",
  "admin_user_id": "vendor_user_123",
  "api_key": "vnd_live_...",  // Vendor API key
  "next_steps": [
    "Verify email",
    "Set up admin password",
    "Configure vendor portal"
  ]
}
```

### Step 2: Email Verification

**Process**:
1. Vendor clicks verification link
2. Sets admin password
3. Vendor status → `active`

### Step 3: Subdomain Provisioning

**Process**:
1. System provisions `vendor.permetrix.fly.dev` (shared portal)
2. OR vendor-specific subdomain: `{vendor_id}.vendor.permetrix.fly.dev`
3. Updates vendor record

**Option A: Shared Vendor Portal** (Recommended)
- Single subdomain: `vendor.permetrix.fly.dev`
- All vendors access same portal
- Authentication via vendor API key

**Option B: Vendor-Specific Subdomain**
- Each vendor gets: `vector.vendor.permetrix.fly.dev`
- More isolation, but more complex

### Step 4: User Management

**Vendor Users**:
- Admin users can invite team members
- Roles: admin, sales, support

**User Roles**:
- **admin**: Full access, can provision licenses, manage customers
- **sales**: Can view customers, provision licenses
- **support**: Read-only access to customer data

### Step 5: Vendor Isolation

**Isolation Mechanisms**:

1. **API Key-Based Isolation**:
   ```python
   def get_vendor_customers(vendor_id: str):
       """Get customers who have this vendor's licenses"""
       with get_connection() as conn:
           cur = conn.cursor()
           cur.execute("""
               SELECT DISTINCT t.* 
               FROM tenants t
               JOIN license_packages lp ON t.tenant_id = lp.tenant_id
               WHERE lp.vendor_id = ?
           """, (vendor_id,))
           return cur.fetchall()
   ```

2. **Product-Level Isolation**:
   - Vendors can only see customers with their products
   - Vendors can only provision their own products
   - License packages are scoped by vendor_id

3. **Vendor API Key**:
   - Each vendor has unique API key
   - Key identifies vendor in all requests
   - Stored in `vendors` table

### Step 6: Customer Visibility & Product Provisioning

**View Customers**:
```http
GET /api/vendor/customers
Authorization: Bearer <vendor-api-key>

Response:
{
  "customers": [
    {
      "tenant_id": "acme",
      "company_name": "Acme Corporation",
      "domain": "acme.permetrix.fly.dev",
      "status": "active",
      "my_products": [
        {
          "product_id": "davinci-se",
          "product_name": "DaVinci Configurator SE",
          "total_licenses": 20,
          "active_licenses": 5
        }
      ]
    }
  ]
}
```

**Provision Products to Customer**:
```http
POST /api/vendor/provision
Authorization: Bearer <vendor-api-key>
Content-Type: application/json

{
  "tenant_id": "acme",
  "product_id": "davinci-se",
  "product_name": "DaVinci Configurator SE",
  "total": 20,
  "commit_qty": 5,
  "max_overage": 15,
  "commit_price": 5000.0,
  "overage_price_per_license": 500.0,
  "crm_opportunity_id": "CRM-ACME-001"
}
```

---

## 🔐 Security & Isolation Guarantees

### Customer Isolation

1. **Subdomain Routing**: 
   - `acme.permetrix.fly.dev` → tenant_id = "acme"
   - Middleware enforces tenant context
   - No way to access other tenants via subdomain

2. **API Key Scoping**:
   ```python
   def validate_api_key(api_key: str, tenant_id: str) -> bool:
       """API key must belong to tenant"""
       with get_connection() as conn:
           cur = conn.cursor()
           cur.execute("""
               SELECT key_id FROM api_keys
               WHERE key_hash = ? AND tenant_id = ?
           """, (hash_key(api_key), tenant_id))
           return cur.fetchone() is not None
   ```

3. **Database Queries**:
   - All queries MUST include `WHERE tenant_id = ?`
   - No global queries without tenant filter
   - Database constraints enforce uniqueness per tenant

4. **Session Isolation**:
   - User sessions scoped to tenant
   - Cannot switch tenants within session
   - Logout required to access different tenant

### Vendor Isolation

1. **API Key Authentication**:
   - Vendor API key identifies vendor
   - All vendor requests require valid API key
   - Keys stored securely (hashed)

2. **Product Scoping**:
   - Vendors can only see customers with their products
   - Vendors can only provision their own products
   - License packages linked to vendor_id

3. **Customer Data Access**:
   - Vendors see aggregated data only
   - No access to customer API keys
   - No access to customer user accounts

---

## 📊 Database Schema

### Users Table

```sql
CREATE TABLE users (
    user_id TEXT PRIMARY KEY,
    tenant_id TEXT,  -- NULL for vendor users
    vendor_id TEXT,  -- NULL for customer users
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL,  -- admin, developer, viewer, vendor_admin, vendor_sales
    status TEXT DEFAULT 'active',
    created_at TEXT NOT NULL,
    last_login_at TEXT,
    FOREIGN KEY(tenant_id) REFERENCES tenants(tenant_id),
    FOREIGN KEY(vendor_id) REFERENCES vendors(vendor_id),
    CHECK((tenant_id IS NOT NULL AND vendor_id IS NULL) OR 
          (tenant_id IS NULL AND vendor_id IS NOT NULL))
);
```

### Tenants Table (Enhanced)

```sql
CREATE TABLE tenants (
    tenant_id TEXT PRIMARY KEY,
    company_name TEXT NOT NULL,
    domain TEXT UNIQUE,  -- acme.permetrix.fly.dev
    crm_id TEXT UNIQUE,
    status TEXT DEFAULT 'pending_verification',  -- pending, verified, active, suspended
    verification_token TEXT,
    verified_at TEXT,
    created_at TEXT NOT NULL,
    admin_user_id TEXT,  -- First admin user
    FOREIGN KEY(admin_user_id) REFERENCES users(user_id)
);
```

### Vendors Table (Enhanced)

```sql
CREATE TABLE vendors (
    vendor_id TEXT PRIMARY KEY,
    vendor_name TEXT NOT NULL,
    contact_email TEXT NOT NULL,
    api_key_hash TEXT NOT NULL UNIQUE,
    status TEXT DEFAULT 'pending_verification',
    verification_token TEXT,
    verified_at TEXT,
    created_at TEXT NOT NULL,
    admin_user_id TEXT,
    FOREIGN KEY(admin_user_id) REFERENCES users(user_id)
);
```

---

## 🚀 Implementation Checklist

### Customer Onboarding

- [ ] Registration endpoint (`POST /api/onboarding/customer/register`)
- [ ] Email verification endpoint (`POST /api/onboarding/customer/verify`)
- [ ] Subdomain provisioning (automatic on verification)
- [ ] User management endpoints
- [ ] API key generation for tenant
- [ ] Tenant isolation middleware
- [ ] Vendor portal visibility

### Vendor Onboarding

- [ ] Registration endpoint (`POST /api/onboarding/vendor/register`)
- [ ] Email verification endpoint (`POST /api/onboarding/vendor/verify`)
- [ ] Vendor portal subdomain setup
- [ ] Vendor user management
- [ ] Product catalog management
- [ ] Customer visibility endpoint
- [ ] License provisioning endpoint

### Security

- [ ] API key hashing and validation
- [ ] Tenant-scoped database queries
- [ ] Vendor-scoped queries
- [ ] Session management
- [ ] Rate limiting per tenant
- [ ] Audit logging

---

## 📝 Example Workflows

### Customer Onboarding Flow

```
1. Customer registers → Tenant created (status: pending)
2. Email sent with verification link
3. Customer clicks link → Sets password → Tenant verified
4. System provisions subdomain: acme.permetrix.fly.dev
5. Admin user created and logged in
6. Customer appears in vendor portal
7. Vendor provisions licenses
8. Customer can start using licenses
```

### Vendor Onboarding Flow

```
1. Vendor registers → Vendor record created (status: pending)
2. Email sent with verification link
3. Vendor clicks link → Sets password → Vendor verified
4. Vendor portal accessible at vendor.permetrix.fly.dev
5. Vendor adds products to catalog
6. Vendor views customer list
7. Vendor provisions licenses to customers
8. Customers can use vendor's products
```

---

## 🔍 Testing Isolation

### Test Customer Isolation

```bash
# Test 1: API key from acme cannot access globex data
curl -H "Authorization: Bearer <acme-api-key>" \
     https://acme.permetrix.fly.dev/licenses/status
# Should return only acme's licenses

curl -H "Authorization: Bearer <acme-api-key>" \
     https://globex.permetrix.fly.dev/licenses/status
# Should return 403 Forbidden

# Test 2: Subdomain routing enforces tenant
curl https://acme.permetrix.fly.dev/licenses/status
# Should return acme's data (even without API key for web UI)

curl https://globex.permetrix.fly.dev/licenses/status
# Should return globex's data
```

### Test Vendor Isolation

```bash
# Test: Vendor can only see customers with their products
curl -H "Authorization: Bearer <vector-api-key>" \
     https://vendor.permetrix.fly.dev/api/vendor/customers
# Should return only customers with Vector products

# Test: Vendor cannot access customer API keys
curl -H "Authorization: Bearer <vector-api-key>" \
     https://vendor.permetrix.fly.dev/api/vendor/customers/acme/keys
# Should return 403 Forbidden
```


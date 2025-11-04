# Tenant Authentication & API Key Design

## 🎯 The Problem

**Current State**: Anyone with the URL `acme.cloudlicenses.com` can make requests.

**Security Gap**: 
- HMAC signature prevents unauthorized *API* access
- But doesn't prevent unauthorized *tenant* access
- Need to authenticate **which customer** is making the request

---

## 🔐 Solution: Multi-Layer Authentication

### Layer 1: **API Keys per Tenant** (Customer Authentication)
**What**: Each customer (Acme, Globex, Initech) gets unique API key(s)  
**Purpose**: Proves "I am Acme Corporation"  
**Generated**: By vendor via portal when provisioning licenses  
**Stored**: Customer's environment variables / secret management

### Layer 2: **Vendor Secret per Product** (Application Authentication)
**What**: Each vendor product has embedded secret (already implemented)  
**Purpose**: Proves "I am the official ECU Dev Suite application"  
**Generated**: By vendor when building their application  
**Stored**: Compiled into the vendor's client library (obfuscated)

### Layer 3: **Combined Signature** (Request Authentication)
**What**: HMAC includes API key + vendor secret + request data  
**Purpose**: Proves "I am Acme's ECU Dev Suite making this specific request"  
**Validated**: Server checks both API key and HMAC

---

## 🏗️ Recommended Architecture

### Flow: Vendor → Customer → Application

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. VENDOR PROVISIONS LICENSES                                    │
│    (via Vendor Portal)                                           │
└─────────────────────────────────────────────────────────────────┘
         │
         │ TechVendor sells 20 ECU Dev Suite licenses to Acme
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. SYSTEM GENERATES API KEY                                      │
│    API Key: acme_live_pk_abc123xyz789...                        │
│    Tenant ID: acme                                               │
│    Product: ECU Development Suite                                │
└─────────────────────────────────────────────────────────────────┘
         │
         │ Vendor emails/shares API key with Acme IT team
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. CUSTOMER CONFIGURES ENVIRONMENT                               │
│    Acme IT sets: LICENSE_SERVER_URL=https://acme.cloudlicenses  │
│                  LICENSE_API_KEY=acme_live_pk_abc123xyz789...   │
└─────────────────────────────────────────────────────────────────┘
         │
         │ Developers install ECU Dev Suite on their machines
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. APPLICATION MAKES REQUEST                                     │
│    ECU Dev Suite starts → reads env vars → calls license server │
└─────────────────────────────────────────────────────────────────┘
         │
         │ Request includes:
         │ - API Key (proves "I'm Acme")
         │ - HMAC signature (proves "I'm ECU Dev Suite")
         │ - Timestamp (prevents replay)
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. SERVER VALIDATES REQUEST                                      │
│    ✓ API key valid and belongs to tenant "acme"?               │
│    ✓ HMAC signature valid for vendor "techvendor"?              │
│    ✓ Timestamp fresh (< 5 minutes)?                             │
│    ✓ Tenant "acme" has licenses for this product?               │
│    ✓ License available?                                          │
│    → ✅ Success or ❌ Reject                                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔑 API Key Design

### Format
```
{tenant}_{environment}_{type}_{random}

Examples:
- acme_live_pk_a1b2c3d4e5f6...        (Production)
- acme_test_pk_x9y8z7w6v5u4...        (Testing)
- globex_live_pk_m3n4o5p6q7r8...      (Production)
```

### Structure
| Part | Example | Purpose |
|------|---------|---------|
| Tenant | `acme` | Quick lookup which customer |
| Environment | `live` / `test` | Separate prod/dev keys |
| Type | `pk` (private key) | Indicates this is secret |
| Random | `abc123...` | Cryptographically random |

### Storage (Server-Side)
```sql
CREATE TABLE api_keys (
    id TEXT PRIMARY KEY,              -- acme_live_pk_abc123...
    tenant_id TEXT NOT NULL,          -- acme
    environment TEXT DEFAULT 'live',  -- live, test, dev
    name TEXT,                        -- "Production Key 1"
    created_at TEXT NOT NULL,
    expires_at TEXT,                  -- optional expiration
    last_used_at TEXT,
    status TEXT DEFAULT 'active',     -- active, revoked, expired
    scopes TEXT,                      -- JSON: ["borrow", "return", "status"]
    FOREIGN KEY (tenant_id) REFERENCES tenants(tenant_id)
);

CREATE INDEX idx_api_keys_tenant ON api_keys(tenant_id);
CREATE INDEX idx_api_keys_status ON api_keys(status);
```

---

## 🔐 Updated HMAC Signature

### Current (Incomplete)
```python
payload = f"{tool}|{user}|{timestamp}"
signature = hmac(VENDOR_SECRET, payload)
```

### New (Secure)
```python
# Signature includes API key to bind it to the tenant
payload = f"{tool}|{user}|{timestamp}|{api_key}"
signature = hmac(VENDOR_SECRET, payload)

# Send in request
headers = {
    "Authorization": f"Bearer {api_key}",    # WHO (tenant)
    "X-Signature": signature,                 # WHAT (vendor product)
    "X-Timestamp": timestamp,                 # WHEN (freshness)
    "X-Vendor-ID": "techvendor"              # FROM (vendor)
}
```

### Server Validation
```python
@app.post("/licenses/borrow")
def borrow(req: BorrowRequest, request: Request):
    # 1. Extract API key
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(403, "Missing API key")
    
    api_key = auth_header.split("Bearer ")[1]
    
    # 2. Validate API key and get tenant
    tenant = validate_api_key(api_key)
    if not tenant:
        raise HTTPException(403, "Invalid API key")
    
    # 3. Validate HMAC signature (includes API key in payload)
    signature = request.headers.get("X-Signature")
    timestamp = request.headers.get("X-Timestamp")
    vendor_id = request.headers.get("X-Vendor-ID", "techvendor")
    
    # Reconstruct payload (now includes API key)
    payload = f"{req.tool}|{req.user}|{timestamp}|{api_key}"
    expected_sig = hmac(VENDOR_SECRETS[vendor_id], payload)
    
    if not hmac.compare_digest(signature, expected_sig):
        raise HTTPException(403, "Invalid signature")
    
    # 4. Check tenant has license for this product
    if not tenant_has_license(tenant.id, req.tool):
        raise HTTPException(403, f"Tenant {tenant.name} does not have license for {req.tool}")
    
    # 5. Proceed with borrow...
    ok, is_overage = borrow_license(tenant.id, req.tool, req.user, ...)
```

---

## 🎯 Key Management Flows

### Flow 1: Vendor Provisions New Customer

**Vendor Portal** (`/vendor`):
1. Vendor clicks "Provision License to Acme"
2. Selects product: "ECU Development Suite"
3. Sets quantities: 20 total, 5 commit, 15 overage
4. System **automatically generates** API key: `acme_live_pk_abc123...`
5. Display API key to vendor (only shown once!)
6. Vendor shares API key with Acme IT via secure channel (encrypted email, vault)

**Alternative (Better)**: Customer Self-Service
- Acme IT logs into their customer portal
- Clicks "Generate API Key" 
- Enters description: "Production Key 1"
- System generates and displays key (only once!)
- Customer copies to their secret management system

### Flow 2: Customer Configures Application

**Acme IT Team**:
```bash
# Option A: Environment Variables
export LICENSE_SERVER_URL="https://acme.cloudlicenses.com"
export LICENSE_API_KEY="acme_live_pk_abc123..."

# Option B: Config File (json/yaml)
{
  "license_server": {
    "url": "https://acme.cloudlicenses.com",
    "api_key": "acme_live_pk_abc123..."
  }
}

# Option C: Secret Management (Vault, AWS Secrets Manager, Azure Key Vault)
vault write secret/license-server \
  url="https://acme.cloudlicenses.com" \
  api_key="acme_live_pk_abc123..."
```

### Flow 3: Application Uses Key

**Client Library Update**:
```python
# Updated Python client
class LicenseClient:
    def __init__(self, base_url: str, api_key: str, enable_security: bool = True):
        self.base_url = base_url
        self.api_key = api_key
        self.enable_security = enable_security
    
    def borrow(self, tool: str, user: str) -> LicenseHandle:
        if self.enable_security:
            timestamp = str(int(time.time()))
            # Include API key in HMAC payload
            payload = f"{tool}|{user}|{timestamp}|{self.api_key}"
            signature = self._generate_signature(payload)
            
            headers = {
                "Authorization": f"Bearer {self.api_key}",  # NEW!
                "X-Signature": signature,
                "X-Timestamp": timestamp,
                "X-Vendor-ID": self.VENDOR_ID
            }
        else:
            headers = {}
        
        response = self.session.post(
            f"{self.base_url}/licenses/borrow",
            json={"tool": tool, "user": user},
            headers=headers
        )
        # ...
```

**Application Code**:
```python
import os
from license_client import LicenseClient

# Read from environment
api_key = os.getenv("LICENSE_API_KEY")
server_url = os.getenv("LICENSE_SERVER_URL", "https://acme.cloudlicenses.com")

# Create client with API key
client = LicenseClient(server_url, api_key)

# Use as before
with client.borrow("ECU Development Suite", "alice") as license:
    print(f"Got license: {license.id}")
```

---

## 🔐 Security Benefits

### ✅ Solves Your Problem
- **Without API key**: Can't access Acme's tenant, even with URL
- **With stolen API key**: Can't generate valid HMAC without vendor secret
- **With stolen vendor secret**: Can't authenticate without valid API key
- **With both stolen**: Can make requests, BUT...
  - Rate limiting kicks in
  - Behavioral analysis flags unusual patterns
  - Can revoke API key instantly

### ✅ Defense in Depth
1. **API Key** = Tenant authentication (who)
2. **Vendor Secret** = Application authentication (what)
3. **HMAC Signature** = Request authentication (proof)
4. **Timestamp** = Replay prevention (when)
5. **Rate Limiting** = Abuse prevention (how much)
6. **Audit Logs** = Forensics (why)

### ✅ Operational Benefits
- **Revocation**: Disable API key instantly (no app recompile)
- **Rotation**: Generate new keys without downtime
- **Monitoring**: Track which keys are used, when, by whom
- **Scoping**: Limit keys to specific operations (read-only, etc.)
- **Testing**: Separate test/prod keys with different quotas

---

## 🚀 Implementation Priority

### Phase 1: Minimum Viable Security (Current Demo)
- ✅ HMAC with vendor secret
- ✅ Timestamp validation
- ✅ Rate limiting
- ⚠️  **Missing**: Tenant authentication (anyone with URL can access)

### Phase 2: Production-Ready (Recommended)
- ✅ API keys per tenant
- ✅ HMAC includes API key
- ✅ Server validates both
- ✅ Vendor portal generates keys
- ✅ Customer portal for key management

### Phase 3: Enterprise-Grade (Optional)
- ✅ Key rotation policies
- ✅ Scope-based permissions
- ✅ Integration with HashiCorp Vault / AWS Secrets Manager
- ✅ Customer SSO (SAML/OAuth) for portal access
- ✅ Audit log streaming to customer SIEM

---

## 🎯 Demo Recommendation

For your **automotive presentation**, show:

### Current State (Good for MVP)
```
"HMAC prevents API abuse, but doesn't prevent tenant access.
Anyone with acme.cloudlicenses.com can connect."
```

### Production Architecture (What's needed)
```
"Add API keys for tenant authentication:
- Vendor provisions licenses → generates API key
- Customer stores key securely
- Application includes key in every request
- Server validates: API key + HMAC signature + timestamp
→ Now only Acme with valid key can access acme.cloudlicenses.com"
```

### Show the Gap Visually
```
❌ Current:  URL → [HMAC] → Server
✅ Production: URL + API_KEY → [HMAC(API_KEY)] → Server
```

---

## 📋 Next Steps

Want me to implement **Phase 2** (API key authentication)?

**Time estimate**: ~1 hour
- Add `api_keys` table to database
- Update HMAC to include API key
- Generate keys in vendor portal
- Update client libraries to accept API key
- Update demo script to show API key validation
- Add visual diagram to `/security-demo` page

**This completes the security story for automotive demos!** 🎬


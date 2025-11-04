# Tenant Authentication & Access Control

## 🔐 The Core Problem

**Scenario**: Mercedes has their tenant at `mercedes.cloudlicenses.com`

**Question**: How do we prevent:
1. Random people accessing Mercedes' tenant URL?
2. Unauthorized applications using the API?
3. Other customers (BMW, Audi) accessing Mercedes' data?

---

## 🎯 Complete Solution: 3-Layer Authentication

### Layer 1: **Tenant API Keys** (Customer-Level Auth)
### Layer 2: **HMAC Vendor Secrets** (Application-Level Auth)
### Layer 3: **User-Level Tokens** (End-User Auth) [Optional]

---

## 📊 Authentication Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     AUTHENTICATION LAYERS                        │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ 1️⃣  TENANT API KEY (Customer Level)                              │
│                                                                   │
│  Mercedes generates API key in their tenant portal:              │
│    api_key_mercedes_prod_abc123...                              │
│                                                                   │
│  ✅ Validates: This request is from Mercedes (not BMW/Audi)     │
│  ✅ Prevents: Random internet users accessing the tenant         │
│  ✅ Scope: Tenant-specific (can't access other tenants' data)   │
└──────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────┐
│ 2️⃣  VENDOR SECRET (Application Level)                            │
│                                                                   │
│  Vector embeds secret in DaVinci Configurator client library:   │
│    vendor_secret_vector_davinci_xyz789...                       │
│                                                                   │
│  ✅ Validates: This is genuine Vector software (not a fake app) │
│  ✅ Prevents: Custom scripts/curl accessing the API             │
│  ✅ Scope: Product-specific (DaVinci ≠ ASAP2 ≠ Teams)          │
└──────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────┐
│ 3️⃣  USER TOKEN (End-User Level) [OPTIONAL]                       │
│                                                                   │
│  Alice logs into DaVinci, gets session token:                   │
│    user_token_alice_session_123...                              │
│                                                                   │
│  ✅ Validates: This is Alice (not Bob)                          │
│  ✅ Prevents: Sharing credentials between users                  │
│  ✅ Scope: User-specific (can track individual usage)           │
└──────────────────────────────────────────────────────────────────┘
```

---

## 🔑 Layer 1: Tenant API Keys (PRIMARY SOLUTION)

### How It Works

#### Step 1: Tenant Generates API Key

**Mercedes admin logs into their portal:**
```
https://mercedes.cloudlicenses.com/admin/api-keys
```

**Clicks "Generate API Key":**
```
Name: Production Environment
Scopes: license:read, license:write
Expiration: Never (or 1 year)

Generated Key:
clsk_mercedes_prod_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0
```

#### Step 2: Mercedes Configures Applications

**Mercedes distributes this API key to their development team:**

**Option A: Environment Variable**
```bash
# Mercedes sets in their CI/CD
export LICENSE_API_KEY="clsk_mercedes_prod_a1b2c3d4..."
```

**Option B: Configuration File**
```yaml
# mercedes_config.yaml
license_server:
  url: https://mercedes.cloudlicenses.com
  api_key: clsk_mercedes_prod_a1b2c3d4...
```

**Option C: Secure Vault (Production)**
```bash
# Mercedes stores in AWS Secrets Manager / Azure Key Vault
aws secretsmanager get-secret-value --secret-id license-api-key
```

#### Step 3: Application Includes Both Keys

**Vector's DaVinci Configurator (running at Mercedes):**

```python
from license_client import LicenseClient

# Layer 1: Tenant API Key (provided by Mercedes)
tenant_api_key = os.getenv("LICENSE_API_KEY")  # Mercedes' secret

# Layer 2: Vendor Secret (embedded in DaVinci by Vector)
VENDOR_SECRET = "vector_davinci_secret_..."  # Vector's secret

client = LicenseClient(
    base_url="https://mercedes.cloudlicenses.com",
    api_key=tenant_api_key,  # ← NEW: Tenant authentication
    vendor_secret=VENDOR_SECRET  # ← Existing: Application authentication
)

license = client.borrow("DaVinci Configurator SE", "alice")
```

#### Step 4: Server Validates Both

**On the license server:**

```python
@app.post("/licenses/borrow")
def borrow(req: BorrowRequest, request: Request):
    # Layer 1: Validate Tenant API Key
    api_key = request.headers.get("Authorization")  # "Bearer clsk_mercedes_..."
    tenant = validate_api_key(api_key)  # Returns "mercedes"
    
    if not tenant:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    # Layer 2: Validate HMAC Signature
    signature = request.headers.get("X-Signature")
    vendor_id = request.headers.get("X-Vendor-ID")  # "vector"
    
    if not validate_hmac(signature, vendor_id, req.tool, req.user):
        raise HTTPException(status_code=403, detail="Invalid signature")
    
    # Layer 3: Check License Availability (for this tenant)
    license = get_license(tenant_id=tenant, tool=req.tool)
    
    if license.borrowed >= license.total:
        raise HTTPException(status_code=409, detail="No licenses available")
    
    # Success! Both keys valid, license available
    return borrow_license(tenant, req.tool, req.user)
```

---

## 🏢 How Vendor Secrets Are Generated

### Option 1: **Vendor Self-Service Portal** ✅ RECOMMENDED

**Vector logs into vendor portal:**
```
https://cloudlicenses.com/vendor/vector
```

**Creates a new product:**
```
Product: DaVinci Configurator SE
Target Customers: Mercedes, BMW, Audi

Click "Generate Vendor Secret"
→ vendor_secret_vector_davinci_abc123xyz789...
```

**Vector embeds this secret in their application:**
```cpp
// In Vector's DaVinci Configurator source code
const std::string VENDOR_SECRET = "vendor_secret_vector_davinci_abc123xyz789...";
```

**Vector compiles and ships DaVinci to customers (Mercedes, BMW, Audi)**

### Option 2: **Cloud License Platform Generates**

**When Vector registers their product:**
1. Vector provides product details (name, version, etc.)
2. Platform generates unique secret
3. Vector downloads secret via secure channel
4. Vector embeds in application binary (obfuscated)

### Option 3: **Vector Generates, Platform Validates**

**Vector generates their own secret:**
```bash
# Vector runs locally
openssl rand -hex 32
→ 8f3a2d9c1b7e6a5f4d3c2b1a0987654321fedcba
```

**Vector registers this secret with the platform:**
- Platform stores hash (not plaintext)
- Platform validates incoming HMAC signatures against this hash

---

## 🔒 Security Properties

### Tenant API Key
| Property | Value |
|----------|-------|
| **Scope** | Single tenant (Mercedes only) |
| **Distribution** | Mercedes admin → Mercedes developers |
| **Storage** | Environment variable, config file, vault |
| **Rotation** | Can be rotated without app recompilation |
| **Revocation** | Instant via admin portal |
| **Auditability** | All API calls logged with key ID |

### Vendor Secret
| Property | Value |
|----------|-------|
| **Scope** | Single product (DaVinci only) |
| **Distribution** | Vector → Compiled into binary |
| **Storage** | Obfuscated in binary, protected at runtime |
| **Rotation** | Requires app update (less frequent) |
| **Revocation** | Vendor can deprecate old versions |
| **Auditability** | Per-product metrics and alerts |

---

## 🚀 Implementation Steps

### Phase 1: Add Tenant API Keys (NEW)

#### 1. Database Schema
```sql
CREATE TABLE api_keys (
    id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL,
    key_hash TEXT NOT NULL,  -- SHA256 of actual key
    name TEXT,
    scopes TEXT,  -- JSON: ["license:read", "license:write"]
    created_at TIMESTAMP,
    expires_at TIMESTAMP,
    last_used_at TIMESTAMP,
    FOREIGN KEY (tenant_id) REFERENCES tenants(tenant_id)
);

CREATE INDEX idx_api_keys_tenant ON api_keys(tenant_id);
```

#### 2. API Key Generation Endpoint
```python
@app.post("/admin/api-keys")
def create_api_key(req: CreateAPIKeyRequest, current_tenant: str):
    # Generate secure API key
    key = "clsk_" + current_tenant + "_" + secrets.token_urlsafe(32)
    key_hash = hashlib.sha256(key.encode()).hexdigest()
    
    # Store hash (not plaintext)
    db.execute("""
        INSERT INTO api_keys (id, tenant_id, key_hash, name, scopes, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (uuid4(), current_tenant, key_hash, req.name, json.dumps(req.scopes), now()))
    
    # Return plaintext key ONCE (user must save it)
    return {"api_key": key, "warning": "Save this key now - it won't be shown again!"}
```

#### 3. Validation Middleware
```python
async def validate_api_key(request: Request) -> str:
    """Returns tenant_id if valid, raises 401 if invalid"""
    auth_header = request.headers.get("Authorization")
    
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing API key")
    
    key = auth_header.split("Bearer ")[1]
    key_hash = hashlib.sha256(key.encode()).hexdigest()
    
    # Lookup in database
    result = db.execute("""
        SELECT tenant_id, expires_at, scopes
        FROM api_keys
        WHERE key_hash = ?
        AND (expires_at IS NULL OR expires_at > ?)
    """, (key_hash, datetime.utcnow())).fetchone()
    
    if not result:
        raise HTTPException(status_code=401, detail="Invalid or expired API key")
    
    # Update last_used_at
    db.execute("UPDATE api_keys SET last_used_at = ? WHERE key_hash = ?", (datetime.utcnow(), key_hash))
    
    return result["tenant_id"]
```

#### 4. Update Client Libraries
```python
class LicenseClient:
    def __init__(self, base_url: str, api_key: str, enable_security: bool = True):
        self.base_url = base_url
        self.api_key = api_key  # NEW: Tenant API key
        self.enable_security = enable_security
        self.VENDOR_SECRET = "techvendor_secret_..."  # Existing
    
    def borrow(self, tool: str, user: str):
        headers = {
            "Authorization": f"Bearer {self.api_key}",  # NEW: Tenant auth
            "Content-Type": "application/json"
        }
        
        # Add HMAC signature if enabled
        if self.enable_security:
            timestamp = str(int(time.time()))
            signature = self._generate_signature(tool, user, timestamp)
            headers.update({
                "X-Signature": signature,
                "X-Timestamp": timestamp,
                "X-Vendor-ID": "techvendor"
            })
        
        response = requests.post(
            f"{self.base_url}/licenses/borrow",
            json={"tool": tool, "user": user},
            headers=headers
        )
        return response
```

### Phase 2: Vendor Secret Management (EXISTING - ENHANCE)

Already implemented! Just need to document the workflow:

1. **Vector generates secret** (or platform generates it)
2. **Vector embeds in DaVinci** (compile-time constant)
3. **Platform validates HMAC** (already working)

---

## 🎯 Real-World Example

### Scenario: Mercedes Deploys Vector DaVinci

#### 1. Mercedes Admin Setup
```bash
# Mercedes admin logs into their portal
https://mercedes.cloudlicenses.com/admin

# Generates API key for production
Name: "Production DaVinci Fleet"
Key: clsk_mercedes_prod_8f3a2d9c1b7e6a5f...

# Mercedes stores in AWS Secrets Manager
aws secretsmanager create-secret \
  --name license-api-key \
  --secret-string "clsk_mercedes_prod_8f3a2d9c1b7e6a5f..."
```

#### 2. Mercedes DevOps Team
```yaml
# kubernetes/davinci-deployment.yaml
apiVersion: v1
kind: Deployment
spec:
  template:
    spec:
      containers:
      - name: davinci
        image: vector/davinci:latest
        env:
        - name: LICENSE_API_KEY
          valueFrom:
            secretKeyRef:
              name: license-server-key
              key: api_key
        - name: LICENSE_SERVER_URL
          value: "https://mercedes.cloudlicenses.com"
```

#### 3. Vector's DaVinci Application
```cpp
// Compiled into DaVinci by Vector
const std::string VENDOR_SECRET = "vector_davinci_secret_xyz789...";
const std::string VENDOR_ID = "vector";

// At runtime, Mercedes provides API key
std::string api_key = std::getenv("LICENSE_API_KEY");

LicenseClient client(
    "https://mercedes.cloudlicenses.com",
    api_key  // Mercedes' tenant key
);

// HMAC signature automatically added using VENDOR_SECRET
auto license = client.borrow("DaVinci Configurator SE", "alice");
```

#### 4. License Server Validation
```python
# Request arrives at server
Authorization: Bearer clsk_mercedes_prod_8f3a2d9c1b7e6a5f...
X-Signature: abc123def456...
X-Timestamp: 1699564800
X-Vendor-ID: vector

# Server validates:
1. API key → tenant_id = "mercedes" ✅
2. HMAC signature → vendor = "vector", product = "DaVinci" ✅
3. Check Mercedes' license pool for DaVinci ✅
4. Return license ✅
```

---

## 🔐 Security Best Practices

### For Customers (Mercedes)

1. **Store API keys in vault** (not in code!)
2. **Use separate keys per environment** (dev, staging, prod)
3. **Rotate keys annually** (or after employee departures)
4. **Monitor API key usage** (detect anomalies)
5. **Revoke unused keys** (principle of least privilege)

### For Vendors (Vector)

1. **Obfuscate secrets in binaries** (use string encryption)
2. **Use per-product secrets** (DaVinci ≠ ASAP2)
3. **Consider certificate pinning** (prevent MITM)
4. **Implement secret rotation** (deprecate old versions)
5. **Monitor for secret leakage** (GitHub scanning)

### For Platform (Cloud License Server)

1. **Store key hashes only** (never plaintext)
2. **Rate limit API calls** (prevent brute-force)
3. **Log all access** (audit trail)
4. **Alert on anomalies** (unusual usage patterns)
5. **Implement mTLS** (Layer 3 security)

---

## 📋 Summary

| Question | Answer |
|----------|--------|
| **Who generates tenant API keys?** | Customer (Mercedes) via admin portal |
| **Who generates vendor secrets?** | Vendor (Vector) or platform (on behalf of vendor) |
| **How are API keys distributed?** | Customer → Their own developers (env vars, vault) |
| **How are vendor secrets distributed?** | Vendor → Compiled into application binary |
| **Can API keys be rotated?** | Yes, easily via admin portal |
| **Can vendor secrets be rotated?** | Yes, but requires app recompilation |
| **What if API key is stolen?** | Customer revokes it instantly via portal |
| **What if vendor secret is stolen?** | HMAC alone can't prevent, need mTLS (Layer 3) |

---

## ✅ Recommended Implementation Order

1. **Week 1**: Implement tenant API key system
   - Database schema
   - Admin portal UI
   - Validation middleware

2. **Week 2**: Update all client libraries
   - Add `api_key` parameter
   - Update examples and docs

3. **Week 3**: Vendor secret management UI
   - Vendor portal for secret generation
   - Documentation for vendors

4. **Week 4**: Monitoring & Alerts
   - API key usage dashboards
   - Anomaly detection
   - Audit logs

---

**Want me to implement the tenant API key system now?** 🚀

This adds the missing authentication layer while keeping the existing HMAC security!


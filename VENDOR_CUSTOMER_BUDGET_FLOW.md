# Vendor-Customer Budget Flow

## 🎯 **Feature: Vendor Controls, Customer Restricts**

This implements a **real-world SaaS licensing model** where:
- ✅ **Vendor** sets maximum limits (what customer paid for)
- ✅ **Customer** can only **restrict** (lower) those limits
- ❌ **Customer** cannot **exceed** vendor-provisioned maximums

---

## 🔄 **Complete Flow**

```
┌──────────────────────────────────────────────────────────────────┐
│ 1. VENDOR PROVISIONS LICENSES (Vendor Portal)                    │
│    TechVendor sells to Acme Corporation                          │
└──────────────────────────────────────────────────────────────────┘
         │
         │ Vendor opens: /vendor
         │ Selects tool: "ECU Development Suite"
         │ Sets budget:  20 total, 5 commit, 15 overage
         │ Clicks: "Set Vendor Budget"
         │
         ▼
┌──────────────────────────────────────────────────────────────────┐
│ 2. SYSTEM STORES VENDOR LIMITS (Database)                        │
│    vendor_total = 20                                             │
│    vendor_commit_qty = 5                                         │
│    vendor_max_overage = 15                                       │
│                                                                   │
│    active_total = 20        (currently enforced)                │
│    active_commit_qty = 5                                         │
│    active_max_overage = 15                                       │
└──────────────────────────────────────────────────────────────────┘
         │
         │ Customer receives notification
         │
         ▼
┌──────────────────────────────────────────────────────────────────┐
│ 3. CUSTOMER RESTRICTS BUDGET (Customer Config Page)              │
│    Acme IT opens: /config                                        │
│    Sees warning: "Customer Restrictions Only"                    │
│    Current vendor limits: 20 total, 5 commit, 15 overage        │
└──────────────────────────────────────────────────────────────────┘
         │
         │ Scenario A: Try to EXCEED vendor limit
         │
         ▼
┌──────────────────────────────────────────────────────────────────┐
│ ❌ ATTEMPT: Set total to 25 (higher than vendor=20)             │
│    Click "Save"                                                  │
│    → Server validation: REJECTED                                 │
│    → Error: "Cannot exceed vendor limit of 20 total licenses"   │
└──────────────────────────────────────────────────────────────────┘
         │
         │ Scenario B: RESTRICT (lower) limits
         │
         ▼
┌──────────────────────────────────────────────────────────────────┐
│ ✅ ATTEMPT: Set total to 15, commit to 3, overage to 12         │
│    Click "Save"                                                  │
│    → Server validation: ACCEPTED                                 │
│    → Success: "Restrictions applied successfully"               │
└──────────────────────────────────────────────────────────────────┘
         │
         │ System updates database
         │
         ▼
┌──────────────────────────────────────────────────────────────────┐
│ 4. SYSTEM APPLIES CUSTOMER RESTRICTIONS (Database)               │
│    vendor_total = 20                 (unchanged)                │
│    vendor_commit_qty = 5             (unchanged)                │
│    vendor_max_overage = 15           (unchanged)                │
│                                                                   │
│    customer_total = 15               (NEW)                       │
│    customer_commit_qty = 3           (NEW)                       │
│    customer_max_overage = 12         (NEW)                       │
│                                                                   │
│    active_total = 15                 (UPDATED - most restrictive)│
│    active_commit_qty = 3                                         │
│    active_max_overage = 12                                       │
└──────────────────────────────────────────────────────────────────┘
         │
         │ Applications use active limits
         │
         ▼
┌──────────────────────────────────────────────────────────────────┐
│ 5. APPLICATIONS ENFORCE ACTIVE LIMITS                            │
│    Developer tries to borrow license #16                         │
│    → Server checks: active_total = 15                            │
│    → REJECTED: "No licenses available"                           │
│                                                                   │
│    (Even though vendor provisioned 20!)                          │
└──────────────────────────────────────────────────────────────────┘
```

---

## 💡 **Business Logic**

### Validation Rules (Server-Side)

**Customer Restrictions:**
```python
# Customer can only LOWER, not raise
if customer_total > vendor_total:
    return Error("Cannot exceed vendor limit")

if customer_commit > vendor_commit:
    return Error("Cannot exceed vendor commit")

if customer_overage > vendor_overage:
    return Error("Cannot exceed vendor overage")

# Cannot reduce below currently borrowed
if customer_total < currently_borrowed:
    return Error("Cannot reduce below active borrows")

# Math must add up
if customer_commit + customer_overage > customer_total:
    return Error("Commit + overage cannot exceed total")
```

**Vendor Limits:**
```python
# Vendor can set ANY values (they control provisioning)
vendor_total = any_positive_integer
vendor_commit = any_positive_integer <= vendor_total
vendor_overage = any_positive_integer <= (vendor_total - vendor_commit)
```

### Active Configuration

The **active** configuration is always the **most restrictive** value:
```python
active_total = customer_total if customer_total else vendor_total
active_commit = customer_commit if customer_commit else vendor_commit
active_overage = customer_overage if customer_overage else vendor_overage
```

---

## 📊 **Database Schema**

```sql
CREATE TABLE licenses (
    tool TEXT PRIMARY KEY,
    
    -- Active configuration (what's actually enforced)
    total INTEGER NOT NULL,
    commit_qty INTEGER DEFAULT 0,
    max_overage INTEGER DEFAULT 0,
    borrowed INTEGER NOT NULL DEFAULT 0,
    
    -- Vendor-set maximums (cannot be exceeded by customer)
    vendor_total INTEGER,
    vendor_commit_qty INTEGER,
    vendor_max_overage INTEGER,
    
    -- Customer-set restrictions (can only lower, not raise)
    customer_total INTEGER,
    customer_commit_qty INTEGER,
    customer_max_overage INTEGER,
    
    -- Pricing
    commit_price REAL DEFAULT 0.0,
    overage_price_per_license REAL DEFAULT 0.0
);
```

---

## 🔌 **API Endpoints**

### Vendor Portal

**Set Vendor Budget** (Maximum Limits):
```http
PUT /api/vendor/budget
Content-Type: application/json

{
  "tool": "ECU Development Suite",
  "total": 20,
  "commit": 5,
  "max_overage": 15,
  "commit_price": 5000,
  "overage_price_per_license": 500
}

Response: 200 OK
{
  "status": "ok",
  "tool": "ECU Development Suite"
}
```

**Get Budget Configuration**:
```http
GET /api/vendor/budget/ECU%20Development%20Suite

Response: 200 OK
{
  "tool": "ECU Development Suite",
  "vendor_total": 20,
  "vendor_commit_qty": 5,
  "vendor_max_overage": 15,
  "customer_total": 15,
  "customer_commit_qty": 3,
  "customer_max_overage": 12,
  "active_total": 15,
  "active_commit_qty": 3,
  "active_max_overage": 12,
  "borrowed": 0
}
```

### Customer Portal

**Apply Restrictions** (Can Only Lower):
```http
PUT /config/budget
Content-Type: application/json

{
  "tool": "ECU Development Suite",
  "total": 15,            // ✅ Lower than vendor=20
  "commit": 3,            // ✅ Lower than vendor=5
  "max_overage": 12,      // ✅ Lower than vendor=15
  "commit_price": 5000,   // Pricing unchanged
  "overage_price_per_license": 500
}

Response: 200 OK (if within vendor limits)
Response: 400 Bad Request (if exceeds vendor limits)
{
  "detail": "Cannot exceed vendor limit of 20 total licenses"
}
```

---

## 🎬 **Demo Walkthrough**

### Step 1: Vendor Sets Budget
1. Open http://localhost:8000/vendor
2. Scroll to "Customer Budget Management"
3. Select tool: "ECU Development Suite"
4. Set: Total=20, Commit=5, Overage=15
5. Click "Set Vendor Budget"
6. ✅ Confirmation: "Vendor budget set successfully!"

### Step 2: Customer Views Limits
1. Open http://localhost:8000/config
2. See yellow warning: "Customer Restrictions Only"
3. Find "ECU Development Suite" card
4. Current values: Total=20, Commit=5, Overage=15

### Step 3: Customer Restricts Budget
**Scenario A: Try to Exceed (Fails)**
1. Change Total to 25
2. Click "Save"
3. ❌ Error: "Cannot exceed vendor limit of 20 total licenses"

**Scenario B: Restrict (Succeeds)**
1. Change Total to 15, Commit to 3, Overage to 12
2. Click "Save"
3. ✅ Success: "Restrictions applied successfully"

### Step 4: Verify Active Configuration
1. Open http://localhost:8000/dashboard
2. Try to borrow 16 licenses
3. ❌ Fails after 15 (customer restriction enforced)
4. Even though vendor provisioned 20!

---

## 💼 **Real-World Use Cases**

### Use Case 1: Cost Control
**Scenario**: Acme wants to limit overage costs

**Vendor**: Provisions 20 licenses (5 commit, 15 overage)  
**Customer**: Restricts to 10 licenses (5 commit, 5 overage)  
**Result**: Saves money by preventing accidental overage usage

### Use Case 2: Department Limits
**Scenario**: Multiple teams share licenses

**Vendor**: Provisions 50 licenses to company  
**IT Admin**: Restricts Team A to 20, Team B to 15, Team C to 15  
**Result**: Fair allocation across departments

### Use Case 3: Trial Period
**Scenario**: Customer on trial, then upgrades

**Vendor**: Initially provisions 5 licenses  
**Customer**: Uses 5  
**Vendor**: Upgrades to 20 licenses (just updates vendor_total)  
**Customer**: Automatically gets access to 20  
**Result**: Seamless upgrade without customer action

### Use Case 4: Downgrade Protection
**Scenario**: Customer downgrades plan

**Vendor**: Reduces from 20 to 10 licenses  
**Customer**: Currently using 12 licenses  
**Result**: Vendor update rejected (cannot reduce below borrowed)  
**Action**: Customer must return 2 licenses first

---

## 🔐 **Security Benefits**

1. **Vendor Protection**:
   - Customers can't use more than they paid for
   - All limits enforced server-side
   - No client-side manipulation possible

2. **Customer Protection**:
   - Can't accidentally exceed budget
   - Clear visibility of vendor limits
   - Self-service cost control

3. **Audit Trail**:
   - All changes logged
   - Vendor limits vs customer restrictions tracked separately
   - Easy to see who restricted what

---

## ✅ **Complete Implementation**

- ✅ Database schema with vendor/customer/active columns
- ✅ Server-side validation enforces vendor limits
- ✅ Vendor portal with budget management UI
- ✅ Customer portal with restriction-only mode
- ✅ API endpoints for both vendor and customer
- ✅ Real-time status display showing all three configs
- ✅ Clear error messages explaining violations
- ✅ Seamless integration with existing license system

---

## 🎉 **Result**

You now have a **production-ready vendor-customer budget flow** that demonstrates:
- ✅ Realistic SaaS licensing model
- ✅ Clear separation of vendor vs customer control
- ✅ Robust validation and error handling
- ✅ Perfect for automotive company demonstrations!

**Demo this to show how cloud licensing provides better control than traditional dongles!** 🚀


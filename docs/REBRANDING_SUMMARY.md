# Rebranding Summary

## Overview

All automotive brand names have been replaced with generic company names to make the demo more vendor-neutral and suitable for wider audiences.

## Changes Made

### 🏢 Company Names

| **Before** | **After** |
|------------|-----------|
| BMW AG | Acme Corporation |
| Mercedes-Benz AG | Globex Industries |
| Audi AG | Initech Systems |
| Vector Informatik GmbH | TechVendor Software Inc |

### 🔧 Product Names

| **Before** | **After** |
|------------|-----------|
| Vector - DaVinci Configurator SE | ECU Development Suite |
| Vector - DaVinci Configurator IDE | GreenHills Multi IDE |
| Greenhills - Multi 8.2 | AUTOSAR Configuration Tool |
| Vector - ASAP2 v20 | CAN Bus Analyzer Pro |
| Vector - DaVinci Teams | Model-Based Design Studio |
| Vector - VTT | _(removed)_ |

### 🌐 Tenant Subdomains

| **Before** | **After** |
|------------|-----------|
| bmw.localhost:8001 | acme.localhost:8001 |
| mercedes.localhost:8001 | globex.localhost:8001 |
| audi.localhost:8001 | initech.localhost:8001 |
| vendor.localhost:8001 | vendor.localhost:8001 _(unchanged)_ |

### 📦 Product Configurations

| **Product** | **Total** | **Commit** | **Overage** | **Commit Price** | **Overage Price** |
|-------------|-----------|------------|-------------|------------------|-------------------|
| ECU Development Suite | 20 | 5 | 15 | $5,000 | $500 |
| GreenHills Multi IDE | 15 | 10 | 5 | $8,000 | $800 |
| AUTOSAR Configuration Tool | 12 | 8 | 4 | $4,000 | $400 |
| CAN Bus Analyzer Pro | 10 | 10 | 0 | $2,000 | $0 |
| Model-Based Design Studio | 18 | 6 | 12 | $6,000 | $600 |

## Files Updated

### Backend
- ✅ `app/db.py` - Database seeding for multi-tenant demo
- ✅ `app/main.py` - Default tool configurations

### Frontend
- ✅ `app/static/dashboard.html` - Borrow tool dropdown
- ✅ `app/static/vendor.html` - Vendor portal UI and product catalog

### Client Libraries
- ✅ `clients/python/example.py`
- ✅ `clients/c/example.c`
- ✅ `clients/cpp/example.cpp`
- ✅ `clients/rust/src/main.rs`

### Stress Testing
- ✅ `stress-test/src/main.rs` - Random tool selection
- ✅ `stress-test/run_stress_test.sh` - Interactive tool menu

### Documentation
- ✅ `VENDOR_PORTAL_GUIDE.md`
- ✅ `MULTITENANT_DEMO.md`

## Why Generic Names?

1. **Vendor Neutral**: Avoids any potential trademark or branding issues
2. **Universal Demo**: Works for any audience, not just automotive
3. **Professional**: Well-known placeholder company names from pop culture
4. **Clear Separation**: Makes it obvious this is a demo/reference implementation

## What Stayed the Same

- ✅ All functionality remains identical
- ✅ Database schema unchanged
- ✅ API endpoints unchanged
- ✅ Multi-tenant architecture unchanged
- ✅ License budget and overage logic unchanged
- ✅ Real-time metrics and observability unchanged

## Next Steps

When deploying to Fly.io, the database will automatically re-seed with the new company names and product configurations.

To reset the local database:
```bash
rm licenses.db
# Restart the app to re-seed
```

## Easter Eggs 🥚

The new company names are famous references:
- **Acme Corporation**: Classic cartoon company (Looney Tunes)
- **Globex Industries**: Hank Scorpio's company (The Simpsons)
- **Initech**: Office Space movie company


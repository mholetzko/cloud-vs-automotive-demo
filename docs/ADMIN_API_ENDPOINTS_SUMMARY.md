# Admin API Endpoints Summary

## Complete Endpoint List

### 🔵 Customer/Tenant Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/admin/tenants` | Create new customer tenant |
| `GET` | `/api/admin/tenants` | List all tenants |
| `GET` | `/api/admin/tenants/{tenant_id}` | Get tenant details |
| `PATCH` | `/api/admin/tenants/{tenant_id}` | Update tenant (status, etc.) |
| `DELETE` | `/api/admin/tenants/{tenant_id}` | Delete tenant |

### 👥 Customer User Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/admin/tenants/{tenant_id}/users` | List all users for tenant |
| `POST` | `/api/admin/tenants/{tenant_id}/users` | Create user for tenant |
| `GET` | `/api/admin/users/{user_id}` | Get user details |
| `PATCH` | `/api/admin/users/{user_id}` | Update user (role, status) |
| `DELETE` | `/api/admin/users/{user_id}` | Delete user |
| `POST` | `/api/admin/users/{user_id}/reset-password` | Reset user password |
| `POST` | `/api/admin/users/{user_id}/invite` | Send invitation email |

### 🏭 Vendor Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/admin/vendors` | Create new vendor |
| `GET` | `/api/admin/vendors` | List all vendors |
| `GET` | `/api/admin/vendors/{vendor_id}` | Get vendor details |
| `PATCH` | `/api/admin/vendors/{vendor_id}` | Update vendor (status, etc.) |
| `POST` | `/api/admin/vendors/{vendor_id}/regenerate-key` | Regenerate vendor API key |
| `DELETE` | `/api/admin/vendors/{vendor_id}` | Delete vendor |

### 👨‍💼 Vendor User Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/admin/vendors/{vendor_id}/users` | List all users for vendor |
| `POST` | `/api/admin/vendors/{vendor_id}/users` | Create user for vendor |
| `GET` | `/api/admin/users/{user_id}` | Get user details (works for both) |
| `PATCH` | `/api/admin/users/{user_id}` | Update user (role, status) |
| `DELETE` | `/api/admin/users/{user_id}` | Delete user |
| `POST` | `/api/admin/users/{user_id}/reset-password` | Reset user password |

### 📊 Platform Statistics

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/admin/stats` | Get platform statistics |

---

## Quick Reference: Common Operations

### Onboard a Customer

```bash
# 1. Create tenant
curl -X POST https://permetrix.fly.dev/api/admin/tenants \
  -H "Authorization: Bearer $ADMIN_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "company_name": "Acme Corporation",
    "contact_email": "admin@acme.com",
    "tenant_id": "acme"
  }'

# 2. Add additional users (optional)
curl -X POST https://permetrix.fly.dev/api/admin/tenants/acme/users \
  -H "Authorization: Bearer $ADMIN_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "developer@acme.com",
    "role": "developer",
    "send_invite": true
  }'
```

### Onboard a Vendor

```bash
# 1. Create vendor
curl -X POST https://permetrix.fly.dev/api/admin/vendors \
  -H "Authorization: Bearer $ADMIN_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "vendor_name": "Vector Informatik GmbH",
    "contact_email": "sales@vector.com",
    "vendor_id": "vector"
  }'

# 2. Add vendor team members (optional)
curl -X POST https://permetrix.fly.dev/api/admin/vendors/vector/users \
  -H "Authorization: Bearer $ADMIN_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "support@vector.com",
    "role": "vendor_sales",
    "send_invite": true
  }'
```

### Manage Users

```bash
# List all users for a tenant
curl https://permetrix.fly.dev/api/admin/tenants/acme/users \
  -H "Authorization: Bearer $ADMIN_KEY"

# List all users for a vendor
curl https://permetrix.fly.dev/api/admin/vendors/vector/users \
  -H "Authorization: Bearer $ADMIN_KEY"

# Reset user password
curl -X POST https://permetrix.fly.dev/api/admin/users/user_abc123/reset-password \
  -H "Authorization: Bearer $ADMIN_KEY"

# Suspend user
curl -X PATCH https://permetrix.fly.dev/api/admin/users/user_abc123 \
  -H "Authorization: Bearer $ADMIN_KEY" \
  -H "Content-Type: application/json" \
  -d '{"status": "suspended"}'
```

### Platform Overview

```bash
# Get platform statistics
curl https://permetrix.fly.dev/api/admin/stats \
  -H "Authorization: Bearer $ADMIN_KEY"

# List all tenants
curl https://permetrix.fly.dev/api/admin/tenants \
  -H "Authorization: Bearer $ADMIN_KEY"

# List all vendors
curl https://permetrix.fly.dev/api/admin/vendors \
  -H "Authorization: Bearer $ADMIN_KEY"
```

---

## User Roles Reference

### Customer User Roles

- **`admin`**: Full access to tenant (manage users, configure budgets, generate API keys)
- **`developer`**: Can borrow/return licenses, view status
- **`viewer`**: Read-only access (view status, cannot borrow)

### Vendor User Roles

- **`vendor_admin`**: Full access to vendor portal (manage users, provision licenses, configure budgets)
- **`vendor_sales`**: Can view customers, provision licenses
- **`vendor_support`**: Read-only access to customer data

---

## Response Codes

| Code | Meaning |
|------|---------|
| `200` | Success |
| `201` | Created |
| `400` | Bad Request (invalid input) |
| `401` | Unauthorized (missing/invalid admin API key) |
| `403` | Forbidden (valid key but insufficient permissions) |
| `404` | Not Found (tenant/vendor/user doesn't exist) |
| `409` | Conflict (tenant/vendor already exists) |
| `500` | Internal Server Error |


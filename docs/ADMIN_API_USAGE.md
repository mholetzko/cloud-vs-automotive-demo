# Admin API Usage Guide

## Overview

The Admin API allows the Permetrix platform owner to programmatically manage tenants (customers) and vendors. All endpoints require authentication via an Admin API key.

## Authentication

All Admin API endpoints require a `Bearer` token in the `Authorization` header:

```bash
Authorization: Bearer <PERMETRIX_ADMIN_API_KEY>
```

### Setting the Admin API Key

Set the `PERMETRIX_ADMIN_API_KEY` environment variable:

```bash
# Generate a secure key
python3 -c "import secrets; print('admin_live_' + secrets.token_urlsafe(32))"

# Set in Fly.io
flyctl secrets set PERMETRIX_ADMIN_API_KEY=admin_live_<your-generated-key>

# Or locally
export PERMETRIX_ADMIN_API_KEY=admin_live_<your-generated-key>
```

## Endpoints

### Create Tenant (Customer)

Create a new customer tenant with automatic subdomain provisioning.

**Endpoint**: `POST /api/admin/tenants`

**Request Body**:
```json
{
  "company_name": "Acme Corporation",
  "contact_email": "admin@acme.com",
  "tenant_id": "acme",  // Optional: auto-generated from company_name if not provided
  "crm_id": "CRM-12345",  // Optional: CRM system identifier
  "company_domain": "acme.com"  // Optional: company's actual domain
}
```

**Response**:
```json
{
  "tenant_id": "acme",
  "company_name": "Acme Corporation",
  "domain": "acme.permetrix.fly.dev",
  "status": "active",
  "admin_user_id": "user_abc123...",
  "admin_email": "admin@acme.com",
  "setup_token": "xyz789...",
  "setup_link": "https://acme.permetrix.fly.dev/setup?token=xyz789...",
  "created_at": "2025-11-06T12:00:00"
}
```

**Example**:
```bash
curl -X POST https://permetrix.fly.dev/api/admin/tenants \
  -H "Authorization: Bearer $PERMETRIX_ADMIN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "company_name": "Acme Corporation",
    "contact_email": "admin@acme.com"
  }'
```

### List Tenants

Get all customer tenants.

**Endpoint**: `GET /api/admin/tenants`

**Response**:
```json
{
  "tenants": [
    {
      "tenant_id": "acme",
      "company_name": "Acme Corporation",
      "domain": "acme.permetrix.fly.dev",
      "crm_id": "CRM-12345",
      "status": "active",
      "created_at": "2025-11-06T12:00:00"
    }
  ]
}
```

**Example**:
```bash
curl https://permetrix.fly.dev/api/admin/tenants \
  -H "Authorization: Bearer $PERMETRIX_ADMIN_API_KEY"
```

### Get Tenant Details

Get details for a specific tenant.

**Endpoint**: `GET /api/admin/tenants/{tenant_id}`

**Example**:
```bash
curl https://permetrix.fly.dev/api/admin/tenants/acme \
  -H "Authorization: Bearer $PERMETRIX_ADMIN_API_KEY"
```

### Create Vendor

Create a new vendor with automatic API key generation.

**Endpoint**: `POST /api/admin/vendors`

**Request Body**:
```json
{
  "vendor_name": "TechVendor Software Inc",
  "contact_email": "admin@techvendor.com",
  "vendor_id": "techvendor"  // Optional: auto-generated from vendor_name if not provided
}
```

**Response**:
```json
{
  "vendor_id": "techvendor",
  "vendor_name": "TechVendor Software Inc",
  "status": "active",
  "api_key": "vnd_live_xyz789...",  // ⚠️ Only shown once! Store securely.
  "admin_user_id": "vendor_user_abc123...",
  "admin_email": "admin@techvendor.com",
  "setup_token": "xyz789...",
  "setup_link": "https://vendor.permetrix.fly.dev/setup?token=xyz789...",
  "created_at": "2025-11-06T12:00:00"
}
```

**Example**:
```bash
curl -X POST https://permetrix.fly.dev/api/admin/vendors \
  -H "Authorization: Bearer $PERMETRIX_ADMIN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "vendor_name": "TechVendor Software Inc",
    "contact_email": "admin@techvendor.com"
  }'
```

### List Vendors

Get all vendors.

**Endpoint**: `GET /api/admin/vendors`

**Response**:
```json
{
  "vendors": [
    {
      "vendor_id": "techvendor",
      "vendor_name": "TechVendor Software Inc",
      "contact_email": "admin@techvendor.com",
      "status": "active",
      "created_at": "2025-11-06T12:00:00",
      "admin_email": "admin@techvendor.com"
    }
  ]
}
```

**Example**:
```bash
curl https://permetrix.fly.dev/api/admin/vendors \
  -H "Authorization: Bearer $PERMETRIX_ADMIN_API_KEY"
```

### Get Vendor Details

Get details for a specific vendor.

**Endpoint**: `GET /api/admin/vendors/{vendor_id}`

**Example**:
```bash
curl https://permetrix.fly.dev/api/admin/vendors/techvendor \
  -H "Authorization: Bearer $PERMETRIX_ADMIN_API_KEY"
```

### Platform Statistics

Get platform-wide statistics.

**Endpoint**: `GET /api/admin/stats`

**Response**:
```json
{
  "tenants": {
    "total": 10,
    "active": 9
  },
  "vendors": {
    "total": 3,
    "active": 3
  },
  "licenses": {
    "total_provisioned": 150,
    "active_borrows": 45
  }
}
```

**Example**:
```bash
curl https://permetrix.fly.dev/api/admin/stats \
  -H "Authorization: Bearer $PERMETRIX_ADMIN_API_KEY"
```

## Error Responses

All endpoints return standard HTTP status codes:

- `200 OK`: Success
- `401 Unauthorized`: Missing or invalid Authorization header
- `403 Forbidden`: Invalid admin API key
- `404 Not Found`: Resource not found
- `409 Conflict`: Resource already exists (e.g., tenant_id or vendor_id already in use)
- `500 Internal Server Error`: Server error

**Error Response Format**:
```json
{
  "detail": "Error message here"
}
```

## Workflow Examples

### Onboarding a New Customer

1. **Create the tenant**:
```bash
curl -X POST https://permetrix.fly.dev/api/admin/tenants \
  -H "Authorization: Bearer $PERMETRIX_ADMIN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "company_name": "Acme Corporation",
    "contact_email": "admin@acme.com",
    "crm_id": "CRM-12345"
  }'
```

2. **Send setup link to customer**:
   - The response includes a `setup_link` that the customer can use to complete their account setup
   - The customer will set their password and configure their account

3. **Vendor provisions licenses**:
   - Vendors can now see "Acme Corporation" in their vendor portal
   - They can provision licenses to this customer

### Onboarding a New Vendor

1. **Create the vendor**:
```bash
curl -X POST https://permetrix.fly.dev/api/admin/vendors \
  -H "Authorization: Bearer $PERMETRIX_ADMIN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "vendor_name": "TechVendor Software Inc",
    "contact_email": "admin@techvendor.com"
  }'
```

2. **Store the vendor API key securely**:
   - The response includes an `api_key` that the vendor needs for their client libraries
   - ⚠️ This key is only shown once! Store it securely.

3. **Send setup link to vendor**:
   - The response includes a `setup_link` for the vendor to complete their account setup

## Security Considerations

1. **Admin API Key**: Store the `PERMETRIX_ADMIN_API_KEY` securely. Never commit it to version control.

2. **Vendor API Keys**: When creating vendors, the API key is only shown once in the response. Ensure it's stored securely before the response is lost.

3. **Setup Tokens**: Setup tokens are single-use and should be sent securely to the customer/vendor.

4. **Rate Limiting**: Consider implementing rate limiting for Admin API endpoints in production.

5. **Audit Logging**: All Admin API operations are logged. Monitor these logs for security.

### Delete Tenant

Delete a tenant (customer). Supports both soft delete (default) and hard delete.

**Endpoint**: `DELETE /api/admin/tenants/{tenant_id}`

**Query Parameters**:
- `hard_delete` (optional, default: `false`): If `true`, permanently delete. If `false`, soft delete (mark as deleted).

**Soft Delete** (default):
- Marks tenant as `status='deleted'`
- Preserves all data for recovery
- Safe for production use

**Hard Delete**:
- Permanently removes tenant and all related data
- ⚠️ **Cannot be undone!**
- Requires all licenses to be returned first
- Use for testing/cleanup only

**Response**:
```json
{
  "tenant_id": "acme",
  "company_name": "Acme Corporation",
  "status": "deleted",
  "deletion_type": "soft",
  "message": "Tenant acme (Acme Corporation) marked as deleted (soft delete)"
}
```

**Examples**:
```bash
# Soft delete (default)
curl -X DELETE https://permetrix.fly.dev/api/admin/tenants/acme \
  -H "Authorization: Bearer $PERMETRIX_ADMIN_API_KEY"

# Hard delete (permanent)
curl -X DELETE "https://permetrix.fly.dev/api/admin/tenants/acme?hard_delete=true" \
  -H "Authorization: Bearer $PERMETRIX_ADMIN_API_KEY"
```

### Delete Vendor

Delete a vendor. Supports both soft delete (default) and hard delete.

**Endpoint**: `DELETE /api/admin/vendors/{vendor_id}`

**Query Parameters**:
- `hard_delete` (optional, default: `false`): If `true`, permanently delete. If `false`, soft delete (mark as deleted).

**Soft Delete** (default):
- Marks vendor as `status='deleted'`
- Preserves all data for recovery
- Safe for production use

**Hard Delete**:
- Permanently removes vendor and all related data
- ⚠️ **Cannot be undone!**
- Requires all license packages to be removed first
- Use for testing/cleanup only

**Response**:
```json
{
  "vendor_id": "techvendor",
  "vendor_name": "TechVendor Software Inc",
  "status": "deleted",
  "deletion_type": "hard",
  "message": "Vendor techvendor (TechVendor Software Inc) permanently deleted"
}
```

**Examples**:
```bash
# Soft delete (default)
curl -X DELETE https://permetrix.fly.dev/api/admin/vendors/techvendor \
  -H "Authorization: Bearer $PERMETRIX_ADMIN_API_KEY"

# Hard delete (permanent)
curl -X DELETE "https://permetrix.fly.dev/api/admin/vendors/techvendor?hard_delete=true" \
  -H "Authorization: Bearer $PERMETRIX_ADMIN_API_KEY"
```

## Next Steps

After creating tenants and vendors via the Admin API:

1. **Customer Setup**: Customers receive a setup link to complete their account configuration
2. **Vendor Setup**: Vendors receive a setup link and their API key for client library integration
3. **License Provisioning**: Vendors can provision licenses to customers via the vendor portal
4. **API Key Generation**: Customers can generate their own API keys via the customer config page

## Cleanup for Testing

When testing, you can clean up test data:

```bash
# List all tenants
curl https://permetrix.fly.dev/api/admin/tenants \
  -H "Authorization: Bearer $PERMETRIX_ADMIN_API_KEY"

# Hard delete test tenant (permanent)
curl -X DELETE "https://permetrix.fly.dev/api/admin/tenants/test-tenant?hard_delete=true" \
  -H "Authorization: Bearer $PERMETRIX_ADMIN_API_KEY"

# Hard delete test vendor (permanent)
curl -X DELETE "https://permetrix.fly.dev/api/admin/vendors/test-vendor?hard_delete=true" \
  -H "Authorization: Bearer $PERMETRIX_ADMIN_API_KEY"
```

⚠️ **Warning**: Hard delete is permanent and cannot be undone. Use soft delete in production.


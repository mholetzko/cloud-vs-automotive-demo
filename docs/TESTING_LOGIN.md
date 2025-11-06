# Testing Login & User Management

## Quick Start Testing Guide

### Prerequisites

1. **Set Admin API Key** (if not already set):
```bash
# Generate a secure key
python3 -c "import secrets; print('admin_live_' + secrets.token_urlsafe(32))"

# Set in Fly.io
flyctl secrets set PERMETRIX_ADMIN_API_KEY=admin_live_<your-generated-key>

# Or locally (for testing)
export PERMETRIX_ADMIN_API_KEY=admin_live_<your-generated-key>
```

2. **Set Session Secret** (for session management):
```bash
# Generate a secure key
python3 -c "import secrets; print(secrets.token_urlsafe(32))"

# Set in Fly.io
flyctl secrets set SESSION_SECRET_KEY=<your-generated-key>

# Or locally
export SESSION_SECRET_KEY=<your-generated-key>
```

---

## Step-by-Step Testing

### 1. Create a Test Tenant

```bash
# Replace with your actual admin API key
export PERMETRIX_ADMIN_API_KEY="admin_live_<your-key>"

# Create a tenant
curl -X POST https://permetrix.fly.dev/api/admin/tenants \
  -H "Authorization: Bearer $PERMETRIX_ADMIN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "company_name": "Test Company",
    "contact_email": "test@example.com"
  }'
```

**Response** will include:
```json
{
  "tenant_id": "test-company",
  "company_name": "Test Company",
  "domain": "test-company.permetrix.fly.dev",
  "setup_token": "xyz789...",
  "setup_link": "https://test-company.permetrix.fly.dev/setup?token=xyz789..."
}
```

### 2. Test Setup Page

1. **Copy the `setup_link`** from the response
2. **Open it in your browser**: `https://test-company.permetrix.fly.dev/setup?token=xyz789...`
3. **Set a password** (minimum 8 characters)
4. **Click "Complete Setup"**
5. You should be **automatically logged in** and redirected to `/dashboard`

### 3. Test Login

1. **Go to**: `https://permetrix.fly.dev/login`
2. **Enter**:
   - Username: `test@example.com` (the email you used when creating the tenant)
   - Password: The password you set in step 2
3. **Click "Login"**
4. You should be **redirected to `/dashboard`**

### 4. Test Profile Page

1. **Go to**: `https://permetrix.fly.dev/profile`
2. You should see:
   - Username: `test@example.com`
   - Role: `admin`
   - Tenant: `test-company`
   - Vendor: `N/A`

### 5. Test Logout

1. **Click "Logout"** in the header (or go to `/api/auth/logout`)
2. You should be **redirected to `/login`**
3. Try accessing `/profile` again - should redirect to login

---

## Testing with Vendor

### 1. Create a Test Vendor

```bash
curl -X POST https://permetrix.fly.dev/api/admin/vendors \
  -H "Authorization: Bearer $PERMETRIX_ADMIN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "vendor_name": "Test Vendor",
    "contact_email": "vendor@example.com"
  }'
```

**Response** will include:
```json
{
  "vendor_id": "test-vendor",
  "vendor_name": "Test Vendor",
  "api_key": "vnd_live_xyz789...",
  "setup_link": "https://vendor.permetrix.fly.dev/setup?token=xyz789..."
}
```

### 2. Test Vendor Setup & Login

1. **Use the `setup_link`** to set password
2. **Login** with `vendor@example.com`
3. Should be **redirected to `/vendor`** (vendor portal)

---

## Local Testing

If testing locally:

```bash
# Start the server
cd /Users/matthiasholetzko/Documents/Software-Projects/Experiment-MB-Presentation
source venv/bin/activate  # or your venv path
uvicorn app.main:app --reload --port 8000

# Then use:
# - http://localhost:8000/login
# - http://localhost:8000/setup?token=...
# - http://localhost:8000/profile
```

---

## Troubleshooting

### "Invalid or expired setup token"
- Token might have been used already (one-time use)
- Check that the token matches exactly
- Create a new tenant/vendor to get a fresh token

### "Invalid username or password"
- Make sure you're using the email address as username
- Check that password was set correctly
- Try creating a new tenant and setting up again

### "Authentication required" on profile page
- Session might have expired (7 days)
- Try logging in again
- Check browser cookies are enabled

### Cookie issues (local development)
- Make sure `SESSION_SECRET_KEY` is set
- Cookies work on `localhost` (secure=False in dev)
- Try clearing browser cookies and logging in again

---

## Quick Test Script

Save this as `test-login.sh`:

```bash
#!/bin/bash

# Set your admin API key
export PERMETRIX_ADMIN_API_KEY="admin_live_<your-key>"
BASE_URL="https://permetrix.fly.dev"  # or http://localhost:8000 for local

echo "🧪 Testing Login & User Management"
echo ""

# 1. Create tenant
echo "1️⃣  Creating test tenant..."
RESPONSE=$(curl -s -X POST "$BASE_URL/api/admin/tenants" \
  -H "Authorization: Bearer $PERMETRIX_ADMIN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "company_name": "Test Company",
    "contact_email": "test@example.com"
  }')

echo "$RESPONSE" | python3 -m json.tool
echo ""

# Extract setup link
SETUP_LINK=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['setup_link'])")
TENANT_ID=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['tenant_id'])")

echo "✅ Tenant created: $TENANT_ID"
echo "🔗 Setup link: $SETUP_LINK"
echo ""
echo "📝 Next steps:"
echo "   1. Open the setup link in your browser"
echo "   2. Set a password (min 8 characters)"
echo "   3. You'll be automatically logged in"
echo "   4. Test login at: $BASE_URL/login"
echo "   5. Test profile at: $BASE_URL/profile"
echo ""
echo "🧹 Cleanup:"
echo "   curl -X DELETE \"$BASE_URL/api/admin/tenants/$TENANT_ID?hard_delete=true\" \\"
echo "     -H \"Authorization: Bearer $PERMETRIX_ADMIN_API_KEY\""
```

Make it executable and run:
```bash
chmod +x test-login.sh
./test-login.sh
```

---

## API Testing with curl

### Test Login API

```bash
# Login
curl -X POST https://permetrix.fly.dev/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=test@example.com&password=yourpassword" \
  -v

# Should return 302 redirect with Set-Cookie header
```

### Test Current User API

```bash
# Get current user (requires session cookie from login)
curl https://permetrix.fly.dev/api/auth/me \
  -H "Cookie: permetrix_session=<your-session-token>" \
  -v

# Should return user info JSON
```

---

## What to Verify

✅ **Setup Flow**:
- Setup page loads with token pre-filled
- Password can be set (min 8 chars)
- Password confirmation works
- Redirects to dashboard after setup
- User is logged in automatically

✅ **Login Flow**:
- Login page loads
- Invalid credentials show error
- Valid credentials redirect correctly
- Session cookie is set

✅ **Profile Page**:
- Shows correct user info
- Requires authentication
- Redirects to login if not authenticated

✅ **Logout**:
- Clears session cookie
- Redirects to login
- Can't access protected pages after logout

✅ **Role-Based Redirects**:
- Vendor users → `/vendor`
- Tenant users → `/dashboard`
- Regular users → `/dashboard`

---

## Next Steps

After testing login, you can:
1. Test tenant-specific features (dashboard, config)
2. Test vendor portal features
3. Test API key generation for tenants
4. Test multi-tenant isolation


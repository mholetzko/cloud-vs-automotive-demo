#!/bin/bash

# Set your admin API key
export PERMETRIX_ADMIN_API_KEY="${PERMETRIX_ADMIN_API_KEY:-admin_live_CHANGE_ME}"
BASE_URL="${BASE_URL:-https://permetrix.fly.dev}"  # or http://localhost:8000 for local

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

echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
echo ""

# Extract setup link
SETUP_LINK=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['setup_link'])" 2>/dev/null)
TENANT_ID=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['tenant_id'])" 2>/dev/null)

if [ -z "$SETUP_LINK" ]; then
    echo "❌ Failed to create tenant. Check your PERMETRIX_ADMIN_API_KEY"
    exit 1
fi

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

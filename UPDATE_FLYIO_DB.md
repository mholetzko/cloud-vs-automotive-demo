# Update Fly.io Database Guide

## 🎯 Current Situation

The database on Fly.io is stored on a persistent volume at `/data/licenses.db`. When you deploy new code, the existing database is **NOT** automatically updated or recreated.

## 🔄 Methods to Update the Database

---

### **Method 1: Quick Reset (Recommended)** ⭐

Use the automated script to delete and reseed:

```bash
./reset-flyio-db.sh
```

This script will:
1. ✅ SSH into Fly.io and delete `/data/licenses.db`
2. ✅ Restart the app
3. ✅ The app will automatically create a new database with the new products

---

### **Method 2: Manual SSH** 

If you want more control:

```bash
# 1. SSH into the Fly.io machine
flyctl ssh console

# 2. Delete the database
rm -f /data/licenses.db

# 3. Exit SSH
exit

# 4. Restart the app
flyctl apps restart license-server-demo
```

---

### **Method 3: Deploy + Reset** 

First deploy the new code, then reset:

```bash
# 1. Push changes to GitHub (triggers auto-deploy)
git add .
git commit -m "Update products"
git push origin main

# 2. Wait for deployment to complete (check GitHub Actions)

# 3. Then reset database
./reset-flyio-db.sh
```

---

### **Method 4: Manual Update via SQL** 

If you want to keep existing borrow data and only update products:

```bash
# 1. SSH into Fly.io
flyctl ssh console

# 2. Install sqlite3 if not present
apt-get update && apt-get install -y sqlite3

# 3. Update the database
sqlite3 /data/licenses.db <<'EOF'
-- Delete old products
DELETE FROM licenses;

-- Insert new products
INSERT INTO licenses (tool, total, borrowed, commit_qty, max_overage, commit_price, overage_price_per_license) VALUES
  ('Vector - DaVinci Configurator SE', 20, 0, 5, 15, 5000.0, 500.0),
  ('Vector - DaVinci Configurator IDE', 10, 0, 10, 0, 3000.0, 0.0),
  ('Greenhills - Multi 8.2', 20, 0, 5, 15, 8000.0, 800.0),
  ('Vector - ASAP2 v20', 20, 0, 5, 15, 4000.0, 400.0),
  ('Vector - DaVinci Teams', 10, 0, 10, 0, 2000.0, 0.0),
  ('Vector - VTT', 10, 0, 10, 0, 2500.0, 0.0);
EOF

# 4. Exit and restart
exit
flyctl apps restart license-server-demo
```

⚠️ **Warning**: This keeps the borrows table, which might reference old tools and cause issues.

---

## 🚀 Recommended Workflow

For your demo, I recommend:

```bash
# 1. Deploy the updated code
git add .
git commit -m "Add automotive software products"
git push origin main

# 2. Wait for GitHub Actions to complete (~2-3 minutes)
# Check: https://github.com/mholetzko/cloud-vs-automotive-demo/actions

# 3. Reset the database with new products
./reset-flyio-db.sh

# 4. Test the deployment
curl https://license-server-demo.fly.dev/licenses/status | jq
```

---

## 📊 Verify New Products

After resetting, check the products:

```bash
# List all tools
curl https://license-server-demo.fly.dev/licenses/status | jq

# Or visit in browser
open https://license-server-demo.fly.dev/dashboard
```

You should see:
- ✅ Vector - DaVinci Configurator SE (20 total, 5 commit, 15 overage)
- ✅ Vector - DaVinci Configurator IDE (10 total, 10 commit, 0 overage)
- ✅ Greenhills - Multi 8.2 (20 total, 5 commit, 15 overage)
- ✅ Vector - ASAP2 v20 (20 total, 5 commit, 15 overage)
- ✅ Vector - DaVinci Teams (10 total, 10 commit, 0 overage)
- ✅ Vector - VTT (10 total, 10 commit, 0 overage)

---

## 🔍 Troubleshooting

### Database not resetting?

```bash
# Check if database file exists
flyctl ssh console -C "ls -lah /data/"

# Check app logs
flyctl logs

# Look for: "database initialized with seed data for automotive tools"
```

### Old products still showing?

```bash
# Verify the environment variable
flyctl ssh console -C "env | grep LICENSE_DB"

# Should show: LICENSE_DB_SEED=true
```

### App not starting?

```bash
# Check status
flyctl status

# View logs
flyctl logs --no-tail
```

---

## 💡 Pro Tips

1. **Backup before reset** (if you have important test data):
   ```bash
   flyctl ssh sftp get /data/licenses.db ./backup-licenses.db
   ```

2. **Restore from backup**:
   ```bash
   flyctl ssh sftp shell
   put backup-licenses.db /data/licenses.db
   ```

3. **Monitor after reset**:
   ```bash
   flyctl logs -f
   ```

---

## 🎬 For Your Demo

Since you're presenting to an automotive company, the new products are:
- **Vector Tools**: Industry-standard AUTOSAR and calibration tools
- **Greenhills Multi**: Embedded compiler toolchain
- Realistic pricing: $2,000 - $8,000 commit fees

This makes the demo much more relatable! 🚗✨


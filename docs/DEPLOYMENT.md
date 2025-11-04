# Deployment Guide - License Server Demo

## 🚀 Option 1: Fly.io (Recommended - FREE)

### Prerequisites
- Install flyctl: `brew install flyctl` (macOS) or https://fly.io/docs/hands-on/install-flyctl/
- Fly.io account (free): `flyctl auth signup`

### Deploy Steps

1. **Login to Fly.io**
```bash
flyctl auth login
```

2. **Create volume for database persistence**
```bash
flyctl volumes create license_data --size 1 --region fra
```

3. **Launch and deploy**
```bash
flyctl launch --no-deploy
# Answer prompts:
# - Choose app name (or keep generated)
# - Choose region: fra (Frankfurt) or closest to you
# - No to Postgres
# - No to Redis

flyctl deploy
```

4. **Your app will be live at:**
```
https://YOUR-APP-NAME.fly.dev
```

5. **View logs**
```bash
flyctl logs
```

6. **Scale down after demo (optional)**
```bash
flyctl scale count 0  # Stop machines
flyctl scale count 1  # Start again
```

### Cost: **$0** (Free tier includes 3 shared VMs, 3GB persistent storage)

---

## 🚂 Option 2: Railway.app (FREE $5/month credit)

### Steps

1. **Push code to GitHub**
```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin YOUR_GITHUB_REPO
git push -u origin main
```

2. **Deploy on Railway**
- Go to https://railway.app
- Click "Start a New Project"
- Select "Deploy from GitHub repo"
- Choose your repository
- Railway auto-detects Dockerfile and deploys

3. **Configure**
- Click on your service → Variables
- Add: `LICENSE_DB_SEED=true`
- Railway provides persistent storage automatically

4. **Access**
- Click "Settings" → "Generate Domain"
- Your app will be at: `https://YOUR-APP.railway.app`

### Cost: **$0** (includes $5 free credit/month, demo uses ~$0.50)

---

## 🌊 Option 3: DigitalOcean App Platform ($5/month)

### Steps

1. **Push to GitHub** (same as Railway)

2. **Create App**
- Go to https://cloud.digitalocean.com/apps
- Click "Create App"
- Connect GitHub → Select repository
- Detects Dockerfile automatically

3. **Configure**
- Choose $5 Basic plan
- Set environment variable: `LICENSE_DB_SEED=true`
- Add persistent volume (optional, $1/month for 1GB)

4. **Deploy**
- Click "Create Resources"
- Wait 3-5 minutes
- Access at: `https://YOUR-APP.ondigitalocean.app`

### Cost: **$5/month** (can cancel after demo)

---

## 📊 Without Observability Stack

The above deployments run **only the FastAPI app** (lightweight, fast).

Prometheus/Grafana/Loki would need separate setup or cloud services:
- **Grafana Cloud**: Free tier (10k series, 50GB logs)
- **Docker Compose**: Run on a $5 DigitalOcean Droplet

For the demo, you can:
1. Show the **app functionality** (hosted)
2. Show **observability** via localhost or separate cloud setup

---

## 🎯 Recommendation for Thursday Demo

**Use Fly.io:**
- ✅ Completely free
- ✅ Deploys in 2-3 minutes  
- ✅ Persistent database
- ✅ Auto-sleep saves resources
- ✅ Can scale to 0 when not demoing

**Commands to deploy NOW:**
```bash
# Install flyctl
brew install flyctl

# Login
flyctl auth signup
flyctl auth login

# Deploy (from project directory)
flyctl launch --no-deploy
flyctl volumes create license_data --size 1 --region fra
flyctl deploy

# Done! App is live
```

---

## 🔍 For Full Observability Stack

If you need Prometheus/Grafana/Loki for the demo:

**Option A: Run locally during demo**
```bash
docker compose up -d
# Demo from http://localhost:8000
```

**Option B: Small VPS**
- DigitalOcean $6 Droplet
- Install Docker + Docker Compose
- Deploy full stack with `docker compose up -d`
- Access via IP address

**Option C: Managed Services**
- Grafana Cloud (free tier)
- Update prometheus.yml to remote_write to Grafana Cloud
- Deploy app to Fly.io
- Grafana Cloud for dashboards

---

## 🆘 Need help?

After deploying, test with:
```bash
curl https://YOUR-APP-URL.fly.dev/
curl https://YOUR-APP-URL.fly.dev/licenses/status
```

Should return JSON responses.

Let me know which option you choose and I can help with any issues!


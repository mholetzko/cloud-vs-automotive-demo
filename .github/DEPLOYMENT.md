# Automated Deployment Setup

This repository is configured for automated deployments to Fly.io using GitHub Actions.

## 🚀 How It Works

Every time you push to `main` branch, if any of these files change:
- `app/**` (backend code)
- `requirements.txt` (dependencies)
- `Dockerfile` (container config)
- `fly.toml` (Fly.io config)

GitHub Actions will automatically:
1. ✅ Checkout the code
2. ✅ Setup Fly CLI
3. ✅ Deploy to Fly.io
4. ✅ Verify with health check
5. ✅ Report status

## 🔑 Secrets Setup

The following secret is configured in the repository:

- `FLY_API_TOKEN` - Fly.io authentication token

**To rotate the token:**

```bash
# Get new token
flyctl tokens create deploy --name github-actions

# Update GitHub secret
gh secret set FLY_API_TOKEN < new_token.txt
```

## 📋 Workflow Details

**File:** `.github/workflows/fly-deploy.yml`

**Triggers:**
- Push to `main` branch (with relevant file changes)
- Manual dispatch (via Actions tab)

**Concurrency:** Only one deployment at a time (queued)

**Status:** Check at https://github.com/mholetzko/cloud-vs-automotive-demo/actions

## 🎯 Manual Deployment

You can trigger a deployment manually:

1. Go to: https://github.com/mholetzko/cloud-vs-automotive-demo/actions
2. Click **"Deploy to Fly.io"** workflow
3. Click **"Run workflow"**
4. Select branch (usually `main`)
5. Click **"Run workflow"**

## 🔍 Monitoring Deployments

### Via GitHub Actions UI

1. Go to **Actions** tab
2. Click on the workflow run
3. View logs for each step

### Via Fly.io Dashboard

1. Go to: https://fly.io/apps/license-server-demo
2. View deployment history and logs

### Via CLI

```bash
# View deployment status
flyctl status

# View recent deployments
flyctl releases

# View logs
flyctl logs
```

## ✅ Deployment Verification

After each deployment, the workflow automatically:

1. Waits 5 seconds for the app to start
2. Performs a health check: `GET /licenses/status`
3. Expects HTTP 200 response
4. Fails the workflow if health check fails

## 🐛 Troubleshooting

### Deployment Failed

Check the GitHub Actions logs for errors:

```bash
# View the specific error
https://github.com/mholetzko/cloud-vs-automotive-demo/actions
```

Common issues:
- **Invalid FLY_API_TOKEN:** Rotate the token
- **Build failures:** Check Dockerfile and dependencies
- **Health check failed:** App might be slow to start, or there's a runtime error

### Fix and Redeploy

```bash
# Fix the issue locally
# Commit and push
git add .
git commit -m "fix: deployment issue"
git push

# The workflow will automatically trigger
```

### Manual Deployment

If automated deployment fails, deploy manually:

```bash
flyctl deploy
```

## 📊 Deployment URLs

After successful deployment, the app is available at:

| Service | URL |
|---------|-----|
| Main Dashboard | https://license-server-demo.fly.dev |
| Metrics Dashboard | https://license-server-demo.fly.dev/metrics-dashboard |
| Presentation | https://license-server-demo.fly.dev/presentation |
| API Docs | https://license-server-demo.fly.dev/docs |
| Prometheus Metrics | https://license-server-demo.fly.dev/metrics |

## 🔐 Security Best Practices

1. ✅ **Never commit secrets** to the repository
2. ✅ **Use GitHub Secrets** for sensitive data
3. ✅ **Rotate tokens regularly** (every 90 days)
4. ✅ **Use deployment keys** with minimal permissions
5. ✅ **Monitor deployment logs** for suspicious activity

## 📈 Deployment History

View deployment history:

```bash
flyctl releases
```

Rollback to previous version:

```bash
flyctl releases rollback <version>
```

## 🚦 Deployment Status Badge

Add to README.md:

```markdown
[![Deploy to Fly.io](https://github.com/mholetzko/cloud-vs-automotive-demo/actions/workflows/fly-deploy.yml/badge.svg)](https://github.com/mholetzko/cloud-vs-automotive-demo/actions/workflows/fly-deploy.yml)
```

## 📞 Support

- **Fly.io Docs:** https://fly.io/docs/
- **GitHub Actions Docs:** https://docs.github.com/en/actions
- **Repository Issues:** https://github.com/mholetzko/cloud-vs-automotive-demo/issues

---

**Last Updated:** 2025-11-03  
**Deployment Target:** Fly.io (Frankfurt region)  
**Automation Status:** ✅ Active


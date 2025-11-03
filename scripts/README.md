# Demo Client Scripts

## License Server Demo Client

A Python client to test the license server from any machine, against either localhost or the deployed Fly.io instance.

### Installation

```bash
# The client only needs the requests library
pip install requests
```

### Usage

#### Test against deployed Fly.io instance:

```bash
python scripts/demo_client.py --url https://license-server-demo.fly.dev
```

#### Test against localhost:

```bash
python scripts/demo_client.py --url http://localhost:8000
```

#### Interactive mode:

```bash
python scripts/demo_client.py --url https://license-server-demo.fly.dev --interactive
```

Interactive commands:
- `status [tool]` - Check license status for a tool or all tools
- `borrow <tool>` - Borrow a license
- `return <id>` - Return a license
- `list` - List your currently borrowed licenses
- `quit` - Exit

#### Simulate specific tool:

```bash
python scripts/demo_client.py --url https://license-server-demo.fly.dev --tool cad_tool --duration 10
```

#### Run in a loop (stress test):

```bash
python scripts/demo_client.py --url https://license-server-demo.fly.dev --loop 10
```

#### Custom user:

```bash
python scripts/demo_client.py --url https://license-server-demo.fly.dev --user alice
```

### Examples

**Quick test:**
```bash
# Test against deployed instance
python scripts/demo_client.py --url https://license-server-demo.fly.dev

# Output:
# ======================================================================
# 🎫  License Server Demo Client
# ======================================================================
# Server:  https://license-server-demo.fly.dev
# User:    demo-client
# ======================================================================
# 
# ✅ Connected to server (version: 1.0.0)
# 
# 🎯 Simulating license usage for cad_tool
#    User: demo-client
#    Available: 5/5
# ✅ Borrowed cad_tool license (ID: abc123)
#    💼 Working with cad_tool for 5 seconds...
# ✅ Returned license (ID: abc123)
#    Available: 5/5
```

**Interactive session:**
```bash
python scripts/demo_client.py --url https://license-server-demo.fly.dev -i

>>> status
cad_tool: 5/5 available
simulation: 3/3 available
analysis: 2/2 available

>>> borrow cad_tool
✅ Borrowed cad_tool license (ID: xyz789)

>>> list
Borrowed licenses:
  cad_tool: xyz789

>>> return xyz789
✅ Returned license (ID: xyz789)

>>> quit
```

**Stress test:**
```bash
# Borrow and return 20 times
python scripts/demo_client.py --url https://license-server-demo.fly.dev --loop 20 --duration 2
```

### Features

- ✅ Connect to local or remote license server
- ✅ Borrow and return licenses
- ✅ Check license status
- ✅ Interactive mode for manual testing
- ✅ Simulation mode for automated testing
- ✅ Loop mode for stress testing
- ✅ Custom user identification
- ✅ Full error handling

### Use Cases

1. **Demo to stakeholders** - Run the interactive client while screen sharing
2. **Load testing** - Use `--loop` to generate traffic and test observability
3. **Integration testing** - Verify API endpoints work correctly
4. **Multi-user simulation** - Run multiple clients with different `--user` values
5. **CI/CD validation** - Test deployed instance after each deployment

## Deploy to Fly.io

To get your public endpoint:

```bash
# Login to Fly.io
flyctl auth login

# Create the volume (first time only)
flyctl volumes create license_data --region fra --size 1

# Deploy
flyctl deploy

# Get your public URL
flyctl status

# Your app will be available at:
# https://license-server-demo.fly.dev
```

### Check deployment:

```bash
# View logs
flyctl logs

# Check status
flyctl status

# Open in browser
flyctl open

# SSH into the machine
flyctl ssh console
```

### Update deployment:

```bash
# After making changes
git push origin main

# Redeploy
flyctl deploy
```

## Troubleshooting

**Connection refused:**
- Make sure the server is running
- Check the URL (http vs https)
- Verify firewall settings

**No available licenses:**
- Check license pool status: `status cad_tool`
- Wait for licenses to be returned
- Increase license pool in configuration

**Timeout errors:**
- The Fly.io app may be sleeping (auto_stop_machines=true)
- First request will wake it up (takes ~5 seconds)
- Subsequent requests will be fast


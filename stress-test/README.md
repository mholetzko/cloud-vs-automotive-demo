# License Server Stress Testing Tool

High-performance stress testing tool built with Rust for parallel license operations.

## 🚀 Features

- ⚡ **Parallel Execution**: Concurrent workers using Tokio async runtime
- 📊 **Real-time Progress**: Visual progress bars for each worker
- 🎯 **Configurable Load**: Light to extreme load profiles
- 🔄 **Multiple Modes**: Full-cycle, checkout-only, or custom
- 📈 **Detailed Metrics**: Success rates, throughput, timing stats
- 🌈 **Beautiful Output**: Colored terminal output with progress tracking

## 🏃 Quick Start

### Interactive Launcher (Recommended)

```bash
cd stress-test
./run_stress_test.sh
```

This will:
1. Build the Rust binary (release mode)
2. Let you select target (localhost/Fly.io/custom)
3. Let you choose load profile (light/medium/heavy/extreme)
4. Run the stress test with real-time progress
5. Display detailed results

### Manual Usage

```bash
cd stress-test
cargo build --release

# Light test on localhost
./target/release/stress \
    --url http://localhost:8000 \
    --workers 5 \
    --operations 20

# Heavy test on Fly.io
./target/release/stress \
    --url https://license-server-demo.fly.dev \
    --workers 50 \
    --operations 200 \
    --hold-time 0.1 \
    --ramp-up 10
```

## 📋 Load Profiles

### Light Load (100 ops)
- **Workers**: 5
- **Operations**: 20 per worker
- **Use case**: Quick validation, CI testing

### Medium Load (500 ops)
- **Workers**: 10
- **Operations**: 50 per worker
- **Use case**: Demo scenarios, moderate testing

### Heavy Load (2,000 ops)
- **Workers**: 20
- **Operations**: 100 per worker
- **Use case**: Performance testing, load validation

### Extreme Load (10,000 ops)
- **Workers**: 50
- **Operations**: 200 per worker
- **Use case**: Stress testing, finding breaking points

## ⚙️ Command Line Options

```
Options:
  -u, --url <URL>              Server URL [default: http://localhost:8000]
  -w, --workers <WORKERS>      Number of concurrent workers [default: 10]
  -n, --operations <OPS>       Total operations per worker [default: 100]
  -t, --tool <TOOL>            Tool to test (cad_tool, ide_tool, sim_tool, random) [default: random]
  -H, --hold-time <SECONDS>    Hold time in seconds [default: 1]
  -m, --mode <MODE>            Test mode: checkout-only, full-cycle [default: full-cycle]
  -r, --ramp-up <SECONDS>      Ramp-up time in seconds [default: 0]
  -h, --help                   Print help
  -V, --version                Print version
```

## 🎯 Test Modes

### Full Cycle (Default)
Borrow → Hold → Return

Each worker borrows a license, holds it for the specified time, then returns it. This simulates real-world usage patterns.

### Checkout Only
Borrow and keep

Workers borrow licenses without returning them. Useful for testing overage limits and availability exhaustion.

## 📊 Example Output

```
╔══════════════════════════════════════════════════════════╗
║   License Server Stress Test                             ║
╚══════════════════════════════════════════════════════════╝

Configuration:
  Server:      https://license-server-demo.fly.dev
  Workers:     10
  Operations:  50 per worker
  Total Ops:   500
  Tool:        random
  Hold Time:   1s
  Mode:        full-cycle
  Ramp-up:     2s

🔍 Checking server status... ✓
   cad_tool → 100 total, 0 borrowed, 100 available
   ide_tool → 50 total, 0 borrowed, 50 available
   sim_tool → 30 total, 0 borrowed, 30 available

🚀 Starting stress test...

[████████████████████████████████████████] 50/50 Worker 0 completed
[████████████████████████████████████████] 50/50 Worker 1 completed
...

╔══════════════════════════════════════════════════════════╗
║   Test Results                                           ║
╚══════════════════════════════════════════════════════════╝

Performance:
  Total Time:         65.32s
  Throughput:         15.31 ops/sec

Borrow Operations:
  Successful:         500 ✓
  Failed:             0 ✓
  Success Rate:       100.00%

Return Operations:
  Successful:         500 ✓
  Failed:             0 ✓
  Success Rate:       100.00%

Final Server Status:
  cad_tool → 100 total, 0 borrowed, 100 available
  ide_tool → 50 total, 0 borrowed, 50 available
  sim_tool → 30 total, 0 borrowed, 30 available

🎉 All operations completed successfully!
```

## 🔧 Requirements

- Rust 1.70+ (install from https://rustup.rs/)
- Cargo (comes with Rust)

## 📈 Use Cases

### 1. Performance Benchmarking
```bash
./run_stress_test.sh
# Choose "Heavy Load" to measure max throughput
```

### 2. Overage Testing
```bash
cargo run --release -- \
    --workers 50 \
    --operations 10 \
    --mode checkout-only \
    --tool cad_tool
# Exhaust licenses and trigger overage
```

### 3. Gradual Load Ramp
```bash
cargo run --release -- \
    --workers 20 \
    --operations 100 \
    --ramp-up 10
# Workers start gradually over 10 seconds
```

### 4. CI Integration
```bash
# Quick smoke test
cargo run --release -- \
    --workers 3 \
    --operations 5 \
    --hold-time 0.1
```

## 🎯 Monitoring

While the stress test runs, monitor:

- **Grafana Dashboards**: License usage, overage, costs
- **Prometheus Metrics**: Real-time throughput
- **Application Logs**: Borrow/return events
- **Loki Logs**: Error traces

## 🐛 Troubleshooting

### Connection Refused
```bash
# Check if server is running
curl http://localhost:8000/licenses/status

# Or for Fly.io
curl https://license-server-demo.fly.dev/licenses/status
```

### High Failure Rate
- Reduce `--workers` or `--operations`
- Increase `--ramp-up` time
- Check server capacity
- Review server logs

### Build Errors
```bash
# Update Rust
rustup update

# Clean build
cargo clean
cargo build --release
```

## 📝 Notes

- The tool uses async I/O for maximum concurrency
- Progress bars update in real-time
- Stats are aggregated from all workers
- Ramp-up spreads worker starts evenly over the specified time
- Random tool selection is truly random (uses thread RNG)

## 🎨 Output Colors

- 🔵 **Blue**: Headers, info
- 🟢 **Green**: Success, available licenses
- 🟡 **Yellow**: Labels, warnings
- 🔴 **Red**: Errors, borrowed licenses

## 🚀 Advanced Examples

### Mixed Load Test
```bash
# 30% light, hold for 5s
cargo run --release -- -w 10 -n 30 -H 5 -t random

# 100% overage on one tool
cargo run --release -- -w 100 -n 5 -m checkout-only -t cad_tool
```

### Production Validation
```bash
# Run against Fly.io with realistic load
cargo run --release -- \
    --url https://license-server-demo.fly.dev \
    --workers 15 \
    --operations 50 \
    --hold-time 2 \
    --ramp-up 5 \
    --mode full-cycle
```

---

**Built with ❤️ using Rust + Tokio**


# Performance Testing Plan

## Overview

This document outlines the comprehensive performance testing strategy for remote monitoring of the Linux server, including testing methodology, tools, metrics, and procedures.

## Testing Objectives

### Primary Goals

1. **Establish Baseline Performance:** Document normal system resource consumption
2. **Identify Resource Bottlenecks:** Determine system limitations under various workloads
3. **Validate Monitoring Capabilities:** Ensure remote monitoring tools function correctly
4. **Test Under Load:** Evaluate system behavior under stress conditions
5. **Document Performance Characteristics:** Create reference data for future comparisons

## Remote Monitoring Methodology

### Monitoring Architecture

```
┌───────────────────────┐
│   Admin Workstation    │
│   (192.168.1.20)      │
│                         │
│  ┌────────────────┐  │
│  │ Monitoring      │  │
│  │ Script          │  │
│  │ (monitor-       │  │
│  │  server.sh)     │  │
│  └────────┬────────┘  │
└────────────│───────────┘
               │
               │ SSH Connection
               │ (Encrypted)
               │
     ┌─────────▼─────────┐
     │  Production Server │
     │  (192.168.1.10)    │
     │                     │
     │  ┌─────────────┐  │
     │  │ Metrics      │  │
     │  │ Collection   │  │
     │  │ - CPU        │  │
     │  │ - Memory     │  │
     │  │ - Disk I/O   │  │
     │  │ - Network    │  │
     │  │ - Processes  │  │
     │  └─────────────┘  │
     └───────────────────┘
```

### Monitoring Approach

**Pull-Based Monitoring:**
- Workstation initiates SSH connections to server
- Executes monitoring commands remotely
- Collects metrics and displays/logs locally
- No agent installation required on server

**Advantages:**
- Minimal server resource overhead
- Centralized monitoring from workstation
- Secure SSH-based communication
- Easy to implement and maintain

## Performance Metrics

### 1. CPU Metrics

**Metrics to Collect:**
- Overall CPU utilization (%)
- Per-core CPU usage
- Load average (1, 5, 15 minutes)
- Process CPU consumption
- CPU wait time (I/O wait)
- System vs. user CPU time

**Collection Commands:**
```bash
# Current CPU usage
top -bn1 | grep "Cpu(s)" | awk '{print $2}'

# Load average
uptime | awk -F'load average:' '{print $2}'

# Per-core usage
mpstat -P ALL 1 1

# Top CPU-consuming processes
ps aux --sort=-%cpu | head -10
```

**Thresholds:**
- Normal: 0-70% utilization
- Warning: 70-90% utilization
- Critical: >90% utilization
- Load Average: Should be < number of CPU cores

### 2. Memory Metrics

**Metrics to Collect:**
- Total/Used/Free RAM
- Memory utilization percentage
- Buffer/Cache usage
- Swap usage and activity
- Available memory
- Top memory-consuming processes

**Collection Commands:**
```bash
# Memory summary
free -m | awk 'NR==2{printf "Memory Usage: %.2f%%", $3*100/$2}'

# Detailed memory
free -h

# Swap activity
vmstat 1 5

# Top memory consumers
ps aux --sort=-%mem | head -10
```

**Thresholds:**
- Normal: <80% memory utilization
- Warning: 80-95% memory utilization
- Critical: >95% memory utilization
- Swap: Minimal swap usage is ideal (<10% of total)

### 3. Disk I/O Metrics

**Metrics to Collect:**
- Disk space usage per partition
- I/O operations per second (IOPS)
- Read/Write throughput (MB/s)
- Disk latency
- I/O wait percentage
- Top disk-using processes

**Collection Commands:**
```bash
# Disk space
df -h | grep -E "/$|/boot"

# Disk I/O statistics
iostat -x 1 5

# Per-process I/O
sudo iotop -bn1

# Disk usage by directory
sudo du -sh /var /usr /home /tmp
```

**Thresholds:**
- Normal: <80% disk space used
- Warning: 80-90% disk space used
- Critical: >90% disk space used
- IOPS: Depends on workload and hardware

### 4. Network Metrics

**Metrics to Collect:**
- Bandwidth utilization (RX/TX)
- Packets per second
- Network errors and drops
- Active connections count
- Network latency
- Top bandwidth-consuming processes

**Collection Commands:**
```bash
# Network statistics
ip -s link

# Bandwidth per interface
sar -n DEV 1 5

# Active connections
ss -s

# Connection details
netstat -tuln

# Top network consumers
sudo nethogs -t -d 1
```

**Thresholds:**
- Packet loss: <0.1% acceptable
- Network errors: Should be minimal
- Latency: <10ms on local network

### 5. System Metrics

**Metrics to Collect:**
- System uptime
- Running processes count
- Failed services
- Login sessions
- System temperature (if available)
- Journal/Log errors

**Collection Commands:**
```bash
# Uptime
uptime

# Process count
ps aux | wc -l

# Failed services
systemctl --failed

# Active users
w

# Recent errors
journalctl -p err -n 20 --no-pager
```

## Testing Methodology

### Phase 1: Baseline Testing (No Load)

**Objective:** Establish normal system behavior

**Procedure:**
1. Ensure server is in idle state (no active workloads)
2. Run monitoring script for 10 minutes
3. Collect metrics every 30 seconds
4. Document baseline values

**Expected Results:**
- CPU: <5% utilization
- Memory: ~1-2 GB used
- Disk I/O: Minimal activity
- Network: <1 Mbps

### Phase 2: Application-Specific Testing

**Objective:** Measure resource consumption of specific applications

**Procedure:**
1. Start baseline monitoring
2. Launch specific application (e.g., web server, database)
3. Monitor for 5 minutes (idle application)
4. Generate application-specific load
5. Monitor for 10 minutes under load
6. Document resource usage patterns

**Applications to Test:**
- CPU-intensive: Stress testing, compilation
- Memory-intensive: Database operations, caching
- I/O-intensive: File operations, backups
- Network-intensive: Web server, file transfers

### Phase 3: Stress Testing

**Objective:** Determine system limits and behavior under extreme load

**Procedure:**
1. Run baseline monitoring
2. Apply stress using `stress` or `stress-ng` tool
3. Monitor system behavior
4. Document when system becomes unresponsive
5. Identify resource bottlenecks

**Stress Test Scenarios:**

```bash
# CPU stress (all cores, 5 minutes)
stress --cpu $(nproc) --timeout 300s

# Memory stress (80% of RAM)
stress --vm 2 --vm-bytes $(awk '/MemTotal/{printf "%d\n", $2*0.8}' < /proc/meminfo)K --timeout 300s

# Disk I/O stress
stress --io 4 --hdd 2 --timeout 300s

# Combined stress
stress-ng --cpu 4 --io 2 --vm 2 --vm-bytes 1G --timeout 5m
```

### Phase 4: Endurance Testing

**Objective:** Verify system stability over extended periods

**Procedure:**
1. Apply moderate load (50-60% resource utilization)
2. Run for 24-48 hours
3. Monitor for memory leaks
4. Check for performance degradation
5. Verify system stability

## Monitoring Tools

### Native Linux Tools

| Tool | Purpose | Installation |
|------|---------|-------------|
| `top` | Real-time process monitoring | Pre-installed |
| `htop` | Enhanced process viewer | `sudo apt install htop` |
| `vmstat` | Virtual memory statistics | Pre-installed |
| `iostat` | I/O statistics | `sudo apt install sysstat` |
| `sar` | System activity reporter | `sudo apt install sysstat` |
| `iftop` | Network bandwidth monitoring | `sudo apt install iftop` |
| `nethogs` | Per-process network usage | `sudo apt install nethogs` |
| `iotop` | Per-process I/O usage | `sudo apt install iotop` |
| `stress` | CPU/memory/I/O stress testing | `sudo apt install stress` |
| `stress-ng` | Advanced stress testing | `sudo apt install stress-ng` |

### Installation Script

```bash
#!/bin/bash
# install-monitoring-tools.sh

echo "Installing performance monitoring tools..."

sudo apt update
sudo apt install -y \
    htop \
    sysstat \
    iftop \
    nethogs \
    iotop \
    stress \
    stress-ng \
    net-tools \
    dstat \
    nmon

# Enable sysstat data collection
sudo systemctl enable sysstat
sudo systemctl start sysstat

echo "Installation complete!"
echo "Run 'htop', 'iotop', 'iftop' to start monitoring"
```

## Remote Monitoring Script Design

### Script Requirements

1. **SSH-Based Execution:** Run from workstation, connect to server via SSH
2. **Comprehensive Metrics:** Collect all key performance indicators
3. **Configurable:** Easy to adjust monitoring interval and duration
4. **Output Options:** Display to screen and/or log to file
5. **Error Handling:** Graceful handling of connection issues
6. **Timestamping:** All metrics tagged with timestamp

### Script Structure

```bash
#!/bin/bash
# monitor-server.sh - Remote server monitoring script

# Configuration
SERVER_HOST="192.168.1.10"
SERVER_USER="admin"
MONITOR_INTERVAL=30  # seconds
LOG_FILE="monitoring-$(date +%Y%m%d-%H%M%S).log"

# Functions
function collect_cpu_metrics() {
    # SSH and collect CPU data
}

function collect_memory_metrics() {
    # SSH and collect memory data
}

function collect_disk_metrics() {
    # SSH and collect disk data
}

function collect_network_metrics() {
    # SSH and collect network data
}

function display_metrics() {
    # Format and display collected metrics
}

# Main monitoring loop
while true; do
    collect_all_metrics
    display_metrics
    log_metrics
    sleep $MONITOR_INTERVAL
done
```

## Testing Schedule

### Week 1: Setup and Baseline
- Day 1-2: Install monitoring tools
- Day 3-4: Configure remote monitoring
- Day 5-7: Collect baseline metrics

### Week 2: Application Testing
- Day 1-2: Test CPU-intensive applications
- Day 3-4: Test memory-intensive applications
- Day 5-7: Test I/O-intensive applications

### Week 3: Stress Testing
- Day 1-2: CPU stress tests
- Day 3-4: Memory stress tests
- Day 5-7: Combined stress tests

### Week 4: Endurance Testing
- Day 1-7: 24/7 monitoring under moderate load

## Data Collection and Analysis

### Data Storage Format

```csv
timestamp,cpu_percent,mem_percent,disk_percent,network_rx_mbps,network_tx_mbps,load_avg_1m,load_avg_5m,load_avg_15m
2024-01-15 10:00:00,25.5,45.2,15,12.5,8.3,1.2,0.9,0.7
2024-01-15 10:00:30,28.1,45.8,15,15.2,10.1,1.3,1.0,0.8
```

### Analysis Metrics

1. **Average Resource Utilization:** Mean values over test period
2. **Peak Resource Utilization:** Maximum values observed
3. **Resource Utilization Distribution:** Percentiles (50th, 95th, 99th)
4. **Correlation Analysis:** Relationships between metrics
5. **Trend Analysis:** Performance changes over time

### Reporting Template

```markdown
## Performance Test Report

**Test Date:** YYYY-MM-DD
**Test Type:** [Baseline/Application/Stress/Endurance]
**Duration:** X hours

### System Configuration
- CPU: X cores
- RAM: X GB
- Disk: X GB

### Results Summary
| Metric | Baseline | Average | Peak | 95th Percentile |
|--------|----------|---------|------|----------------|
| CPU %  |          |         |      |                |
| Memory %|         |         |      |                |
| Disk I/O|         |         |      |                |
| Network |         |         |      |                |

### Observations
- Finding 1
- Finding 2

### Recommendations
- Recommendation 1
- Recommendation 2
```

## Performance Thresholds and Alerts

### Alert Levels

```yaml
CPU:
  warning: 70%
  critical: 90%
  
Memory:
  warning: 80%
  critical: 95%
  
Disk:
  warning: 80%
  critical: 90%
  
Swap:
  warning: 10%  # of total RAM
  critical: 50%
  
Load Average:
  warning: num_cores * 0.8
  critical: num_cores * 1.5
```

## Troubleshooting Common Issues

### High CPU Usage
```bash
# Identify top CPU consumers
top -bn1 | head -20
ps aux --sort=-%cpu | head -10

# Check for runaway processes
top -bn1 -o %CPU | head -15
```

### High Memory Usage
```bash
# Memory details
free -h
cat /proc/meminfo

# Top memory consumers
ps aux --sort=-%mem | head -10

# Check for memory leaks
sudo cat /proc/$(pgrep -f <process>)/status | grep Vm
```

### High Disk I/O
```bash
# I/O statistics
iostat -x 1 5

# Process I/O
sudo iotop -o

# Find large files
sudo find / -type f -size +100M 2>/dev/null
```

## Conclusion

This performance testing plan provides:

1. ✅ **Comprehensive Coverage:** All critical metrics monitored
2. ✅ **Remote Monitoring:** SSH-based, minimal server overhead
3. ✅ **Multiple Test Phases:** Baseline, application, stress, endurance
4. ✅ **Clear Methodology:** Step-by-step procedures
5. ✅ **Actionable Results:** Thresholds and recommendations

Following this plan ensures thorough understanding of system performance characteristics and capabilities.

## References

- Linux Performance Tools: http://www.brendangregg.com/linuxperf.html
- sysstat Documentation: https://github.com/sysstat/sysstat
- Performance Co-Pilot: https://pcp.io/

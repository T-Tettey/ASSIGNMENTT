# Monitoring Strategy

## Overview

This document outlines the comprehensive monitoring strategy for performance testing, including tools, methodologies, data collection procedures, and analysis approaches.

---

## Monitoring Architecture

### Remote Monitoring Model

```
┌─────────────────────────────────────┐
│     Admin Workstation               │
│     (192.168.1.20)                 │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  Monitoring Control Center    │ │
│  │  - Execute scripts via SSH    │ │
│  │  - Collect metrics            │ │
│  │  - Store data locally         │ │
│  │  - Generate reports           │ │
│  └──────────────┬────────────────┘ │
└─────────────────┼──────────────────┘
                  │
                  │ SSH Connection (Port 22)
                  │ Encrypted Channel
                  │
┌─────────────────▼──────────────────┐
│     Production Server               │
│     (192.168.1.10)                 │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  Metrics Sources              │ │
│  │  - /proc/* (CPU, Memory)     │ │
│  │  - /sys/* (Hardware info)    │ │
│  │  - iostat (Disk I/O)         │ │
│  │  - ss/netstat (Network)      │ │
│  │  - systemd (Services)        │ │
│  │  - Application logs          │ │
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
```

---

## Monitoring Tools Matrix

### Native Linux Tools

| Tool | Purpose | Metrics | Update Interval | Output Format |
|------|---------|---------|-----------------|---------------|
| **top** | Process monitoring | CPU, Memory, Load | Real-time | Text |
| **htop** | Enhanced process viewer | CPU, Memory, Processes | Real-time | Interactive |
| **free** | Memory usage | RAM, Swap | On-demand | Text |
| **vmstat** | Virtual memory stats | CPU, Memory, I/O | 1-60s | Text |
| **iostat** | I/O statistics | Disk throughput, IOPS | 1-60s | Text |
| **mpstat** | Per-CPU statistics | CPU per core | 1-60s | Text |
| **sar** | System activity report | All resources | 1-600s | Text/Binary |
| **ss** | Socket statistics | Network connections | On-demand | Text |
| **iftop** | Network bandwidth | Real-time bandwidth | Real-time | Interactive |
| **nethogs** | Per-process network | Process bandwidth | Real-time | Interactive |
| **iotop** | Per-process I/O | Process I/O | Real-time | Interactive |
| **ps** | Process status | Process details | On-demand | Text |
| **uptime** | System load | Load average | On-demand | Text |
| **df** | Disk space | Filesystem usage | On-demand | Text |
| **du** | Disk usage | Directory sizes | On-demand | Text |

### Installation Commands

```bash
# SSH to server
ssh admin@192.168.1.10

# Install monitoring tools
sudo apt update
sudo apt install -y \
    htop \
    sysstat \
    iftop \
    nethogs \
    iotop \
    dstat \
    nmon \
    atop \
    glances

# Enable sysstat for historical data
sudo systemctl enable sysstat
sudo systemctl start sysstat

# Configure sysstat collection interval
sudo vim /etc/cron.d/sysstat
# Change to collect every 1 minute (default is 10)
```

---

## Monitoring Metrics

### 1. CPU Metrics

**What to Monitor:**
- Overall CPU utilization (%)
- Per-core CPU usage
- User vs System CPU time
- I/O wait time
- Load average (1, 5, 15 minutes)
- Context switches
- Interrupts

**Collection Commands:**

```bash
# Overall CPU utilization
top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}'

# Per-core usage
mpstat -P ALL 1 1 | grep -v "^$"

# Load average
uptime | awk -F'load average:' '{print $2}'

# Detailed CPU stats
sar -u 1 10

# Top CPU consuming processes
ps aux --sort=-%cpu | head -10

# CPU info
lscpu
```

**Thresholds:**
- Normal: 0-70%
- Warning: 70-90%
- Critical: >90%
- Load Average: Should be < number of cores

---

### 2. Memory Metrics

**What to Monitor:**
- Total/Used/Free RAM
- Memory utilization percentage
- Buffer and cache usage
- Available memory
- Swap usage
- Swap in/out rate
- Page faults
- OOM killer activity

**Collection Commands:**

```bash
# Memory summary
free -h

# Memory percentage
free | awk 'NR==2{printf "%.2f%%", $3*100/$2}'

# Detailed memory
cat /proc/meminfo

# Swap activity
vmstat 1 5

# Top memory consumers
ps aux --sort=-%mem | head -10

# Available memory
free -h | awk 'NR==2{print $7}'

# Memory pressure
cat /proc/pressure/memory
```

**Thresholds:**
- Normal: <80% RAM used
- Warning: 80-95%
- Critical: >95%
- Swap: Should be minimal (<10%)

---

### 3. Disk I/O Metrics

**What to Monitor:**
- Disk utilization (%)
- Read/Write throughput (MB/s)
- IOPS (reads/writes per second)
- Average I/O wait time
- Disk queue length
- Disk space usage
- Inode usage

**Collection Commands:**

```bash
# Disk I/O statistics
iostat -x 1 5

# Per-device I/O
iostat -dx 1 5

# Disk space
df -h

# Inode usage
df -i

# Top I/O processes
sudo iotop -bn1 | head -20

# Disk usage by directory
sudo du -sh /* 2>/dev/null | sort -hr | head -10

# I/O wait percentage
vmstat 1 5 | awk '{print $16}'
```

**Thresholds:**
- Disk Space Normal: <80%
- Disk Space Warning: 80-90%
- Disk Space Critical: >90%
- I/O Wait Normal: <10%
- I/O Wait Warning: 10-30%
- I/O Wait Critical: >30%

---

### 4. Network Metrics

**What to Monitor:**
- Bandwidth utilization (TX/RX)
- Packets per second
- Network errors
- Dropped packets
- Retransmissions
- Active connections
- Connection states
- Latency/RTT

**Collection Commands:**

```bash
# Network statistics
ip -s link

# Bandwidth per interface
sar -n DEV 1 5

# Connection summary
ss -s

# Active connections
ss -tuln

# Connection count by state
netstat -ant | awk '{print $6}' | sort | uniq -c

# Real-time bandwidth (requires iftop)
sudo iftop -t -s 10 -i enp0s8

# Per-process network usage
sudo nethogs -t -d 5

# Network errors
ip -s -s link show enp0s8
```

**Thresholds:**
- Bandwidth: Monitor against line speed
- Packet Loss: <0.1% acceptable
- Errors: Should be minimal
- Latency (local): <10ms

---

### 5. System Metrics

**What to Monitor:**
- System uptime
- Process count
- Open file descriptors
- Failed services
- Kernel messages
- Log errors
- Temperature (if available)
- Power state

**Collection Commands:**

```bash
# System uptime
uptime

# Process count
ps aux | wc -l

# Open files
lsof | wc -l

# Failed services
systemctl --failed

# System logs (errors)
journalctl -p err -n 20 --no-pager

# Kernel messages
dmesg -T | tail -20

# Temperature (if sensors available)
sensors

# System information
hostnamectl
```

---

## Monitoring Approaches

### Approach 1: Manual Spot Checks

**When to Use**: Quick health checks, troubleshooting

```bash
#!/bin/bash
# quick-check.sh

echo "=== Quick System Check ==="
echo ""
echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')%"
echo "Memory: $(free | awk 'NR==2{printf "%.2f%%", $3*100/$2}')"
echo "Disk: $(df -h / | awk 'NR==2{print $5}')"
echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
echo "Processes: $(ps aux | wc -l)"
echo "Uptime: $(uptime -p)"
```

---

### Approach 2: Continuous Monitoring

**When to Use**: During performance tests, production monitoring

```bash
#!/bin/bash
# continuous-monitor.sh

INTERVAL=30  # seconds
LOG_FILE="monitoring-$(date +%Y%m%d-%H%M%S).log"

echo "Starting continuous monitoring (interval: ${INTERVAL}s)"
echo "Logging to: ${LOG_FILE}"
echo ""

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Collect metrics
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    MEM=$(free | awk 'NR==2{printf "%.2f", $3*100/$2}')
    DISK=$(df -h / | awk 'NR==2{print $5}' | tr -d '%')
    LOAD=$(cat /proc/loadavg | awk '{print $1,$2,$3}')
    
    # Log to file
    echo "${TIMESTAMP},${CPU},${MEM},${DISK},${LOAD}" >> "${LOG_FILE}"
    
    # Display to console
    printf "%s | CPU: %5.2f%% | MEM: %5.2f%% | DISK: %3s%% | LOAD: %s\n" \
        "${TIMESTAMP}" "${CPU}" "${MEM}" "${DISK}" "${LOAD}"
    
    sleep ${INTERVAL}
done
```

---

### Approach 3: Remote SSH-Based Monitoring

**When to Use**: Monitoring from workstation

```bash
#!/bin/bash
# remote-monitor.sh (run on workstation)

SERVER="192.168.1.10"
USER="admin"
INTERVAL=30
LOG_FILE="remote-monitoring-$(date +%Y%m%d-%H%M%S).csv"

echo "Remote monitoring of ${SERVER}"
echo "Interval: ${INTERVAL}s"
echo "Log file: ${LOG_FILE}"
echo ""

# CSV header
echo "Timestamp,CPU%,Memory%,DiskUsed%,Load1m,Load5m,Load15m,Processes,Connections" > "${LOG_FILE}"

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Collect metrics via SSH
    METRICS=$(ssh ${USER}@${SERVER} '
        CPU=$(top -bn1 | grep "Cpu(s)" | awk "{print \$2 + \$4}")
        MEM=$(free | awk "NR==2{printf \"%.2f\", \$3*100/\$2}")
        DISK=$(df -h / | awk "NR==2{print \$5}" | tr -d "%")
        LOAD=$(cat /proc/loadavg | awk "{print \$1,\$2,\$3}")
        PROCS=$(ps aux | wc -l)
        CONNS=$(ss -s | grep "TCP:" | awk "{print \$2}")
        
        echo "${CPU},${MEM},${DISK},${LOAD},${PROCS},${CONNS}"
    ')
    
    # Log to file
    echo "${TIMESTAMP},${METRICS}" >> "${LOG_FILE}"
    
    # Display
    echo "${TIMESTAMP} | ${METRICS}"
    
    sleep ${INTERVAL}
done
```

---

### Approach 4: Application-Specific Monitoring

**When to Use**: Testing specific applications

```bash
#!/bin/bash
# app-monitor.sh

APP_NAME="$1"  # e.g., "nginx", "postgres", "redis"
INTERVAL=10
DURATION=300  # 5 minutes

if [ -z "$APP_NAME" ]; then
    echo "Usage: $0 <application_name>"
    exit 1
fi

LOG_FILE="${APP_NAME}-monitoring-$(date +%Y%m%d-%H%M%S).log"

echo "Monitoring ${APP_NAME} for ${DURATION} seconds"
echo "Interval: ${INTERVAL}s"
echo ""

END_TIME=$(($(date +%s) + DURATION))

while [ $(date +%s) -lt $END_TIME ]; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Get PIDs of application
    PIDS=$(pgrep -f "${APP_NAME}")
    
    if [ -z "$PIDS" ]; then
        echo "${TIMESTAMP} | Application not running"
        sleep ${INTERVAL}
        continue
    fi
    
    # Collect metrics for each PID
    for PID in $PIDS; do
        CPU=$(ps -p ${PID} -o %cpu= 2>/dev/null)
        MEM=$(ps -p ${PID} -o %mem= 2>/dev/null)
        RSS=$(ps -p ${PID} -o rss= 2>/dev/null)
        THREADS=$(ps -p ${PID} -o nlwp= 2>/dev/null)
        
        if [ -n "$CPU" ]; then
            printf "%s | PID: %5s | CPU: %5.1f%% | MEM: %5.1f%% | RSS: %8s KB | Threads: %3s\n" \
                "${TIMESTAMP}" "${PID}" "${CPU}" "${MEM}" "${RSS}" "${THREADS}" | \
                tee -a "${LOG_FILE}"
        fi
    done
    
    sleep ${INTERVAL}
done

echo ""
echo "Monitoring complete. Log saved to: ${LOG_FILE}"
```

---

## Monitoring Workflow

### Phase 1: Pre-Test Baseline

**Objective**: Establish system baseline before testing

```bash
#!/bin/bash
# baseline-capture.sh

BASELINE_DIR="baseline-$(date +%Y%m%d-%H%M%S)"
mkdir -p "${BASELINE_DIR}"

echo "Capturing baseline metrics..."

# System information
uname -a > "${BASELINE_DIR}/system-info.txt"
lscpu > "${BASELINE_DIR}/cpu-info.txt"
free -h > "${BASELINE_DIR}/memory-info.txt"
df -h > "${BASELINE_DIR}/disk-info.txt"
ip addr > "${BASELINE_DIR}/network-info.txt"

# Resource usage (5 minute average)
echo "Collecting 5-minute baseline..."
sar -u 60 5 > "${BASELINE_DIR}/cpu-baseline.txt"
sar -r 60 5 > "${BASELINE_DIR}/memory-baseline.txt"
sar -d 60 5 > "${BASELINE_DIR}/disk-baseline.txt"
sar -n DEV 60 5 > "${BASELINE_DIR}/network-baseline.txt"

# Process list
ps aux > "${BASELINE_DIR}/processes.txt"

# Services
systemctl list-units --type=service --state=running > "${BASELINE_DIR}/services.txt"

echo "Baseline captured in: ${BASELINE_DIR}"
```

---

### Phase 2: During-Test Monitoring

**Objective**: Continuous monitoring during performance tests

```bash
#!/bin/bash
# during-test-monitor.sh

TEST_NAME="$1"
if [ -z "$TEST_NAME" ]; then
    echo "Usage: $0 <test_name>"
    exit 1
fi

TEST_DIR="test-${TEST_NAME}-$(date +%Y%m%d-%H%M%S)"
mkdir -p "${TEST_DIR}"

echo "Starting monitoring for test: ${TEST_NAME}"
echo "Output directory: ${TEST_DIR}"
echo ""
echo "Press Ctrl+C to stop monitoring"
echo ""

# Start background monitoring processes
sar -u 5 > "${TEST_DIR}/cpu.log" 2>&1 &
SAR_CPU_PID=$!

sar -r 5 > "${TEST_DIR}/memory.log" 2>&1 &
SAR_MEM_PID=$!

sar -d 5 > "${TEST_DIR}/disk.log" 2>&1 &
SAR_DISK_PID=$!

sar -n DEV 5 > "${TEST_DIR}/network.log" 2>&1 &
SAR_NET_PID=$!

# Cleanup function
cleanup() {
    echo ""
    echo "Stopping monitoring..."
    kill ${SAR_CPU_PID} ${SAR_MEM_PID} ${SAR_DISK_PID} ${SAR_NET_PID} 2>/dev/null
    echo "Data saved to: ${TEST_DIR}"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Real-time display
while true; do
    clear
    echo "=== Test: ${TEST_NAME} ==="
    echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "CPU:"
    top -bn1 | grep "Cpu(s)" | head -1
    echo ""
    echo "Memory:"
    free -h | grep -E "Mem:|Swap:"
    echo ""
    echo "Disk I/O:"
    iostat -x 1 1 | grep -E "Device|sda"
    echo ""
    echo "Network:"
    sar -n DEV 1 1 | grep -E "IFACE|enp0s"
    echo ""
    echo "Top Processes:"
    ps aux --sort=-%cpu | head -6
    
    sleep 5
done
```

---

### Phase 3: Post-Test Analysis

**Objective**: Analyze collected data and generate reports

```bash
#!/bin/bash
# analyze-test-data.sh

TEST_DIR="$1"

if [ -z "$TEST_DIR" ] || [ ! -d "$TEST_DIR" ]; then
    echo "Usage: $0 <test_directory>"
    exit 1
fi

REPORT_FILE="${TEST_DIR}/analysis-report.txt"

echo "Analyzing test data from: ${TEST_DIR}"
echo "" > "${REPORT_FILE}"

echo "=== Test Analysis Report ===" >> "${REPORT_FILE}"
echo "Generated: $(date)" >> "${REPORT_FILE}"
echo "Test Directory: ${TEST_DIR}" >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"

# CPU Analysis
if [ -f "${TEST_DIR}/cpu.log" ]; then
    echo "--- CPU Statistics ---" >> "${REPORT_FILE}"
    echo "Average CPU Usage:" >> "${REPORT_FILE}"
    grep -v "^$" "${TEST_DIR}/cpu.log" | grep -v "Linux" | grep -v "CPU" | \
        awk '{sum+=$3} END {if(NR>0) print "User: " sum/NR "%"}' >> "${REPORT_FILE}"
    grep -v "^$" "${TEST_DIR}/cpu.log" | grep -v "Linux" | grep -v "CPU" | \
        awk '{sum+=$5} END {if(NR>0) print "System: " sum/NR "%"}' >> "${REPORT_FILE}"
    echo "" >> "${REPORT_FILE}"
fi

# Memory Analysis
if [ -f "${TEST_DIR}/memory.log" ]; then
    echo "--- Memory Statistics ---" >> "${REPORT_FILE}"
    echo "Average Memory Usage:" >> "${REPORT_FILE}"
    grep -v "^$" "${TEST_DIR}/memory.log" | grep -v "Linux" | grep -v "kbmem" | \
        awk '{sum+=$4} END {if(NR>0) print "Used: " sum/NR " KB"}' >> "${REPORT_FILE}"
    echo "" >> "${REPORT_FILE}"
fi

echo "Analysis complete. Report saved to: ${REPORT_FILE}"
cat "${REPORT_FILE}"
```

---

## Data Collection Best Practices

### 1. Sampling Intervals

| Test Duration | Sampling Interval | Rationale |
|---------------|-------------------|------------|
| < 5 minutes | 1-5 seconds | Capture rapid changes |
| 5-30 minutes | 5-15 seconds | Balance detail and data volume |
| 30-60 minutes | 15-30 seconds | Reduce data volume |
| > 1 hour | 30-60 seconds | Long-term trends |
| 24+ hours | 1-5 minutes | Historical analysis |

### 2. Data Storage

```bash
# Organize data by test
monitoring-data/
├── baseline/
│   ├── 20240115-100000/
│   └── 20240115-140000/
├── cpu-tests/
│   ├── stress-ng-test1/
│   └── sysbench-test1/
├── memory-tests/
│   ├── redis-test1/
│   └── postgres-test1/
└── reports/
    ├── summary-20240115.txt
    └── analysis-20240115.pdf
```

### 3. Data Retention

- **Raw data**: 30 days
- **Aggregated data**: 90 days
- **Reports**: 1 year
- **Baseline**: Permanent

---

## Alerting and Thresholds

### Alert Levels

```bash
#!/bin/bash
# monitor-with-alerts.sh

# Thresholds
CPU_WARNING=70
CPU_CRITICAL=90
MEM_WARNING=80
MEM_CRITICAL=95
DISK_WARNING=80
DISK_CRITICAL=90

while true; do
    # Collect metrics
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}' | cut -d. -f1)
    MEM=$(free | awk 'NR==2{printf "%d", $3*100/$2}')
    DISK=$(df -h / | awk 'NR==2{print $5}' | tr -d '%')
    
    # Check CPU
    if [ $CPU -ge $CPU_CRITICAL ]; then
        echo "CRITICAL: CPU usage at ${CPU}%"
    elif [ $CPU -ge $CPU_WARNING ]; then
        echo "WARNING: CPU usage at ${CPU}%"
    fi
    
    # Check Memory
    if [ $MEM -ge $MEM_CRITICAL ]; then
        echo "CRITICAL: Memory usage at ${MEM}%"
    elif [ $MEM -ge $MEM_WARNING ]; then
        echo "WARNING: Memory usage at ${MEM}%"
    fi
    
    # Check Disk
    if [ $DISK -ge $DISK_CRITICAL ]; then
        echo "CRITICAL: Disk usage at ${DISK}%"
    elif [ $DISK -ge $DISK_WARNING ]; then
        echo "WARNING: Disk usage at ${DISK}%"
    fi
    
    sleep 30
done
```

---

## Visualization and Reporting

### Generate CSV for External Analysis

```bash
#!/bin/bash
# export-to-csv.sh

LOG_DIR="$1"
OUTPUT_CSV="metrics-$(date +%Y%m%d-%H%M%S).csv"

echo "Timestamp,CPU%,Memory%,DiskUsed%,Load1m,NetworkRxMbps,NetworkTxMbps" > "${OUTPUT_CSV}"

# Parse logs and create CSV
# (Implementation depends on log format)

echo "CSV exported to: ${OUTPUT_CSV}"
echo "Import into Excel, Google Sheets, or Grafana for visualization"
```

### Simple ASCII Charts

```bash
#!/bin/bash
# create-chart.sh

DATA_FILE="$1"

if [ -f "$DATA_FILE" ]; then
    echo "CPU Usage Over Time"
    echo "═══════════════════════════════════════════"
    
    while read line; do
        VALUE=$(echo "$line" | cut -d',' -f2 | cut -d'.' -f1)
        BARS=$((VALUE / 5))
        printf "%3d%% |" "$VALUE"
        for i in $(seq 1 $BARS); do
            printf "█"
        done
        echo ""
    done < "$DATA_FILE"
fi
```

---

## Monitoring Checklist

### Pre-Test
- [ ] All monitoring tools installed
- [ ] SSH connection tested
- [ ] Baseline metrics captured
- [ ] Storage space available for logs
- [ ] Test plan documented

### During Test
- [ ] Monitoring scripts running
- [ ] Data being logged correctly
- [ ] No monitoring tool failures
- [ ] Real-time display functioning
- [ ] Alerts configured (if applicable)

### Post-Test
- [ ] All data collected successfully
- [ ] Logs backed up
- [ ] Analysis scripts run
- [ ] Report generated
- [ ] Findings documented

---

## Troubleshooting Monitoring Issues

### Issue: SSH connection drops

```bash
# Solution: Use persistent SSH connection
ssh -o ServerAliveInterval=60 -o ServerAliveCountMax=3 admin@192.168.1.10

# Or in ~/.ssh/config:
Host prod-server
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

### Issue: Monitoring tools consume too many resources

```bash
# Solution: Reduce sampling frequency
# Instead of: sar -u 1
# Use: sar -u 5  # or higher

# Use batch mode for tools
top -bn1  # Instead of interactive mode
```

### Issue: Logs filling disk

```bash
# Solution: Log rotation and compression
sudo logrotate -f /etc/logrotate.conf

# Compress old logs
find monitoring-data/ -name "*.log" -mtime +7 -exec gzip {} \;
```

---

## Summary

This monitoring strategy provides:

1. **Comprehensive Coverage**: All major resource metrics
2. **Flexible Approaches**: Manual, continuous, remote, application-specific
3. **Practical Scripts**: Ready-to-use monitoring tools
4. **Best Practices**: Sampling intervals, data storage, alerting
5. **Analysis Workflows**: Pre-test, during-test, post-test

### Key Principles

- **Minimal Overhead**: Monitoring should not significantly impact performance
- **Reliable Collection**: Robust error handling and recovery
- **Actionable Data**: Metrics that inform decisions
- **Reproducible**: Consistent methodology across tests

---

## Next Steps

1. Install all monitoring tools on the server
2. Test monitoring scripts
3. Capture system baseline
4. Begin application testing with monitoring
5. Analyze results and document findings

---

## References

- Brendan Gregg's USE Method: http://www.brendangregg.com/usemethod.html
- Linux Performance Observability Tools: http://www.brendangregg.com/linuxperf.html
- sysstat Documentation: https://github.com/sysstat/sysstat
- Performance Co-Pilot: https://pcp.io/

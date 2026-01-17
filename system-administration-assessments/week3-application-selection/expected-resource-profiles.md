# Expected Resource Profiles

## Overview

This document details the anticipated resource usage patterns for each selected application, providing baseline expectations for performance testing and monitoring.

---

## Resource Measurement Methodology

### Metrics Collection

```bash
# CPU Usage
top -bn2 -d 0.5 | grep "Cpu(s)" | tail -1 | awk '{print $2}' | cut -d'%' -f1

# Memory Usage
free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2}'

# Disk I/O
iostat -x 1 2 | grep -A1 "Device" | tail -1

# Network I/O
sar -n DEV 1 1 | grep "Average"
```

### Profile Categories

- **Idle**: Application installed but not actively processing
- **Light Load**: Minimal workload (10-20% capacity)
- **Medium Load**: Moderate workload (40-60% capacity)
- **Heavy Load**: Maximum sustainable workload (80-100% capacity)
- **Peak/Stress**: Burst or stress test conditions

---

## CPU-Intensive Application Profiles

### 1. stress-ng

**Application Type**: System stress testing tool

#### Resource Profile

| Scenario | CPU (%) | Memory (MB) | Disk I/O (MB/s) | Network (Mbps) | Notes |
|----------|---------|-------------|-----------------|----------------|-------|
| **Idle** | 0 | 0 | 0 | 0 | Not running |
| **1 Core Stress** | 100 (1 core) = ~25% total | 50-100 | <1 | 0 | Single CPU worker |
| **All Cores Stress** | 400 (4 cores) = 100% | 100-200 | <1 | 0 | All CPU workers |
| **CPU + Memory** | 80-100% | 2000-4000 | <1 | 0 | Combined stress |
| **Full System Stress** | 100% | 4000-6000 | 100-500 | 0 | CPU+Mem+I/O |

**Expected Behavior**:
- **CPU**: Scales linearly with number of workers
- **Memory**: Minimal unless memory stress enabled
- **I/O**: Negligible unless I/O stress enabled
- **Temperature**: Expect significant heat generation

**Test Commands**:
```bash
# Light: 1 core for 60s
stress-ng --cpu 1 --timeout 60s
# Expected: 25% total CPU, 50MB RAM

# Medium: 2 cores for 60s
stress-ng --cpu 2 --timeout 60s
# Expected: 50% total CPU, 80MB RAM

# Heavy: All cores for 60s
stress-ng --cpu 4 --timeout 60s
# Expected: 100% CPU, 150MB RAM
```

**Monitoring Points**:
- CPU utilization per core
- System load average (should equal number of workers)
- CPU temperature (if available)
- Process priority and scheduling

---

### 2. sysbench (CPU Test)

**Application Type**: Benchmarking tool

#### Resource Profile

| Scenario | CPU (%) | Memory (MB) | Disk I/O (MB/s) | Network (Mbps) | Duration |
|----------|---------|-------------|-----------------|----------------|----------|
| **Prime 2000, 1 thread** | 25% | 100 | <1 | 0 | 30-60s |
| **Prime 10000, 1 thread** | 25% | 120 | <1 | 0 | 60-120s |
| **Prime 2000, 2 threads** | 50% | 150 | <1 | 0 | 30-60s |
| **Prime 2000, 4 threads** | 100% | 200 | <1 | 0 | 30-60s |
| **Prime 20000, 4 threads** | 100% | 250 | <1 | 0 | 120-300s |

**Expected Behavior**:
- CPU-bound workload with predictable patterns
- Linear scaling with thread count
- Consistent performance across runs
- Memory usage grows slightly with thread count

**Test Commands**:
```bash
# Light
sysbench cpu --cpu-max-prime=2000 --threads=1 --time=30 run

# Medium
sysbench cpu --cpu-max-prime=10000 --threads=2 --time=60 run

# Heavy
sysbench cpu --cpu-max-prime=20000 --threads=4 --time=60 run
```

**Performance Metrics**:
- Events per second
- Total time
- Total number of events
- Latency (min/avg/max)

---

### 3. 7zip Compression

**Application Type**: File compression

#### Resource Profile

| Scenario | CPU (%) | Memory (MB) | Disk I/O (MB/s) | Network (Mbps) | Compression Ratio |
|----------|---------|-------------|-----------------|----------------|-------------------|
| **Fast (-mx=1)** | 40-60% | 200-400 | 50-100 (read) | 0 | ~2:1 |
| **Normal (-mx=5)** | 70-90% | 400-800 | 30-60 | 0 | ~4:1 |
| **Maximum (-mx=9)** | 95-100% | 800-1500 | 20-40 | 0 | ~6:1 |
| **Ultra (-mx=9, dict=64M)** | 100% | 2000-3000 | 10-30 | 0 | ~8:1 |

**Expected Behavior**:
- CPU-intensive during compression phase
- Memory usage depends on compression level and dictionary size
- I/O: Initial read spike, then CPU-bound, final write
- Multi-threaded: scales to available cores

**Test Commands**:
```bash
# Prepare test data (100MB)
sudo cp -r /usr/share/doc /tmp/compress-test

# Fast compression
time 7z a -mx=1 -mmt=2 /tmp/fast.7z /tmp/compress-test/
# Expected: 40-60% CPU, 300MB RAM, 2-5 seconds

# Maximum compression
time 7z a -mx=9 -mmt=4 /tmp/max.7z /tmp/compress-test/
# Expected: 100% CPU, 1GB RAM, 30-60 seconds
```

**Phases**:
1. **Reading**: High disk read, low CPU
2. **Compressing**: High CPU, high memory
3. **Writing**: High disk write, low CPU

---

## Memory-Intensive Application Profiles

### 4. Redis

**Application Type**: In-memory data store

#### Resource Profile

| Scenario | CPU (%) | Memory (MB) | Disk I/O (MB/s) | Network (Mbps) | Ops/sec |
|----------|---------|-------------|-----------------|----------------|----------|
| **Idle** | 0.5-1% | 50-100 | 0 | 0 | 0 |
| **Light Load (1K ops/s)** | 5-10% | 200-500 | <1 | 5-10 | 1,000 |
| **Medium Load (10K ops/s)** | 15-25% | 500-1000 | 1-5 | 20-50 | 10,000 |
| **Heavy Load (50K ops/s)** | 40-60% | 1000-2000 | 5-10 | 100-200 | 50,000 |
| **Saturated (100K+ ops/s)** | 80-100% | 2000-4000 | 10-20 | 200-500 | 100,000+ |

**Expected Behavior**:
- Memory grows with dataset size
- CPU increases with operations per second
- Periodic disk writes for persistence (RDB snapshots)
- Network correlates with operation rate

**Test Commands**:
```bash
# Light load
redis-benchmark -h localhost -p 6379 -n 10000 -c 10
# Expected: 10% CPU, 300MB RAM

# Medium load
redis-benchmark -h localhost -p 6379 -n 100000 -c 50
# Expected: 25% CPU, 800MB RAM

# Heavy load (large values)
redis-benchmark -h localhost -p 6379 -n 100000 -c 100 -d 1024
# Expected: 50% CPU, 1.5GB RAM
```

**Memory Breakdown**:
- Base: 50MB (Redis binary and overhead)
- Dataset: Varies with number and size of keys
- Peak: During RDB save (fork overhead)

---

### 5. Memcached

**Application Type**: Distributed memory caching

#### Resource Profile

| Scenario | CPU (%) | Memory (MB) | Disk I/O (MB/s) | Network (Mbps) | Hit Rate (%) |
|----------|---------|-------------|-----------------|----------------|-------------|
| **Idle** | 0.1-0.5% | Allocated memory | 0 | 0 | N/A |
| **Light (1K ops/s)** | 3-5% | 512 (allocated) | 0 | 5-10 | 80-90 |
| **Medium (10K ops/s)** | 10-15% | 1024 | 0 | 20-50 | 85-95 |
| **Heavy (50K ops/s)** | 25-35% | 2048 | 0 | 100-200 | 90-95 |
| **Peak (100K+ ops/s)** | 50-70% | 2048 | 0 | 200-400 | 90-95 |

**Expected Behavior**:
- Memory pre-allocated at startup (fixed size)
- Pure in-memory (zero disk I/O)
- CPU scales with operations per second
- Very efficient for simple key-value operations

**Configuration**:
```bash
# Start with 2GB memory
memcached -m 2048 -p 11211 -u memcache -c 1024 -d
```

**Test Commands**:
```bash
# Install benchmark tool
sudo apt install -y libmemcached-tools

# Light load
memtier_benchmark -s localhost -p 11211 --protocol=memcache_text -n 10000 -c 10

# Heavy load
memtier_benchmark -s localhost -p 11211 --protocol=memcache_text -n 100000 -c 50 --key-pattern=R:R
```

---

### 6. PostgreSQL

**Application Type**: Relational database

#### Resource Profile

| Scenario | CPU (%) | Memory (MB) | Disk I/O (MB/s) | Network (Mbps) | Queries/sec |
|----------|---------|-------------|-----------------|----------------|-------------|
| **Idle** | 0.5-1% | 500-1000 | 0 | 0 | 0 |
| **Light SELECTs** | 10-20% | 1000-1500 | 5-10 | 5-10 | 100-500 |
| **Medium Mixed** | 30-50% | 1500-2500 | 20-50 | 10-20 | 500-1000 |
| **Heavy Writes** | 50-70% | 2500-3500 | 100-200 | 20-50 | 1000-2000 |
| **OLAP Queries** | 80-100% | 3000-5000 | 50-100 | 50-100 | 10-50 |

**Expected Behavior**:
- Memory used for shared buffers and caching
- CPU spikes during complex queries
- I/O: Reads from cache or disk, writes to WAL and data files
- Performance depends heavily on query complexity and indexes

**Test Setup**:
```sql
-- Create test table
CREATE TABLE test_data (
    id SERIAL PRIMARY KEY,
    data VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Generate test data
INSERT INTO test_data (data)
SELECT 'test_' || generate_series(1, 100000);
```

**Test Commands**:
```bash
# Light: Simple selects
sysbench --db-driver=pgsql --pgsql-host=localhost --pgsql-db=testdb \
  --pgsql-user=testuser --pgsql-password=testpass \
  --threads=4 --time=60 oltp_read_only prepare

sysbench --db-driver=pgsql --pgsql-host=localhost --pgsql-db=testdb \
  --pgsql-user=testuser --pgsql-password=testpass \
  --threads=4 --time=60 oltp_read_only run

# Heavy: Mixed read/write
sysbench --db-driver=pgsql --pgsql-host=localhost --pgsql-db=testdb \
  --pgsql-user=testuser --pgsql-password=testpass \
  --threads=8 --time=60 oltp_read_write run
```

---

## I/O-Intensive Application Profiles

### 7. fio (Flexible I/O Tester)

**Application Type**: I/O benchmarking

#### Resource Profile

| Test Type | CPU (%) | Memory (MB) | Read IOPS | Write IOPS | Throughput (MB/s) |
|-----------|---------|-------------|-----------|------------|-------------------|
| **Seq Read (1M blocks)** | 5-10% | 100-200 | N/A | N/A | 300-500 |
| **Seq Write (1M blocks)** | 5-10% | 100-200 | N/A | N/A | 200-400 |
| **Random Read (4K)** | 10-20% | 200-400 | 5000-15000 | N/A | 20-60 |
| **Random Write (4K)** | 15-25% | 200-400 | N/A | 3000-10000 | 12-40 |
| **Mixed 70/30 R/W** | 20-30% | 300-500 | 7000-12000 | 3000-5000 | 30-50 |

**Expected Behavior**:
- Sequential I/O: High throughput, low CPU
- Random I/O: Lower throughput, higher IOPS, more CPU
- Write operations slower than reads (typical)
- Performance depends on disk type (SSD vs HDD)

**Test Commands**:
```bash
# Sequential read test
fio --name=seqread --ioengine=libaio --rw=read --bs=1M \
    --size=1G --numjobs=1 --runtime=60 --time_based \
    --directory=/tmp/fio-test

# Random read test
fio --name=randread --ioengine=libaio --rw=randread --bs=4k \
    --iodepth=16 --size=1G --numjobs=4 --runtime=60 \
    --time_based --directory=/tmp/fio-test

# Mixed workload
fio --name=mixed --ioengine=libaio --rw=randrw --rwmixread=70 \
    --bs=4k --iodepth=16 --size=1G --numjobs=4 --runtime=60 \
    --time_based --directory=/tmp/fio-test
```

---

### 8. dd (Data Duplicator)

**Application Type**: Sequential I/O testing

#### Resource Profile

| Operation | CPU (%) | Memory (MB) | Throughput (MB/s) | Notes |
|-----------|---------|-------------|-------------------|-------|
| **Write (bs=1M)** | 5-10% | 64 | 200-400 | Sequential write |
| **Read (bs=1M)** | 5-10% | 64 | 300-500 | Sequential read |
| **Write (bs=4K)** | 15-20% | 32 | 50-100 | Many small writes |
| **Read (bs=4K)** | 15-20% | 32 | 80-150 | Many small reads |

**Test Commands**:
```bash
# Write test (4GB file)
dd if=/dev/zero of=/tmp/testfile bs=1M count=4096 oflag=direct
# Expected: 5% CPU, 64MB RAM, 250 MB/s

# Read test
dd if=/tmp/testfile of=/dev/null bs=1M iflag=direct
# Expected: 5% CPU, 64MB RAM, 400 MB/s
```

---

### 9. rsync

**Application Type**: File synchronization

#### Resource Profile

| Scenario | CPU (%) | Memory (MB) | Disk Read (MB/s) | Disk Write (MB/s) | Network (Mbps) |
|----------|---------|-------------|------------------|-------------------|----------------|
| **Local, no compression** | 20-30% | 100-300 | 100-200 | 100-200 | 0 |
| **Local, with compression** | 40-60% | 200-500 | 80-150 | 80-150 | 0 |
| **Remote, no compression** | 15-25% | 150-400 | 50-100 | N/A | 100-500 |
| **Remote, with compression** | 50-70% | 300-600 | 50-100 | N/A | 50-200 |

**Test Commands**:
```bash
# Local sync (2GB data)
time rsync -avh /usr/share/doc/ /tmp/rsync-dest/
# Expected: 25% CPU, 200MB RAM, 150 MB/s

# With compression
time rsync -avhz /usr/share/doc/ /tmp/rsync-dest/
# Expected: 55% CPU, 400MB RAM, 100 MB/s
```

---

## Network-Intensive Application Profiles

### 10. iperf3

**Application Type**: Network bandwidth testing

#### Resource Profile

| Test Type | CPU (%) | Memory (MB) | Bandwidth (Mbps) | Packet Loss (%) |
|-----------|---------|-------------|------------------|----------------|
| **TCP, 1 stream** | 10-20% | 50-100 | 500-940 | 0 |
| **TCP, 4 streams** | 30-50% | 100-200 | 700-950 | 0 |
| **UDP, 100Mbps** | 5-10% | 50-80 | 100 | 0-0.1 |
| **UDP, 1Gbps** | 40-60% | 80-150 | 800-950 | 0-1 |

**Test Commands**:
```bash
# Server (on 192.168.1.10)
iperf3 -s

# Client (from workstation 192.168.1.20)
iperf3 -c 192.168.1.10 -t 60
# Expected: 900 Mbps on gigabit network

# Multiple streams
iperf3 -c 192.168.1.10 -t 60 -P 4
# Expected: 930 Mbps total

# UDP test
iperf3 -c 192.168.1.10 -t 60 -u -b 1G
# Expected: 800-950 Mbps with minimal loss
```

---

### 11. Nginx

**Application Type**: Web server

#### Resource Profile

| Scenario | CPU (%) | Memory (MB) | Network (Mbps) | Requests/sec | Concurrent Conn |
|----------|---------|-------------|----------------|--------------|----------------|
| **Idle** | 0.1-0.5% | 50-100 | 0 | 0 | 0 |
| **Static files, 100 conn** | 10-20% | 100-200 | 50-100 | 1000-5000 | 100 |
| **Static files, 500 conn** | 30-50% | 200-400 | 100-300 | 5000-15000 | 500 |
| **Static files, 1000 conn** | 50-70% | 300-500 | 200-500 | 10000-20000 | 1000 |
| **PHP/Dynamic, 100 conn** | 40-60% | 400-800 | 20-50 | 100-500 | 100 |

**Test Commands**:
```bash
# Light load (from workstation)
ab -n 10000 -c 100 http://192.168.1.10/test.html
# Expected server: 15% CPU, 150MB RAM, 80 Mbps

# Medium load
ab -n 50000 -c 500 http://192.168.1.10/test.html
# Expected server: 45% CPU, 300MB RAM, 250 Mbps

# Heavy load
ab -n 100000 -c 1000 http://192.168.1.10/test.html
# Expected server: 65% CPU, 450MB RAM, 400 Mbps
```

---

## Server Application Profiles

### 12. Minecraft Server

**Application Type**: Game server

#### Resource Profile

| Scenario | CPU (%) | Memory (MB) | Disk I/O (MB/s) | Network (Mbps) | Players |
|----------|---------|-------------|-----------------|----------------|---------|
| **Idle (no players)** | 5-10% | 800-1200 | 1-5 | 0-1 | 0 |
| **2-5 players** | 25-40% | 1200-2000 | 5-15 | 5-20 | 2-5 |
| **5-10 players** | 40-60% | 2000-3000 | 10-25 | 10-40 | 5-10 |
| **10-20 players** | 60-85% | 3000-4500 | 20-50 | 20-80 | 10-20 |
| **World generation** | 80-100% | 1500-2500 | 50-150 | 0-5 | 0-1 |

**Expected Behavior**:
- Single-threaded (one core maxed out)
- Memory grows with player count and loaded chunks
- Periodic I/O spikes (world saves every 5 min)
- Network increases with player activity

---

### 13. Docker Containers

**Application Type**: Container platform

#### Resource Profile

| Scenario | CPU (%) | Memory (MB) | Disk I/O (MB/s) | Network (Mbps) |
|----------|---------|-------------|-----------------|----------------|
| **Daemon only** | 0.5-2% | 100-300 | 0-1 | 0 |
| **1 nginx container** | 5-10% | 200-400 | 1-5 | Varies |
| **3 containers (nginx+redis+postgres)** | 15-30% | 800-1500 | 10-30 | Varies |
| **10 containers (mixed)** | 40-70% | 2000-4000 | 30-80 | Varies |

**Overhead**: ~2-5% CPU, 100-200MB RAM for Docker daemon

---

### 14. Node.js API

**Application Type**: Application server

#### Resource Profile

| Scenario | CPU (%) | Memory (MB) | Network (Mbps) | Requests/sec |
|----------|---------|-------------|----------------|-------------|
| **Idle** | 0.5-1% | 150-300 | 0 | 0 |
| **Light (simple API)** | 10-20% | 200-400 | 5-10 | 100-500 |
| **Medium (CPU ops)** | 40-60% | 300-600 | 10-30 | 500-1000 |
| **Heavy (complex ops)** | 70-90% | 500-1000 | 20-50 | 200-500 |

---

## Summary Matrix

### Resource Consumption Overview

| Application | Primary Resource | CPU Range | Memory Range | I/O Impact | Network Impact |
|-------------|------------------|-----------|--------------|------------|----------------|
| stress-ng | CPU | 25-100% | Low | Very Low | None |
| sysbench | CPU | 25-100% | Low | Very Low | None |
| 7zip | CPU | 40-100% | Medium | Medium | None |
| Redis | Memory | Low-Medium | Medium-High | Low | Medium |
| Memcached | Memory | Low | High (fixed) | None | Medium |
| PostgreSQL | Memory | Medium | High | High | Low-Medium |
| fio | Disk I/O | Low-Medium | Low | Very High | None |
| dd | Disk I/O | Low | Very Low | High | None |
| rsync | Disk I/O | Medium | Low-Medium | High | Medium |
| iperf3 | Network | Low-Medium | Low | None | Very High |
| nginx | Network | Medium | Low-Medium | Low | High |
| ab | Network (client) | Medium | Low | Very Low | High |
| Minecraft | Multi (CPU) | Medium-High | High | Medium | Medium |
| Docker | Variable | Low + containers | Medium + containers | Varies | Varies |
| Node.js | Multi (CPU) | Low-High | Medium | Low | Medium |

---

## Testing Recommendations

### Baseline Collection

1. **System idle**: Measure with no applications running
2. **Application idle**: Each app installed but not active
3. **Light load**: 20% of capacity
4. **Medium load**: 50% of capacity
5. **Heavy load**: 80% of capacity
6. **Stress**: 100% of capacity

### Duration Guidelines

- **Short tests**: 30-60 seconds (quick benchmarks)
- **Standard tests**: 5-10 minutes (typical workload)
- **Endurance tests**: 1-24 hours (stability testing)

### Success Criteria

- Actual usage within ±20% of expected values
- No system crashes under load
- Performance degradation <10% over time
- Resource limits respected

---

## Conclusion

These resource profiles provide baseline expectations for each application. Actual values may vary based on:
- Hardware specifications
- System configuration
- Concurrent workloads
- Storage type (SSD vs HDD)
- Network conditions

Use these profiles as reference points for:
1. Capacity planning
2. Performance anomaly detection
3. Resource allocation decisions
4. System optimization priorities

---

## References

- Brendan Gregg's Performance Tools: http://www.brendangregg.com/linuxperf.html
- Linux Performance Analysis: https://netflixtechblog.com/linux-performance-analysis-in-60-000-milliseconds-accc10403c55

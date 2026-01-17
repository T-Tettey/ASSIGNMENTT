# Application Selection Matrix

## Overview

This document presents a comprehensive selection of applications representing different workload types for performance evaluation on the Linux server.

## Application Selection Criteria

### Workload Categories

1. **CPU-Intensive**: Applications that primarily stress the processor
2. **Memory-Intensive**: Applications requiring significant RAM
3. **I/O-Intensive**: Applications with heavy disk read/write operations
4. **Network-Intensive**: Applications generating significant network traffic
5. **Server Applications**: Services like game servers, web servers, databases

### Selection Factors

- **Measurability**: Easy to monitor resource consumption
- **Reproducibility**: Consistent performance characteristics
- **Real-World Relevance**: Represents actual production workloads
- **Open Source**: Free and easily accessible
- **Documentation**: Well-documented for installation and testing

---

## Application Selection Matrix

| # | Application | Category | Primary Resource | Secondary Resource | Justification | Installation Difficulty |
|---|-------------|----------|------------------|-------------------|---------------|------------------------|
| 1 | **stress-ng** | CPU-Intensive | CPU | Memory | Industry-standard stress testing tool | Easy |
| 2 | **sysbench** | CPU-Intensive | CPU | Memory | Benchmarking tool with CPU tests | Easy |
| 3 | **7zip compression** | CPU-Intensive | CPU | Memory | Real-world compression workload | Easy |
| 4 | **Redis** | Memory-Intensive | Memory | Network | In-memory data store | Easy |
| 5 | **Memcached** | Memory-Intensive | Memory | Network | Distributed memory caching | Easy |
| 6 | **PostgreSQL** | Memory-Intensive | Memory | Disk I/O | Relational database | Medium |
| 7 | **fio (Flexible I/O)** | I/O-Intensive | Disk I/O | CPU | I/O benchmarking tool | Easy |
| 8 | **dd** | I/O-Intensive | Disk I/O | - | File system operations | Pre-installed |
| 9 | **rsync** | I/O-Intensive | Disk I/O | Network | File synchronization | Pre-installed |
| 10 | **iperf3** | Network-Intensive | Network | CPU | Network bandwidth testing | Easy |
| 11 | **nginx** | Network-Intensive | Network | Memory | Web server | Easy |
| 12 | **Apache Bench (ab)** | Network-Intensive | Network | CPU | HTTP load testing | Easy |
| 13 | **Minecraft Server** | Server Application | Memory | CPU, Network | Popular game server | Medium |
| 14 | **Docker** | Server Application | All | - | Container platform | Medium |
| 15 | **Node.js API** | Server Application | CPU | Memory, Network | Application server | Easy |

---

## Detailed Application Profiles

### 1. CPU-Intensive Applications

#### 1.1 stress-ng

**Purpose**: Comprehensive stress testing and workload generation

**Why Selected**:
- Industry-standard tool for system stress testing
- Multiple CPU stress methods (arithmetic, matrix, FFT)
- Precise control over CPU core usage
- Minimal dependencies
- Included in Ubuntu repositories

**Use Cases**:
- CPU thermal testing
- System stability validation
- Performance baseline establishment
- Multi-core scalability testing

**Resource Profile**:
- **CPU**: 100% utilization possible per core
- **Memory**: 50-200 MB depending on test type
- **Disk**: Minimal (<10 MB)
- **Network**: None

**Measurable Metrics**:
- CPU utilization per core
- System load average
- Temperature (if sensors available)
- Performance degradation over time

---

#### 1.2 Sysbench

**Purpose**: Multi-threaded benchmark tool for CPU, memory, and databases

**Why Selected**:
- Versatile benchmarking capabilities
- Prime number calculation for CPU testing
- Reproducible results
- Commonly used in industry

**Use Cases**:
- CPU performance benchmarking
- Multi-threaded performance testing
- Database performance testing
- Comparative analysis across systems

**Resource Profile**:
- **CPU**: Configurable threads (1-N cores)
- **Memory**: 100-500 MB
- **Disk**: Minimal
- **Network**: None (unless testing remote DB)

**Test Scenarios**:
```bash
# CPU test
sysbench cpu --threads=4 --time=60 run

# Memory test
sysbench memory --threads=4 --memory-total-size=10G run
```

---

#### 1.3 7zip Compression

**Purpose**: File compression and decompression workload

**Why Selected**:
- Real-world CPU-intensive task
- Common in backup and archival operations
- Predictable resource usage
- Easy to benchmark

**Use Cases**:
- Testing sustained CPU load
- Multi-threaded compression performance
- Real-world productivity workload simulation

**Resource Profile**:
- **CPU**: 80-100% utilization (multi-threaded)
- **Memory**: 200-500 MB per thread
- **Disk**: Read/Write during compression
- **Network**: None

**Test Methodology**:
```bash
# Compress large directory
7z a -t7z -mx=9 -mmt=4 archive.7z /usr/share/doc/

# Benchmark mode
7z b -mmt=4
```

---

### 2. Memory-Intensive Applications

#### 2.1 Redis

**Purpose**: In-memory data structure store

**Why Selected**:
- Production-grade in-memory database
- Controllable memory usage
- Real-world caching workload
- Built-in benchmark tool (redis-benchmark)

**Use Cases**:
- Memory capacity testing
- Cache performance evaluation
- Memory bandwidth testing
- Eviction policy testing

**Resource Profile**:
- **Memory**: Configurable (can use 1GB to all available RAM)
- **CPU**: 10-30% (depending on operations/sec)
- **Disk**: Periodic snapshots (RDB) or AOF logs
- **Network**: 10-100 Mbps for benchmarking

**Configuration**:
```bash
# Set max memory
maxmemory 2gb
maxmemory-policy allkeys-lru

# Benchmark
redis-benchmark -h localhost -p 6379 -n 1000000 -d 1024
```

---

#### 2.2 Memcached

**Purpose**: Distributed memory object caching system

**Why Selected**:
- Simple memory caching service
- Fixed memory allocation
- Low CPU overhead
- Easy to saturate memory

**Use Cases**:
- Memory allocation testing
- Caching performance
- Memory fragmentation analysis

**Resource Profile**:
- **Memory**: Configurable allocation (e.g., -m 1024 for 1GB)
- **CPU**: 5-15%
- **Disk**: None (pure in-memory)
- **Network**: Light to moderate

**Test Command**:
```bash
# Start with 2GB memory
memcached -m 2048 -p 11211 -u memcache -d

# Load test
memtier_benchmark -s localhost -p 11211 --protocol=memcache_text
```

---

#### 2.3 PostgreSQL

**Purpose**: Relational database management system

**Why Selected**:
- Enterprise-grade database
- Complex memory management (shared buffers, work_mem)
- Real-world application workload
- Configurable memory usage

**Use Cases**:
- Database performance testing
- Memory caching effectiveness
- Query performance under memory pressure
- Buffer pool efficiency

**Resource Profile**:
- **Memory**: 500MB to several GB (configurable)
- **CPU**: 20-60% during query execution
- **Disk**: Heavy read/write for data and WAL
- **Network**: Moderate (client connections)

**Configuration**:
```sql
-- /etc/postgresql/14/main/postgresql.conf
shared_buffers = 2GB
effective_cache_size = 6GB
work_mem = 50MB
maintenance_work_mem = 512MB
```

---

### 3. I/O-Intensive Applications

#### 3.1 fio (Flexible I/O Tester)

**Purpose**: I/O workload generator and benchmark tool

**Why Selected**:
- Industry-standard I/O benchmarking
- Highly configurable (read/write patterns, block sizes)
- Supports various I/O engines
- Detailed performance metrics

**Use Cases**:
- Disk performance characterization
- IOPS measurement
- Throughput testing
- Latency analysis

**Resource Profile**:
- **Disk**: 100% I/O saturation possible
- **CPU**: 10-30% (depends on I/O engine)
- **Memory**: 100-500 MB (buffering)
- **Network**: None (unless network block devices)

**Test Scenarios**:
```bash
# Random read IOPS test
fio --name=randread --ioengine=libaio --iodepth=16 --rw=randread --bs=4k --size=4G --numjobs=4

# Sequential write throughput
fio --name=seqwrite --ioengine=libaio --iodepth=1 --rw=write --bs=1M --size=4G
```

---

#### 3.2 dd (Data Duplicator)

**Purpose**: Low-level file copying and conversion

**Why Selected**:
- Pre-installed on all Linux systems
- Simple sequential I/O testing
- Baseline disk performance measurement

**Use Cases**:
- Sequential write speed testing
- Sequential read speed testing
- Disk throughput measurement

**Resource Profile**:
- **Disk**: Sequential I/O (typically 100-500 MB/s)
- **CPU**: 5-10%
- **Memory**: Buffer size (typically 1-64 MB)
- **Network**: None

**Test Commands**:
```bash
# Write test (sequential)
dd if=/dev/zero of=/tmp/testfile bs=1M count=1024 oflag=direct

# Read test
dd if=/tmp/testfile of=/dev/null bs=1M iflag=direct
```

---

#### 3.3 rsync

**Purpose**: File synchronization and transfer utility

**Why Selected**:
- Real-world backup and sync workload
- Combined I/O and network stress
- Common system administration task

**Use Cases**:
- Large file transfer testing
- Directory synchronization
- Backup operation simulation

**Resource Profile**:
- **Disk**: Heavy read (source) and write (destination)
- **CPU**: 20-40% (compression, checksums)
- **Memory**: 100-300 MB
- **Network**: Up to line speed (if remote sync)

**Test Scenarios**:
```bash
# Local large directory sync
rsync -avh --progress /usr/share/ /tmp/rsync-test/

# With compression (more CPU)
rsync -avhz --progress /usr/share/ /tmp/rsync-test/
```

---

### 4. Network-Intensive Applications

#### 4.1 iperf3

**Purpose**: Network bandwidth measurement tool

**Why Selected**:
- Standard network performance tool
- TCP and UDP testing
- Precise bandwidth measurement
- Client-server architecture

**Use Cases**:
- Network throughput testing
- Bandwidth ceiling identification
- Network stability testing
- Multi-stream performance

**Resource Profile**:
- **Network**: Up to line speed (1 Gbps possible)
- **CPU**: 20-50% at high throughput
- **Memory**: 50-100 MB
- **Disk**: None

**Test Commands**:
```bash
# Server mode
iperf3 -s

# Client mode (from workstation)
iperf3 -c 192.168.1.10 -t 60 -P 4

# UDP test
iperf3 -c 192.168.1.10 -u -b 1G
```

---

#### 4.2 Nginx Web Server

**Purpose**: High-performance HTTP server

**Why Selected**:
- Production web server
- Efficient network I/O handling
- Real-world HTTP workload
- Easy to benchmark with ab/wrk

**Use Cases**:
- HTTP request handling capacity
- Concurrent connection testing
- Network throughput under HTTP
- Static file serving performance

**Resource Profile**:
- **Network**: 100-1000 Mbps (depending on file size)
- **CPU**: 10-40%
- **Memory**: 100-500 MB (caching)
- **Disk**: Read for static files

**Performance Testing**:
```bash
# Start nginx
sudo systemctl start nginx

# Benchmark with Apache Bench
ab -n 100000 -c 100 http://192.168.1.10/

# Or with wrk
wrk -t4 -c100 -d60s http://192.168.1.10/
```

---

#### 4.3 Apache Bench (ab)

**Purpose**: HTTP server benchmarking tool

**Why Selected**:
- Simple HTTP load generation
- Generates network and application load
- Included with Apache2 utilities

**Use Cases**:
- Web server stress testing
- Concurrent request handling
- Application layer network stress

**Resource Profile** (as client):
- **Network**: Moderate to high outbound
- **CPU**: 20-60%
- **Memory**: 100-300 MB
- **Disk**: Minimal

**Usage**:
```bash
# 10,000 requests, 100 concurrent
ab -n 10000 -c 100 http://192.168.1.10/index.html

# With keepalive
ab -n 10000 -c 100 -k http://192.168.1.10/
```

---

### 5. Server Applications

#### 5.1 Minecraft Server

**Purpose**: Game server for Minecraft Java Edition

**Why Selected**:
- Real-world game server workload
- Combines CPU, memory, network, and disk I/O
- Popular and representative of game servers
- Configurable player count and world size

**Use Cases**:
- Multi-resource stress testing
- Real-world application performance
- Memory management under load
- Network packet handling

**Resource Profile**:
- **Memory**: 1-4 GB (depends on player count)
- **CPU**: 30-70% (single-threaded bottleneck)
- **Disk**: World loading/saving (chunked)
- **Network**: 10-100 Mbps (player connections)

**Characteristics**:
- Java-based (JVM memory management)
- Single-threaded main loop (CPU bottleneck)
- Memory increases with player count and loaded chunks
- Periodic world saves create disk I/O spikes

---

#### 5.2 Docker Container Platform

**Purpose**: Container runtime and orchestration

**Why Selected**:
- Modern application deployment platform
- Tests OS-level virtualization overhead
- Multiple containers = multiple workloads
- Real-world cloud-native workload

**Use Cases**:
- Container performance testing
- Multi-application resource sharing
- Overhead analysis (container vs native)
- Resource isolation testing

**Resource Profile**:
- **All Resources**: Depends on containers running
- **Overhead**: 2-5% CPU, 100-300 MB memory for Docker daemon
- **Disk**: Container images and volumes
- **Network**: Virtual networking overhead

**Test Scenarios**:
```bash
# Run multiple containers
docker run -d --name nginx1 nginx
docker run -d --name nginx2 nginx
docker run -d --name redis1 redis

# Resource limits
docker run -d --cpus="1.5" --memory="512m" nginx
```

---

#### 5.3 Node.js API Server

**Purpose**: JavaScript runtime for server-side applications

**Why Selected**:
- Modern application server
- Event-driven, non-blocking I/O
- Common in web application backends
- Easy to create test APIs

**Use Cases**:
- Application server performance
- Asynchronous I/O handling
- API endpoint load testing
- Real-world web service workload

**Resource Profile**:
- **CPU**: 20-60% (event loop)
- **Memory**: 200-800 MB (depends on application)
- **Network**: Moderate (HTTP requests/responses)
- **Disk**: Minimal (unless serving files)

**Sample Application**:
```javascript
// Simple API server
const express = require('express');
const app = express();

app.get('/api/test', (req, res) => {
  // CPU-intensive operation
  let result = 0;
  for(let i = 0; i < 1000000; i++) {
    result += Math.sqrt(i);
  }
  res.json({ result: result });
});

app.listen(3000);
```

---

## Application Selection Summary

### By Resource Type

**CPU-Intensive (3 applications):**
1. stress-ng - Stress testing
2. sysbench - Benchmarking
3. 7zip - Real-world compression

**Memory-Intensive (3 applications):**
1. Redis - In-memory cache
2. Memcached - Distributed cache
3. PostgreSQL - Database

**I/O-Intensive (3 applications):**
1. fio - I/O benchmarking
2. dd - Sequential I/O
3. rsync - File synchronization

**Network-Intensive (3 applications):**
1. iperf3 - Network bandwidth
2. nginx - Web server
3. Apache Bench - HTTP load testing

**Server Applications (3 applications):**
1. Minecraft Server - Game server
2. Docker - Container platform
3. Node.js API - Application server

### Testing Matrix

| Workload Type | Light Load App | Medium Load App | Heavy Load App |
|---------------|----------------|-----------------|----------------|
| **CPU** | sysbench (1 thread) | 7zip compression | stress-ng (all cores) |
| **Memory** | Memcached (512MB) | Redis (2GB) | PostgreSQL (4GB) |
| **I/O** | dd sequential | rsync large directory | fio random I/O |
| **Network** | nginx (static) | Apache Bench | iperf3 (multi-stream) |
| **Mixed** | Node.js API | Docker containers | Minecraft Server |

### Installation Priority

**Phase 1 - Essential Tools:**
- stress-ng
- sysbench
- fio
- iperf3

**Phase 2 - Services:**
- nginx
- Redis
- PostgreSQL

**Phase 3 - Advanced:**
- Docker
- Minecraft Server
- Node.js API

---

## Performance Testing Strategy

### Test Progression

1. **Baseline**: Run each application individually
2. **Single Resource Stress**: Max out one resource type
3. **Combined Load**: Multiple applications simultaneously
4. **Real-World Simulation**: Mixed workload scenarios

### Measurement Approach

```bash
# Before starting application
RESOURCES_BEFORE=$(date +%s)
record_metrics baseline

# Start application
start_application

# During operation (periodic sampling)
while application_running; do
    record_metrics during_load
    sleep 30
done

# After stopping application
stop_application
record_metrics after_load

# Analysis
compare_metrics
generate_report
```

### Success Criteria

- All applications install successfully
- Each application's resource usage is measurable
- Performance metrics are reproducible
- No system crashes under load
- Monitoring tools capture all relevant data

---

## Conclusion

This application selection matrix provides:

1. ✅ **Comprehensive Coverage**: All major workload types represented
2. ✅ **Real-World Relevance**: Production-grade applications
3. ✅ **Measurability**: Clear resource consumption patterns
4. ✅ **Scalability**: Light to heavy load scenarios
5. ✅ **Practicality**: Easy installation and configuration

The 15 selected applications enable thorough performance evaluation across all system resources, providing valuable insights into server capabilities and limitations.

---

## References

- stress-ng: https://github.com/ColinIanKing/stress-ng
- sysbench: https://github.com/akopytov/sysbench
- fio: https://fio.readthedocs.io/
- iperf3: https://iperf.fr/
- Performance Testing Best Practices: https://www.brendangregg.com/

# Installation Documentation

## Overview

This document provides complete SSH-based installation instructions for all selected performance testing applications. All commands are designed to be executed remotely via SSH from the admin workstation.

---

## Prerequisites

### SSH Connection Setup

```bash
# From workstation: Test SSH connection
ssh admin@192.168.1.10

# For convenience, add to ~/.ssh/config on workstation:
Host prod-server
    HostName 192.168.1.10
    User admin
    IdentityFile ~/.ssh/id_rsa_server
    Port 22

# Now connect with:
ssh prod-server
```

### System Update

```bash
# Update package lists
sudo apt update

# Upgrade existing packages
sudo apt upgrade -y

# Install common dependencies
sudo apt install -y build-essential curl wget git software-properties-common
```

---

## Category 1: CPU-Intensive Applications

### 1.1 stress-ng

**Purpose**: System stress testing tool

```bash
# SSH to server
ssh admin@192.168.1.10

# Install stress-ng
sudo apt install -y stress-ng

# Verify installation
stress-ng --version
# Expected output: stress-ng, version 0.13.12

# Test installation
stress-ng --cpu 1 --timeout 10s --metrics-brief

# Expected result: CPU stress for 10 seconds, then metrics displayed
```

**Installation Verification**:
```bash
which stress-ng
# Output: /usr/bin/stress-ng

stress-ng --help | head -20
# Should display help text
```

---

### 1.2 Sysbench

**Purpose**: Benchmarking tool

```bash
# Install sysbench
sudo apt install -y sysbench

# Verify installation
sysbench --version
# Expected: sysbench 1.0.20

# Test CPU benchmark
sysbench cpu --cpu-max-prime=2000 --time=10 run

# Test memory benchmark
sysbench memory --memory-total-size=1G run
```

**Installation Verification**:
```bash
which sysbench
# Output: /usr/bin/sysbench

# List available tests
sysbench --help
```

---

### 1.3 p7zip (7zip)

**Purpose**: File compression tool

```bash
# Install p7zip-full
sudo apt install -y p7zip-full

# Verify installation
7z
# Should display 7-Zip version and help

# Test compression (benchmark mode)
7z b
# Runs built-in benchmark

# Create test data
sudo mkdir -p /tmp/compression-test
sudo cp -r /usr/share/doc/* /tmp/compression-test/

# Test compression
cd /tmp
time 7z a -t7z -mx=9 -mmt=4 test-archive.7z compression-test/

# Check compressed file
ls -lh test-archive.7z
```

**Installation Verification**:
```bash
which 7z
# Output: /usr/bin/7z

7z i
# Display system information and supported formats
```

---

## Category 2: Memory-Intensive Applications

### 2.1 Redis

**Purpose**: In-memory data structure store

```bash
# Install Redis server
sudo apt install -y redis-server redis-tools

# Configure Redis
sudo vim /etc/redis/redis.conf
# Set maxmemory (example: 2GB)
# Add line: maxmemory 2gb
# Add line: maxmemory-policy allkeys-lru

# Alternatively, use sed
sudo sed -i 's/# maxmemory <bytes>/maxmemory 2gb/' /etc/redis/redis.conf
echo "maxmemory-policy allkeys-lru" | sudo tee -a /etc/redis/redis.conf

# Restart Redis
sudo systemctl restart redis-server

# Enable Redis on boot
sudo systemctl enable redis-server

# Check status
sudo systemctl status redis-server

# Test Redis
redis-cli ping
# Expected: PONG

# Check memory usage
redis-cli INFO memory | grep used_memory_human

# Run benchmark
redis-benchmark -q -n 100000
```

**Installation Verification**:
```bash
# Check Redis is listening
sudo ss -tuln | grep 6379
# Expected: LISTEN on 127.0.0.1:6379

# Test connection
redis-cli
> SET test "Hello"
> GET test
> EXIT
```

---

### 2.2 Memcached

**Purpose**: Distributed memory caching system

```bash
# Install Memcached
sudo apt install -y memcached libmemcached-tools

# Configure Memcached
sudo vim /etc/memcached.conf
# Adjust: -m 2048 (2GB memory)
# Ensure: -l 127.0.0.1 (listen on localhost)

# Or use sed
sudo sed -i 's/-m 64/-m 2048/' /etc/memcached.conf

# Restart Memcached
sudo systemctl restart memcached

# Enable on boot
sudo systemctl enable memcached

# Check status
sudo systemctl status memcached

# Verify listening
sudo ss -tuln | grep 11211

# Test with telnet
telnet localhost 11211
# Type: stats
# Type: quit

# Or use memcstat
memcstat --servers=localhost:11211
```

**Installation Verification**:
```bash
# Check service
sudo systemctl is-active memcached
# Expected: active

# View stats
echo "stats" | nc localhost 11211
```

---

### 2.3 PostgreSQL

**Purpose**: Relational database management system

```bash
# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Check version
psql --version
# Expected: psql (PostgreSQL) 14.x

# Check status
sudo systemctl status postgresql

# Configure PostgreSQL for performance testing
sudo vim /etc/postgresql/14/main/postgresql.conf

# Recommended settings for 8GB RAM system:
# shared_buffers = 2GB
# effective_cache_size = 6GB
# maintenance_work_mem = 512MB
# work_mem = 50MB
# wal_buffers = 16MB

# Apply settings with sed
sudo sed -i "s/#shared_buffers = 128MB/shared_buffers = 2GB/" /etc/postgresql/14/main/postgresql.conf
sudo sed -i "s/#effective_cache_size = 4GB/effective_cache_size = 6GB/" /etc/postgresql/14/main/postgresql.conf
sudo sed -i "s/#maintenance_work_mem = 64MB/maintenance_work_mem = 512MB/" /etc/postgresql/14/main/postgresql.conf
sudo sed -i "s/#work_mem = 4MB/work_mem = 50MB/" /etc/postgresql/14/main/postgresql.conf

# Restart PostgreSQL
sudo systemctl restart postgresql

# Create test database and user
sudo -u postgres psql
# In psql prompt:
CREATE DATABASE testdb;
CREATE USER testuser WITH ENCRYPTED PASSWORD 'testpass';
GRANT ALL PRIVILEGES ON DATABASE testdb TO testuser;
\q

# Test connection
psql -U testuser -d testdb -h localhost
# Enter password: testpass
# \q to exit
```

**Installation Verification**:
```bash
# Check PostgreSQL is running
sudo systemctl is-active postgresql
# Expected: active

# Check listening port
sudo ss -tuln | grep 5432

# Verify database exists
sudo -u postgres psql -l | grep testdb
```

---

## Category 3: I/O-Intensive Applications

### 3.1 fio (Flexible I/O Tester)

**Purpose**: I/O benchmarking tool

```bash
# Install fio
sudo apt install -y fio

# Verify installation
fio --version
# Expected: fio-3.28

# Create test directory
sudo mkdir -p /tmp/fio-test

# Run simple test
fio --name=test --ioengine=libaio --rw=randrw --bs=4k --numjobs=1 --size=1G --runtime=30 --directory=/tmp/fio-test

# Sample fio job file
cat <<EOF | sudo tee /tmp/fio-test.fio
[global]
ioengine=libaio
iodepth=16
size=1G
directory=/tmp/fio-test
runtime=60
time_based=1

[randread-4k]
rw=randread
bs=4k

[randwrite-4k]
rw=randwrite
bs=4k
EOF

# Run job file
fio /tmp/fio-test.fio
```

**Installation Verification**:
```bash
which fio
# Output: /usr/bin/fio

fio --help | head -20
```

---

### 3.2 dd (pre-installed)

**Purpose**: Data copying and conversion

```bash
# dd is pre-installed, verify it works
which dd
# Output: /usr/bin/dd

# Check version
dd --version
# Expected: dd (coreutils) 8.32

# Test write speed
dd if=/dev/zero of=/tmp/testfile bs=1M count=1024 oflag=direct
# Note the speed (MB/s)

# Test read speed
dd if=/tmp/testfile of=/dev/null bs=1M iflag=direct
# Note the speed (MB/s)

# Clean up
rm /tmp/testfile
```

**Installation Verification**:
```bash
# dd is always available
dd --help | head -10
```

---

### 3.3 rsync (pre-installed)

**Purpose**: File synchronization tool

```bash
# rsync is usually pre-installed
which rsync
# Output: /usr/bin/rsync

# If not installed:
sudo apt install -y rsync

# Check version
rsync --version
# Expected: rsync version 3.2.x

# Create test directories
mkdir -p /tmp/rsync-source
mkdir -p /tmp/rsync-dest

# Copy some data for testing
sudo cp -r /usr/share/doc/* /tmp/rsync-source/

# Test rsync
time rsync -avh --progress /tmp/rsync-source/ /tmp/rsync-dest/

# Test with compression
time rsync -avhz --progress /tmp/rsync-source/ /tmp/rsync-dest/
```

**Installation Verification**:
```bash
rsync --version | head -5

# Test basic sync
rsync --help | grep -i "usage"
```

---

## Category 4: Network-Intensive Applications

### 4.1 iperf3

**Purpose**: Network bandwidth measurement

```bash
# Install iperf3
sudo apt install -y iperf3

# Verify installation
iperf3 --version
# Expected: iperf 3.9

# Start server mode (on server)
iperf3 -s -D
# -D runs as daemon

# Verify it's listening
sudo ss -tuln | grep 5201
# Expected: LISTEN on port 5201

# From workstation, test connection:
ssh admin@192.168.1.20
iperf3 -c 192.168.1.10 -t 10
# Should show bandwidth results

# Stop server
pkill iperf3
```

**Installation Verification**:
```bash
which iperf3
# Output: /usr/bin/iperf3

# Test server mode
iperf3 -s -1
# Runs server for one test, then exits
```

---

### 4.2 Nginx

**Purpose**: High-performance web server

```bash
# Install Nginx
sudo apt install -y nginx

# Check version
nginx -v
# Expected: nginx version: nginx/1.18.0

# Start Nginx
sudo systemctl start nginx

# Enable on boot
sudo systemctl enable nginx

# Check status
sudo systemctl status nginx

# Verify it's listening
sudo ss -tuln | grep :80
# Expected: LISTEN on 0.0.0.0:80

# Test from workstation
curl http://192.168.1.10/
# Should return default Nginx welcome page

# Create test file for benchmarking
echo "Test page for benchmarking" | sudo tee /var/www/html/test.html

# Test
curl http://192.168.1.10/test.html
```

**Installation Verification**:
```bash
# Check service
sudo systemctl is-active nginx
# Expected: active

# Check configuration
sudo nginx -t
# Expected: syntax is ok, test is successful

# View access logs
sudo tail /var/log/nginx/access.log
```

---

### 4.3 Apache Bench (ab)

**Purpose**: HTTP server benchmarking

```bash
# Install Apache2 utils (includes ab)
sudo apt install -y apache2-utils

# Verify installation
ab -V
# Expected: ApacheBench Version 2.3

# Test against Nginx (from workstation is better, but can test locally)
ab -n 1000 -c 10 http://127.0.0.1/test.html
# 1000 requests, 10 concurrent

# Better: From workstation
ssh admin@192.168.1.20
sudo apt install -y apache2-utils
ab -n 10000 -c 100 http://192.168.1.10/test.html
```

**Installation Verification**:
```bash
which ab
# Output: /usr/bin/ab

ab -h | head -20
```

---

## Category 5: Server Applications

### 5.1 Minecraft Server

**Purpose**: Java-based game server

```bash
# Install Java (required for Minecraft)
sudo apt install -y openjdk-17-jre-headless

# Verify Java installation
java -version
# Expected: openjdk version "17.0.x"

# Create Minecraft directory
mkdir -p ~/minecraft-server
cd ~/minecraft-server

# Download Minecraft server (version 1.20.1 example)
wget https://piston-data.mojang.com/v1/objects/84194a2f286ef7c14ed7ce0090dba59902951553/server.jar -O minecraft_server.jar

# Accept EULA
echo "eula=true" > eula.txt

# Create start script
cat <<'EOF' > start.sh
#!/bin/bash
java -Xmx2G -Xms1G -jar minecraft_server.jar nogui
EOF

chmod +x start.sh

# Configure server properties (optional)
cat <<'EOF' > server.properties
max-players=10
difficulty=easy
gamemode=survival
EOF

# Start server (background)
nohup ./start.sh > server.log 2>&1 &

# Check if running
ps aux | grep minecraft_server.jar

# View log
tail -f server.log

# Stop server
pkill -f minecraft_server.jar
```

**Installation Verification**:
```bash
# Check Java
which java

# Check server files
ls -lh ~/minecraft-server/

# Check if server created world
ls ~/minecraft-server/world/
```

---

### 5.2 Docker

**Purpose**: Container platform

```bash
# Install prerequisites
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index
sudo apt update

# Install Docker
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Verify installation
sudo docker --version
# Expected: Docker version 24.0.x

# Add user to docker group
sudo usermod -aG docker $USER

# Activate group (or logout/login)
newgrp docker

# Test Docker
docker run hello-world
# Should download and run hello-world container

# Enable Docker on boot
sudo systemctl enable docker

# Check Docker status
sudo systemctl status docker
```

**Installation Verification**:
```bash
# Check Docker service
sudo systemctl is-active docker
# Expected: active

# List images
docker images

# List running containers
docker ps

# Test with Nginx
docker run -d -p 8080:80 --name test-nginx nginx
curl http://localhost:8080
docker stop test-nginx
docker rm test-nginx
```

---

### 5.3 Node.js

**Purpose**: JavaScript runtime for server applications

```bash
# Install Node.js using NodeSource repository (LTS version)
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installation
node --version
# Expected: v18.x.x or v20.x.x

npm --version
# Expected: 9.x.x or higher

# Create test API application
mkdir -p ~/nodejs-api
cd ~/nodejs-api

# Initialize npm project
npm init -y

# Install Express
npm install express

# Create simple API
cat <<'EOF' > app.js
const express = require('express');
const app = express();
const PORT = 3000;

app.get('/', (req, res) => {
  res.json({ message: 'Hello from Node.js API' });
});

app.get('/api/cpu', (req, res) => {
  // CPU-intensive operation
  let result = 0;
  for(let i = 0; i < 10000000; i++) {
    result += Math.sqrt(i);
  }
  res.json({ result: result });
});

app.get('/api/memory', (req, res) => {
  // Memory allocation
  const arr = new Array(1000000).fill('test data');
  res.json({ allocated: arr.length });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
EOF

# Start the application
node app.js &

# Test the API
curl http://localhost:3000/
curl http://localhost:3000/api/cpu
curl http://localhost:3000/api/memory

# Stop the application
pkill -f "node app.js"
```

**Installation Verification**:
```bash
# Check Node.js
which node
node --version

# Check npm
which npm
npm --version

# Test simple script
node -e "console.log('Node.js is working')"
```

---

## Post-Installation Verification

### Complete Installation Check Script

```bash
#!/bin/bash
# installation-check.sh

echo "===================================="
echo "  Application Installation Check"
echo "===================================="
echo ""

check_command() {
    if command -v $1 &> /dev/null; then
        echo "✓ $1 is installed"
        return 0
    else
        echo "✗ $1 is NOT installed"
        return 1
    fi
}

check_service() {
    if systemctl is-active --quiet $1; then
        echo "✓ $1 service is running"
        return 0
    else
        echo "✗ $1 service is NOT running"
        return 1
    fi
}

echo "--- CPU-Intensive Applications ---"
check_command stress-ng
check_command sysbench
check_command 7z
echo ""

echo "--- Memory-Intensive Applications ---"
check_command redis-cli
check_service redis-server
check_command memcached
check_service memcached
check_command psql
check_service postgresql
echo ""

echo "--- I/O-Intensive Applications ---"
check_command fio
check_command dd
check_command rsync
echo ""

echo "--- Network-Intensive Applications ---"
check_command iperf3
check_command nginx
check_service nginx
check_command ab
echo ""

echo "--- Server Applications ---"
check_command java
check_command docker
check_service docker
check_command node
check_command npm
echo ""

echo "===================================="
echo "  Installation Check Complete"
echo "===================================="
```

### Save and run the check script:

```bash
# Create the script
cat > ~/installation-check.sh << 'SCRIPT_END'
# [paste the script above]
SCRIPT_END

# Make executable
chmod +x ~/installation-check.sh

# Run the check
./installation-check.sh
```

---

## Troubleshooting Common Installation Issues

### Issue: Package not found

```bash
# Solution: Update package lists
sudo apt update
sudo apt upgrade
```

### Issue: Permission denied

```bash
# Solution: Use sudo
sudo <command>

# Or add user to appropriate group
sudo usermod -aG docker $USER
newgrp docker
```

### Issue: Service won't start

```bash
# Check service status
sudo systemctl status <service>

# Check logs
sudo journalctl -u <service> -n 50

# Check configuration
sudo <service> -t  # for nginx
redis-cli ping  # for redis
```

### Issue: Port already in use

```bash
# Find what's using the port
sudo ss -tuln | grep <port>

# Find process
sudo lsof -i :<port>

# Kill process if needed
sudo kill <PID>
```

---

## Installation Summary

### Installed Applications Count: 15

**CPU-Intensive**: 3
- stress-ng ✓
- sysbench ✓
- 7zip ✓

**Memory-Intensive**: 3
- Redis ✓
- Memcached ✓
- PostgreSQL ✓

**I/O-Intensive**: 3
- fio ✓
- dd ✓ (pre-installed)
- rsync ✓ (pre-installed)

**Network-Intensive**: 3
- iperf3 ✓
- Nginx ✓
- Apache Bench ✓

**Server Applications**: 3
- Minecraft Server ✓
- Docker ✓
- Node.js ✓

### Total Disk Space Used

Approximate disk space:
- Applications: ~2 GB
- Docker images: ~500 MB
- Minecraft server: ~200 MB
- Test data: ~1 GB
- **Total**: ~3.7 GB

---

## Next Steps

1. Run the installation check script
2. Test each application individually
3. Document baseline resource usage
4. Begin performance testing (see monitoring-strategy.md)
5. Create performance profiles (see expected-resource-profiles.md)

---

## References

- Ubuntu Packages: https://packages.ubuntu.com/
- Docker Installation: https://docs.docker.com/engine/install/ubuntu/
- Node.js Installation: https://github.com/nodesource/distributions
- PostgreSQL Documentation: https://www.postgresql.org/docs/

# CLI Documentation of System Specifications

## Overview

This document provides comprehensive command-line interface (CLI) documentation of system specifications using standard Linux commands.

## System Information Commands

### 1. `uname` - System Information

#### Basic Usage

```bash
# Display all system information
uname -a
```

**Expected Output:**
```
Linux prod-server 5.15.0-91-generic #101-Ubuntu SMP Tue Nov 14 13:30:08 UTC 2023 x86_64 x86_64 x86_64 GNU/Linux
```

#### Detailed Breakdown

```bash
# Kernel name
uname -s
# Output: Linux

# Network hostname
uname -n
# Output: prod-server

# Kernel release
uname -r
# Output: 5.15.0-91-generic

# Kernel version
uname -v
# Output: #101-Ubuntu SMP Tue Nov 14 13:30:08 UTC 2023

# Machine hardware name
uname -m
# Output: x86_64

# Processor type
uname -p
# Output: x86_64

# Hardware platform
uname -i
# Output: x86_64

# Operating system
uname -o
# Output: GNU/Linux
```

#### Analysis of Output

| Component | Value | Meaning |
|-----------|-------|----------|
| **Kernel Name** | Linux | Operating system kernel |
| **Hostname** | prod-server | Network node name |
| **Kernel Release** | 5.15.0-91-generic | Kernel version (5.15 LTS) |
| **Architecture** | x86_64 | 64-bit x86 processor |
| **OS** | GNU/Linux | Complete operating system |

---

### 2. `free` - Memory Usage

#### Display Memory in Human-Readable Format

```bash
free -h
```

**Expected Output:**
```
               total        used        free      shared  buff/cache   available
Mem:           7.7Gi       1.2Gi       5.8Gi       8.0Mi       710Mi       6.3Gi
Swap:          2.0Gi          0B       2.0Gi
```

#### Detailed Memory Statistics

```bash
# Show memory in megabytes
free -m

# Show memory with total line
free -h --total

# Continuous monitoring (update every 2 seconds)
free -h -s 2

# Display wide output
free -hw
```

**Output Explanation:**

```
               total        used        free      shared  buff/cache   available
Mem:           7.7Gi       1.2Gi       5.8Gi       8.0Mi       710Mi       6.3Gi
Swap:          2.0Gi          0B       2.0Gi
```

| Column | Description |
|--------|-------------|
| **total** | Total installed RAM (7.7 GB) |
| **used** | Memory used by processes (1.2 GB) |
| **free** | Completely unused memory (5.8 GB) |
| **shared** | Memory used by tmpfs (8 MB) |
| **buff/cache** | Memory used by kernel buffers and page cache (710 MB) |
| **available** | Memory available for new applications (6.3 GB) |

#### Memory Calculation

```bash
# Available memory calculation:
available = free + buff/cache (reclaimable)

# Our example:
available = 5.8 GB + ~0.5 GB = 6.3 GB
```

#### Swap Space

```
Swap:          2.0Gi          0B       2.0Gi
```

- **Total Swap:** 2 GB configured
- **Used Swap:** 0 B (none currently in use)
- **Free Swap:** 2 GB available

**Interpretation:** System has plenty of RAM, swap is not needed.

---

### 3. `df -h` - Disk Space Usage

#### Display Filesystem Usage

```bash
df -h
```

**Expected Output:**
```
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           788M  1.2M  787M   1% /run
/dev/sda2        98G   12G   82G  13% /
tmpfs           3.9G     0  3.9G   0% /dev/shm
tmpfs           5.0M  4.0K  5.0M   1% /run/lock
/dev/sda1       511M  6.1M  505M   2% /boot/efi
tmpfs           788M   12K  788M   1% /run/user/1000
```

#### Advanced Usage

```bash
# Show filesystem type
df -hT

# Show inode usage
df -hi

# Show only local filesystems
df -hl

# Exclude certain filesystem types
df -h -x tmpfs -x devtmpfs

# Show specific filesystem
df -h /
```

#### Output Analysis

##### Root Filesystem
```
/dev/sda2        98G   12G   82G  13% /
```

| Field | Value | Description |
|-------|-------|-------------|
| **Filesystem** | /dev/sda2 | Physical device/partition |
| **Size** | 98G | Total partition size |
| **Used** | 12G | Space currently used |
| **Avail** | 82G | Space available |
| **Use%** | 13% | Percentage used |
| **Mounted on** | / | Mount point (root) |

##### Boot Partition
```
/dev/sda1       511M  6.1M  505M   2% /boot/efi
```

- **Purpose:** EFI boot partition
- **Size:** 512 MB
- **Used:** 6.1 MB (boot files)
- **Type:** FAT32 (EFI System Partition)

##### Temporary Filesystems (tmpfs)

```
tmpfs           788M  1.2M  787M   1% /run
tmpfs           3.9G     0  3.9G   0% /dev/shm
tmpfs           5.0M  4.0K  5.0M   1% /run/lock
tmpfs           788M   12K  788M   1% /run/user/1000
```

- **Type:** RAM-based temporary filesystems
- **Purpose:** Fast temporary storage
- **/dev/shm:** Shared memory
- **/run:** Runtime data
- **/run/user/1000:** User-specific runtime files

#### Disk Usage by Directory

```bash
# Show top-level directory sizes
sudo du -h --max-depth=1 / 2>/dev/null | sort -hr | head -20

# Common large directories
sudo du -sh /var /usr /home /tmp 2>/dev/null

# Find large files (over 100MB)
sudo find / -type f -size +100M -exec ls -lh {} \; 2>/dev/null
```

---

### 4. `ip addr` - Network Configuration

#### Display All Network Interfaces

```bash
ip addr
# OR
ip a
```

**Expected Output:**
```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever

2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:8a:42:1f brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic enp0s3
       valid_lft 86386sec preferred_lft 86386sec
    inet6 fe80::a00:27ff:fe8a:421f/64 scope link
       valid_lft forever preferred_lft forever

3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:3c:d4:89 brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.10/24 brd 192.168.1.255 scope global enp0s8
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe3c:d489/64 scope link
       valid_lft forever preferred_lft forever
```

#### Interface Breakdown

##### 1. Loopback Interface (lo)
```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536
    inet 127.0.0.1/8 scope host lo
```

| Attribute | Value | Description |
|-----------|-------|-------------|
| **Interface** | lo | Loopback interface |
| **Status** | UP | Interface is active |
| **MTU** | 65536 | Maximum transmission unit |
| **IPv4** | 127.0.0.1/8 | Localhost address |
| **Purpose** | Local communication | Process-to-process communication |

##### 2. NAT Interface (enp0s3)
```
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500
    link/ether 08:00:27:8a:42:1f
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic enp0s3
```

| Attribute | Value | Description |
|-----------|-------|-------------|
| **Interface** | enp0s3 | First Ethernet adapter |
| **MAC Address** | 08:00:27:8a:42:1f | Hardware address (VirtualBox vendor) |
| **IPv4** | 10.0.2.15/24 | IP from VirtualBox NAT DHCP |
| **Broadcast** | 10.0.2.255 | Broadcast address |
| **Assignment** | dynamic | DHCP assigned |
| **Purpose** | Internet access | NAT network for updates |

##### 3. Host-Only Interface (enp0s8)
```
3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500
    link/ether 08:00:27:3c:d4:89
    inet 192.168.1.10/24 brd 192.168.1.255 scope global enp0s8
```

| Attribute | Value | Description |
|-----------|-------|-------------|
| **Interface** | enp0s8 | Second Ethernet adapter |
| **MAC Address** | 08:00:27:3c:d4:89 | Hardware address |
| **IPv4** | 192.168.1.10/24 | Static IP configuration |
| **Broadcast** | 192.168.1.255 | Broadcast address |
| **Assignment** | static | Manually configured |
| **Purpose** | Server access | Host-only network for SSH |

#### Additional Network Commands

```bash
# Show only IPv4 addresses
ip -4 addr

# Show specific interface
ip addr show enp0s8

# Show interface statistics
ip -s link

# Show routing table
ip route

# Show ARP cache
ip neigh
```

---

### 5. `lsb_release` - Distribution Information

#### Display Distribution Details

```bash
lsb_release -a
```

**Expected Output:**
```
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 22.04.3 LTS
Release:        22.04
Codename:       jammy
```

#### Individual Components

```bash
# Distributor ID
lsb_release -i
# Output: Distributor ID: Ubuntu

# Description
lsb_release -d
# Output: Description: Ubuntu 22.04.3 LTS

# Release number
lsb_release -r
# Output: Release: 22.04

# Codename
lsb_release -c
# Output: Codename: jammy

# Short format (all info, one line)
lsb_release -a -s
# Output: Ubuntu 22.04 jammy
```

#### Output Explanation

| Field | Value | Description |
|-------|-------|-------------|
| **Distributor ID** | Ubuntu | Linux distribution name |
| **Description** | Ubuntu 22.04.3 LTS | Full distribution description |
| **Release** | 22.04 | Major.minor version number |
| **Codename** | jammy | Release codename (Jammy Jellyfish) |
| **LTS** | Long Term Support | 5 years of support (until 2027) |

#### Alternative Distribution Info Commands

```bash
# OS release information
cat /etc/os-release

# Ubuntu version
cat /etc/lsb-release

# Debian version (Ubuntu is Debian-based)
cat /etc/debian_version

# Host information
hostnamectl
```

**Example `/etc/os-release` Output:**
```bash
NAME="Ubuntu"
VERSION="22.04.3 LTS (Jammy Jellyfish)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 22.04.3 LTS"
VERSION_ID="22.04"
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
VERSION_CODENAME=jammy
UBUNTU_CODENAME=jammy
```

---

## Complete System Specification Script

### Automated System Info Collection

```bash
#!/bin/bash
# system-specs.sh - Collect comprehensive system specifications

echo "==============================================="
echo "        SYSTEM SPECIFICATIONS REPORT          "
echo "==============================================="
echo ""

echo "--- System Information (uname) ---"
uname -a
echo ""

echo "--- Distribution Information (lsb_release) ---"
lsb_release -a
echo ""

echo "--- Memory Usage (free) ---"
free -h
echo ""

echo "--- Disk Usage (df) ---"
df -h
echo ""

echo "--- Network Configuration (ip addr) ---"
ip addr
echo ""

echo "--- Hostname Information ---"
hostnamectl
echo ""

echo "--- CPU Information ---"
lscpu | grep -E "^Architecture:|^CPU\(s\):|^Model name:|^CPU MHz:"
echo ""

echo "--- Uptime ---"
uptime
echo ""

echo "--- Kernel Version ---"
uname -r
echo ""

echo "==============================================="
echo "            END OF REPORT                      "
echo "==============================================="
```

### Usage

```bash
# Create the script
vim system-specs.sh

# Make executable
chmod +x system-specs.sh

# Run the script
./system-specs.sh

# Save output to file
./system-specs.sh > system-specs-$(date +%Y%m%d).txt

# Run via SSH and save locally
ssh admin@192.168.1.10 'bash -s' < system-specs.sh > server-specs.txt
```

---

## Additional Useful Commands

### CPU Information

```bash
# Detailed CPU info
lscpu

# CPU model
cat /proc/cpuinfo | grep "model name" | head -1

# Number of CPU cores
nproc

# CPU architecture
arch
```

### Hardware Information

```bash
# Hardware overview
sudo lshw -short

# PCI devices
lspci

# USB devices
lsusb

# Block devices
lsblk

# BIOS/UEFI info
sudo dmidecode -t system
```

### System Performance

```bash
# Current resource usage
top
htop  # if installed

# Process list
ps aux

# System load
uptime
w

# I/O statistics
iostat
vmstat
```

### Kernel and Module Information

```bash
# Loaded kernel modules
lsmod

# Kernel parameters
sysctl -a

# Kernel messages
sudo dmesg | tail

# Boot messages
journalctl -b
```

---

## System Specification Summary

### Server Specifications

```yaml
Hostname: prod-server
Operating System: Ubuntu 22.04.3 LTS (Jammy Jellyfish)
Kernel: Linux 5.15.0-91-generic
Architecture: x86_64 (64-bit)

Hardware:
  CPU: 4 cores @ 2.4 GHz
  RAM: 8 GB (7.7 GiB)
  Swap: 2 GB
  Storage: 100 GB (/dev/sda2)
    - Used: 12 GB (13%)
    - Available: 82 GB

Network:
  Hostname: prod-server
  Interfaces:
    - lo: 127.0.0.1/8 (loopback)
    - enp0s3: 10.0.2.15/24 (NAT, DHCP)
    - enp0s8: 192.168.1.10/24 (Host-Only, Static)

Software:
  Init System: systemd
  Package Manager: APT (dpkg)
  Shell: bash
  Python: 3.10.12
```

### Interpretation and Recommendations

**Memory:**
- ✅ 8 GB RAM is sufficient for server workloads
- ✅ Low memory usage (1.2 GB used, 6.3 GB available)
- ✅ Swap not in use (indicates adequate RAM)

**Storage:**
- ✅ 98 GB total with 82 GB free (13% used)
- ✅ Plenty of space for applications and data
- ✅ EFI boot partition properly configured

**Network:**
- ✅ Dual network setup functioning correctly
- ✅ NAT for internet access (enp0s3)
- ✅ Host-only for administration (enp0s8)
- ✅ Static IP configured on management interface

**System Health:**
- ✅ Ubuntu 22.04 LTS (supported until 2027)
- ✅ Recent kernel version (5.15 LTS)
- ✅ All systems operational
- ✅ Resources not oversubscribed

---

## Documentation Best Practices

### Regular System Audits

```bash
# Weekly system check script
#!/bin/bash
# weekly-check.sh

echo "Weekly System Check - $(date)"
echo "================================"

echo "\n1. Disk Usage:"
df -h | grep -E "/$|/boot"

echo "\n2. Memory Status:"
free -h | grep -E "Mem:|Swap:"

echo "\n3. System Load:"
uptime

echo "\n4. Failed Services:"
systemctl --failed

echo "\n5. Recent Errors:"
sudo journalctl -p err -n 10 --no-pager

echo "\n6. Security Updates Available:"
apt list --upgradable 2>/dev/null | grep -i security | wc -l
```

### Creating System Baselines

```bash
# Create baseline snapshot
date=$(date +%Y%m%d)
mkdir -p ~/baselines

# Capture all specs
./system-specs.sh > ~/baselines/baseline-$date.txt

# Package list
dpkg -l > ~/baselines/packages-$date.txt

# Service status
systemctl list-units --type=service > ~/baselines/services-$date.txt
```

---

## Conclusion

These five commands (`uname`, `free`, `df -h`, `ip addr`, `lsb_release`) provide a comprehensive overview of:

1. ✅ **System Identity:** OS, kernel, architecture
2. ✅ **Resource Usage:** Memory and disk consumption
3. ✅ **Network Configuration:** IP addresses and interfaces
4. ✅ **Distribution Details:** Ubuntu version and support status

Regular execution of these commands helps maintain system awareness and aids in troubleshooting and capacity planning.

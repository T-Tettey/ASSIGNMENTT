# Network Configuration Documentation

## Overview

This document details the complete network configuration for the server-workstation architecture, including VirtualBox network settings, IP addressing scheme, and connectivity validation.

## Network Topology

```
                         Internet
                             │
                   ┌─────────▼──────────┐
                   │   VirtualBox NAT    │
                   │  (10.0.2.0/24)     │
                   └───────┬─────┬──────┘
                          │        │
                  ┌───────▼───┐  ┌─▼────────┐
                  │ Workstation │  │  Server   │
                  │  (NAT IF)   │  │ (NAT IF) │
                  └─────┬──────┘  └──┬─────┘
                        │              │
                        │              │
           ┌────────────▼────────────▼───────────┐
           │    VirtualBox Host-Only Network     │
           │         (192.168.1.0/24)           │
           └──────┬───────────────┬────────┘
                  │                    │
          ┌───────▼───────┐  ┌─────▼───────┐
          │  Workstation  │  │   Server    │
          │ 192.168.1.20 │◄─►│ 192.168.1.10 │
          │  (Host-Only)  │  │ (Host-Only) │
          └──────────────┘  └─────────────┘
                              SSH Traffic
```

## VirtualBox Network Configuration

### Host-Only Network Setup

#### Creating the Host-Only Network

```bash
# On the host machine (Windows/Linux/macOS)
VBoxManage hostonlyif create
VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.1.1 --netmask 255.255.255.0
```

**VirtualBox GUI Method:**
1. Open VirtualBox
2. Go to: File → Host Network Manager
3. Click "Create" to add a new host-only network
4. Configure:
   - **Adapter:**
     - IPv4 Address: `192.168.1.1`
     - IPv4 Network Mask: `255.255.255.0`
   - **DHCP Server:** Disabled (we use static IPs)

### Server Network Adapters

#### Adapter 1: NAT (Internet Access)

**Purpose:** Provides internet connectivity for package updates and downloads

**VirtualBox Settings:**
```yaml
VM: Ubuntu-Server
Adapter 1:
  Attached to: NAT
  Adapter Type: Intel PRO/1000 MT Desktop (82540EM)
  Promiscuous Mode: Deny
  Cable Connected: Yes
  Port Forwarding: None (not needed)
```

**Automatic Configuration:**
- IP: 10.0.2.15 (assigned by VirtualBox NAT DHCP)
- Gateway: 10.0.2.2
- DNS: 10.0.2.3

#### Adapter 2: Host-Only (Server Communication)

**Purpose:** Isolated network for server-workstation communication

**VirtualBox Settings:**
```yaml
VM: Ubuntu-Server
Adapter 2:
  Attached to: Host-only Adapter
  Name: vboxnet0
  Adapter Type: Intel PRO/1000 MT Desktop (82540EM)
  Promiscuous Mode: Deny
  Cable Connected: Yes
```

**Static Configuration:**
- IP: 192.168.1.10/24
- Gateway: 192.168.1.1
- DNS: 8.8.8.8, 8.8.4.4

### Workstation Network Adapters

#### Adapter 1: NAT (Internet Access)

```yaml
VM: Ubuntu-Workstation
Adapter 1:
  Attached to: NAT
  Adapter Type: Intel PRO/1000 MT Desktop (82540EM)
  Cable Connected: Yes
```

#### Adapter 2: Host-Only (Server Communication)

```yaml
VM: Ubuntu-Workstation
Adapter 2:
  Attached to: Host-only Adapter
  Name: vboxnet0
  Adapter Type: Intel PRO/1000 MT Desktop (82540EM)
  Cable Connected: Yes
```

## IP Addressing Scheme

### Network: 192.168.1.0/24

| Device | IP Address | Subnet Mask | Gateway | Purpose |
|--------|-----------|-------------|---------|----------|
| VirtualBox Host | 192.168.1.1 | 255.255.255.0 | - | Gateway for host-only network |
| Server | 192.168.1.10 | 255.255.255.0 | 192.168.1.1 | Production server |
| Workstation | 192.168.1.20 | 255.255.255.0 | 192.168.1.1 | Admin workstation |
| Reserved | 192.168.1.11-19 | - | - | Future servers |
| Reserved | 192.168.1.21-29 | - | - | Future workstations |
| DHCP Pool | 192.168.1.100-200 | - | - | Dynamic allocation (if enabled) |

### Subnet Calculations

```
Network Address: 192.168.1.0
Subnet Mask: 255.255.255.0 (/24)
Wildcard Mask: 0.0.0.255
Broadcast Address: 192.168.1.255
Usable IP Range: 192.168.1.1 - 192.168.1.254
Total Hosts: 254
```

## Server Network Configuration

### Netplan Configuration File

**File:** `/etc/netplan/00-installer-config.yaml`

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:  # NAT adapter (auto-configured)
      dhcp4: true
      dhcp6: false
      optional: true
    enp0s8:  # Host-Only adapter (static)
      addresses:
        - 192.168.1.10/24
      routes:
        - to: default
          via: 192.168.1.1
          metric: 100
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
        search:
          - local
      dhcp4: false
      dhcp6: false
```

### Apply Network Configuration

```bash
# Test configuration (doesn't apply)
sudo netplan try

# Apply configuration
sudo netplan apply

# Check status
sudo netplan status
```

### Alternative: Using NetworkManager (if installed)

```bash
# Configure static IP using nmcli
sudo nmcli connection modify enp0s8 \
  ipv4.addresses 192.168.1.10/24 \
  ipv4.gateway 192.168.1.1 \
  ipv4.dns "8.8.8.8,8.8.4.4" \
  ipv4.method manual

# Restart connection
sudo nmcli connection down enp0s8
sudo nmcli connection up enp0s8
```

## Workstation Network Configuration

### Netplan Configuration File

**File:** `/etc/netplan/01-network-config.yaml`

```yaml
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    enp0s3:  # NAT adapter
      dhcp4: true
      dhcp6: false
    enp0s8:  # Host-Only adapter
      addresses:
        - 192.168.1.20/24
      routes:
        - to: 192.168.1.0/24
          via: 192.168.1.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
      dhcp4: false
      dhcp6: false
```

## Network Verification Commands

### Interface Status

```bash
# Show all network interfaces
ip addr show

# Expected output for server:
# 1: lo: <LOOPBACK,UP,LOWER_UP>
#     inet 127.0.0.1/8
# 2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP>
#     inet 10.0.2.15/24 (VirtualBox NAT)
# 3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP>
#     inet 192.168.1.10/24 (Host-Only)

# Show interface statistics
ip -s link

# Show only specific interface
ip addr show enp0s8
```

### Routing Table

```bash
# Display routing table
ip route show

# Expected output for server:
# default via 192.168.1.1 dev enp0s8 proto static metric 100
# 10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15
# 192.168.1.0/24 dev enp0s8 proto kernel scope link src 192.168.1.10

# Display routing table with more details
route -n
```

### DNS Configuration

```bash
# Check DNS servers
resolvectl status

# Test DNS resolution
nslookup google.com
dig google.com

# Check /etc/resolv.conf
cat /etc/resolv.conf
```

### Connectivity Testing

```bash
# Ping tests from server
ping -c 4 192.168.1.1       # Gateway
ping -c 4 192.168.1.20      # Workstation
ping -c 4 8.8.8.8           # Internet
ping -c 4 google.com        # DNS resolution

# Traceroute
traceroute 8.8.8.8

# MTU discovery
ping -M do -s 1472 192.168.1.20
```

### Port and Service Testing

```bash
# Check listening ports
sudo ss -tuln

# Check specific port (SSH)
sudo ss -tuln | grep :22

# Test SSH connectivity from workstation
telnet 192.168.1.10 22
nc -zv 192.168.1.10 22
```

## Firewall Configuration Integration

### UFW Rules for Network

```bash
# On server - allow SSH from workstation only
sudo ufw allow from 192.168.1.20 to any port 22 proto tcp

# Deny all other SSH attempts
sudo ufw deny 22/tcp

# Allow outgoing connections
sudo ufw default allow outgoing

# Deny incoming by default
sudo ufw default deny incoming

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status verbose
```

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: Cannot ping server from workstation

```bash
# Check if interface is up
ip addr show enp0s8

# Check if IP is configured
ip addr show enp0s8 | grep "inet "

# Restart networking
sudo netplan apply
# OR
sudo systemctl restart NetworkManager

# Check firewall
sudo ufw status
```

#### Issue 2: No internet access

```bash
# Check default route
ip route show default

# Check DNS
cat /etc/resolv.conf

# Test with IP (bypass DNS)
ping -c 4 8.8.8.8

# Test DNS resolution
ping -c 4 google.com

# Restart networking
sudo netplan apply
```

#### Issue 3: SSH not working

```bash
# Check SSH service status
sudo systemctl status sshd

# Check if port 22 is listening
sudo ss -tuln | grep :22

# Check firewall rules
sudo ufw status numbered

# Test from workstation with verbose output
ssh -v admin@192.168.1.10
```

### Network Diagnostic Commands

```bash
# Complete network diagnosis script
#!/bin/bash

echo "=== Network Interfaces ==="
ip addr show

echo -e "\n=== Routing Table ==="
ip route show

echo -e "\n=== DNS Configuration ==="
cat /etc/resolv.conf

echo -e "\n=== Connectivity Tests ==="
ping -c 2 192.168.1.1
ping -c 2 8.8.8.8
ping -c 2 google.com

echo -e "\n=== Listening Ports ==="
sudo ss -tuln

echo -e "\n=== Firewall Status ==="
sudo ufw status verbose
```

## Network Security Considerations

### Network Segmentation

1. **Isolation:** Host-only network is isolated from host machine and internet
2. **Controlled Access:** Only workstation can reach server on host-only network
3. **Outbound Only:** Server initiates outbound connections, doesn't accept from internet

### Security Best Practices

```bash
# Disable IPv6 if not needed (in /etc/sysctl.conf)
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1

# Apply sysctl changes
sudo sysctl -p

# Enable SYN cookies (DDoS protection)
sudo sysctl -w net.ipv4.tcp_syncookies=1

# Disable ICMP redirects
sudo sysctl -w net.ipv4.conf.all.accept_redirects=0
```

## Network Monitoring

### Real-time Traffic Monitoring

```bash
# Monitor network traffic by interface
sudo iftop -i enp0s8

# Monitor bandwidth by process
sudo nethogs enp0s8

# Network statistics
watch -n 1 'ip -s link'

# Connection monitoring
watch -n 1 'ss -s'
```

### Network Logging

```bash
# Enable connection logging in UFW
sudo ufw logging on

# View firewall logs
sudo tail -f /var/log/ufw.log

# Network statistics over time
sar -n DEV 1 10
```

## Documentation and Maintenance

### Network Change Log Template

```markdown
## Network Changes Log

### YYYY-MM-DD - Initial Setup
- Created host-only network 192.168.1.0/24
- Configured server static IP: 192.168.1.10
- Configured workstation static IP: 192.168.1.20
- Applied firewall rules
- Tested connectivity

### YYYY-MM-DD - [Change Description]
- What was changed
- Why it was changed
- Testing performed
- Results
```

## Conclusion

This network configuration provides:

1. ✅ **Dual Network Access:** Internet via NAT + internal via host-only
2. ✅ **Security:** Isolated internal network for server-workstation communication
3. ✅ **Flexibility:** Can add more VMs to the same host-only network
4. ✅ **Simplicity:** Static IPs for easy management
5. ✅ **Reliability:** No dependency on external DHCP servers

The configuration balances security, performance, and ease of management for a learning and testing environment.

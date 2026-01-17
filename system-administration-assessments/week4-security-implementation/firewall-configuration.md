# Firewall Configuration with UFW

## Overview

Complete documentation for configuring UFW (Uncomplicated Firewall) on Ubuntu Server 22.04 with SSH restricted to the workstation.

---

## Phase 1: Install and Check UFW

```bash
# SSH to server
ssh admin@192.168.1.10

# Install UFW (usually pre-installed)
sudo apt update
sudo apt install -y ufw

# Check UFW status
sudo ufw status
# Expected: Status: inactive

# Check UFW version
sudo ufw version
```

---

## Phase 2: Set Default Policies

```bash
# Set default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw default deny routed

# Verify defaults
sudo ufw show raw
```

---

## Phase 3: Configure SSH Access (CRITICAL)

### Allow SSH from Workstation ONLY

```bash
# Allow SSH from workstation IP
sudo ufw allow from 192.168.1.20 to any port 22 proto tcp comment 'SSH from workstation'

# Verify rule added
sudo ufw status numbered
```

### Important: Test BEFORE Enabling

```bash
# DO NOT enable UFW yet
# First verify the rule is correct
sudo ufw show added

# Should show:
# ufw allow from 192.168.1.20 to any port 22 proto tcp comment 'SSH from workstation'
```

---

## Phase 4: Enable UFW

```bash
# Enable UFW
sudo ufw enable

# You'll see warning about disrupting existing SSH connections
# Type 'y' to proceed

# Check status
sudo ufw status verbose

# Expected output:
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), deny (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    192.168.1.20              # SSH from workstation
```

---

## Phase 5: Test Firewall

### Test from Workstation (Should Work)

```bash
# From workstation (192.168.1.20)
ssh admin@192.168.1.10
# Should connect successfully
```

### Test from Other IP (Should Fail)

```bash
# From another machine or temporarily change workstation IP
ssh admin@192.168.1.10
# Should timeout or connection refused
```

---

## Phase 6: Additional Firewall Rules (Optional)

### If Running Web Server

```bash
# Allow HTTP
sudo ufw allow 80/tcp comment 'HTTP'

# Allow HTTPS
sudo ufw allow 443/tcp comment 'HTTPS'

# Or use application profile
sudo ufw allow 'Nginx Full'
```

### If Running Database (Internal Only)

```bash
# PostgreSQL from local network
sudo ufw allow from 192.168.1.0/24 to any port 5432 proto tcp comment 'PostgreSQL local'

# MySQL from local network
sudo ufw allow from 192.168.1.0/24 to any port 3306 proto tcp comment 'MySQL local'
```

### Rate Limiting for SSH

```bash
# Delete the existing SSH rule
sudo ufw delete allow from 192.168.1.20 to any port 22

# Add rate-limited rule
sudo ufw limit from 192.168.1.20 to any port 22 proto tcp comment 'SSH rate limited'

# Rate limiting: max 6 connections per 30 seconds
```

---

## Phase 7: Enable Logging

```bash
# Enable logging
sudo ufw logging on

# Set logging level (low, medium, high, full)
sudo ufw logging medium

# View logs
sudo tail -f /var/log/ufw.log

# View blocked connections
sudo grep "\[UFW BLOCK\]" /var/log/ufw.log | tail -20
```

---

## Phase 8: Application Profiles

### List Available Profiles

```bash
sudo ufw app list

# Common profiles:
# - OpenSSH
# - Nginx Full
# - Nginx HTTP
# - Nginx HTTPS
# - Apache
# - Apache Full
```

### View Profile Details

```bash
sudo ufw app info 'Nginx Full'

# Output shows:
# Profile: Nginx Full
# Title: Web Server (Nginx, HTTP + HTTPS)
# Description: Small, but very powerful and efficient web server
# Ports:
#   80,443/tcp
```

---

## Firewall Rule Management

### View Rules

```bash
# Simple status
sudo ufw status

# Detailed status
sudo ufw status verbose

# Numbered list
sudo ufw status numbered
```

### Delete Rules

```bash
# By rule number
sudo ufw status numbered
sudo ufw delete <number>

# By rule specification
sudo ufw delete allow 80/tcp

# Delete specific rule
sudo ufw delete allow from 192.168.1.0/24 to any port 3306
```

### Insert Rules at Specific Position

```bash
# Insert at position 1
sudo ufw insert 1 allow from 192.168.1.20 to any port 22
```

---

## Advanced Configuration

### Custom Rules with iptables

```bash
# UFW uses iptables underneath
# View actual iptables rules
sudo iptables -L -n -v
sudo ip6tables -L -n -v

# Custom iptables rules (persistent)
sudo vim /etc/ufw/before.rules
# Add custom rules before UFW rules

# Reload UFW
sudo ufw reload
```

### Connection Tracking

```bash
# Allow established connections
# (UFW does this by default)

# View connection tracking
sudo conntrack -L

# Count connections
sudo conntrack -C
```

---

## Monitoring and Troubleshooting

### Real-Time Log Monitoring

```bash
# Watch firewall activity
sudo tail -f /var/log/ufw.log

# Filter blocked connections
sudo tail -f /var/log/ufw.log | grep BLOCK

# Filter allowed connections
sudo tail -f /var/log/ufw.log | grep ALLOW
```

### Analyze Blocked IPs

```bash
#!/bin/bash
# blocked-ips.sh

echo "Top 10 Blocked IPs:"
sudo grep "\[UFW BLOCK\]" /var/log/ufw.log | \
    grep -oP 'SRC=\K[0-9.]+' | \
    sort | uniq -c | sort -rn | head -10

echo ""
echo "Blocked connections by port:"
sudo grep "\[UFW BLOCK\]" /var/log/ufw.log | \
    grep -oP 'DPT=\K[0-9]+' | \
    sort | uniq -c | sort -rn | head -10
```

### Test Firewall Rules

```bash
# Test from workstation
nc -zv 192.168.1.10 22
# Should show: Connection succeeded

nc -zv 192.168.1.10 80
# Should show: Connection refused or timeout (if not allowed)

# Test with telnet
telnet 192.168.1.10 22
# Should connect if allowed

# Test with nmap (from workstation)
sudo apt install -y nmap
nmap -p 1-1000 192.168.1.10
# Should only show allowed ports
```

---

## Complete Firewall Configuration

### Production-Ready Configuration

```bash
#!/bin/bash
# ufw-setup.sh - Complete firewall configuration

echo "Configuring UFW firewall..."

# Reset UFW (optional - use with caution)
# sudo ufw --force reset

# Set defaults
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw default deny routed

# Allow SSH from workstation only
sudo ufw allow from 192.168.1.20 to any port 22 proto tcp comment 'SSH from workstation'

# Allow ping (ICMP)
sudo ufw allow from 192.168.1.0/24 proto icmp comment 'ICMP from local network'

# Enable logging
sudo ufw logging medium

# Enable UFW
sudo ufw --force enable

# Show status
echo ""
echo "Firewall configuration complete:"
sudo ufw status verbose

echo ""
echo "Testing SSH connection..."
ss -tuln | grep :22
```

---

## Firewall Documentation

### Current Firewall Rules

```bash
# Generate firewall documentation
#!/bin/bash
# document-firewall.sh

OUTPUT="firewall-rules-$(date +%Y%m%d-%H%M%S).txt"

echo "=== UFW Firewall Configuration ===" > "$OUTPUT"
echo "Generated: $(date)" >> "$OUTPUT"
echo "Server: $(hostname)" >> "$OUTPUT"
echo "" >> "$OUTPUT"

echo "--- Status ---" >> "$OUTPUT"
sudo ufw status verbose >> "$OUTPUT"
echo "" >> "$OUTPUT"

echo "--- Numbered Rules ---" >> "$OUTPUT"
sudo ufw status numbered >> "$OUTPUT"
echo "" >> "$OUTPUT"

echo "--- Application Profiles ---" >> "$OUTPUT"
sudo ufw app list >> "$OUTPUT"
echo "" >> "$OUTPUT"

echo "--- iptables Rules ---" >> "$OUTPUT"
sudo iptables -L -n -v >> "$OUTPUT"
echo "" >> "$OUTPUT"

echo "Firewall documentation saved to: $OUTPUT"
```

---

## Backup and Restore

### Backup Firewall Rules

```bash
# Backup UFW rules
sudo cp -r /etc/ufw /etc/ufw.backup.$(date +%Y%m%d)
sudo cp /lib/ufw/user.rules /lib/ufw/user.rules.backup
sudo cp /lib/ufw/user6.rules /lib/ufw/user6.rules.backup

# Or export rules
sudo iptables-save > iptables-backup-$(date +%Y%m%d).rules
sudo ip6tables-save > ip6tables-backup-$(date +%Y%m%d).rules
```

### Restore Firewall Rules

```bash
# Restore from backup
sudo cp -r /etc/ufw.backup.* /etc/ufw
sudo ufw reload

# Or restore iptables
sudo iptables-restore < iptables-backup-20240115.rules
```

---

## Security Best Practices

### 1. Principle of Least Privilege
- Only open ports that are absolutely necessary
- Restrict source IPs whenever possible
- Close ports when services are no longer needed

### 2. Regular Audits
```bash
# Weekly firewall audit
sudo ufw status numbered
sudo grep "\[UFW BLOCK\]" /var/log/ufw.log | tail -100
```

### 3. Defense in Depth
- Firewall is one layer
- Combine with fail2ban
- Use AppArmor/SELinux
- Keep services updated

---
## Verification Checklist

- [ ] UFW installed
- [ ] Default policies set (deny incoming, allow outgoing)
- [ ] SSH allowed from workstation IP only
- [ ] UFW enabled
- [ ] SSH connection tested and working from workstation
- [ ] SSH blocked from other IPs (if testable)
- [ ] Logging enabled
- [ ] Rules documented
- [ ] Backup created
- [ ] Monitoring script in place

---

## Configuration Files

### Before UFW Enabled
```bash
# No firewall active
# All ports accessible
```

### After UFW Enabled
```bash
Status: active
Logging: on (medium)
Default: deny (incoming), allow (outgoing), deny (routed)

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    192.168.1.20    # SSH from workstation
```

---

## Troubleshooting

### Issue: Locked out of server

**Prevention:**
- Always test rules before enabling UFW
- Keep current SSH session open while testing
- Have console/physical access if available

**Solution:**
- Access via console or VirtualBox
- Disable UFW: `sudo ufw disable`
- Fix rules
- Re-enable: `sudo ufw enable`

### Issue: Service not accessible

```bash
# Check if port is open
sudo ufw status | grep <port>

# Check if service is listening
sudo ss -tuln | grep <port>

# Check logs
sudo grep "DPT=<port>" /var/log/ufw.log
```

---

## Evidence Collection

### Screenshots/Output to Capture

```bash
# 1. Before configuration
sudo ufw status

# 2. After configuration
sudo ufw status verbose
sudo ufw status numbered

# 3. iptables rules
sudo iptables -L -n -v

# 4. Successful SSH from workstation
ssh admin@192.168.1.10
whoami

# 5. Blocked connection log
sudo grep "\[UFW BLOCK\]" /var/log/ufw.log | tail -10
```

---

## Conclusion

Firewall is now configured with:

1. ✅ Default deny incoming policy
2. ✅ SSH access restricted to workstation IP
3. ✅ Logging enabled
4. ✅ Tested and verified working

The server is protected against:
- Unauthorized network access
- Port scanning attacks
- Brute force from unknown IPs
- Lateral movement from compromised systems

---

## References

- UFW Documentation: https://help.ubuntu.com/community/UFW
- iptables Tutorial: https://www.netfilter.org/documentation/
- Ubuntu Firewall: https://ubuntu.com/server/docs/security-firewall

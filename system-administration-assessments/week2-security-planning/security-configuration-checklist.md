# Security Configuration Checklist

## Overview

This comprehensive checklist covers all essential security configurations for hardening an Ubuntu Server 22.04 LTS system. Each section includes configuration steps, verification methods, and best practices.

---

## 1. SSH Hardening

### Configuration File: `/etc/ssh/sshd_config`

#### Essential Settings

```bash
# Disable root login
PermitRootLogin no

# Disable password authentication (use keys only)
PasswordAuthentication no
PermitEmptyPasswords no

# Enable public key authentication
PubkeyAuthentication yes

# Disable X11 forwarding (unless needed)
X11Forwarding no

# Limit authentication attempts
MaxAuthTries 3
MaxSessions 2

# Set login grace time
LoginGraceTime 60

# Allow only specific users/groups
AllowUsers admin
# OR
AllowGroups ssh-users

# Disable unused authentication methods
ChallengeResponseAuthentication no
KerberosAuthentication no
GSSAPIAuthentication no

# Set strong ciphers and algorithms
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256

# Protocol version
Protocol 2

# Logging
SyslogFacility AUTH
LogLevel VERBOSE

# Client alive interval (prevent timeout)
ClientAliveInterval 300
ClientAliveCountMax 2
```

#### Implementation Steps

```bash
# 1. Backup original configuration
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%Y%m%d)

# 2. Edit SSH configuration
sudo vim /etc/ssh/sshd_config

# 3. Test configuration syntax
sudo sshd -t

# 4. Restart SSH service
sudo systemctl restart sshd

# 5. Verify SSH is running
sudo systemctl status sshd
```

#### Key-Based Authentication Setup

```bash
# On workstation: Generate SSH key pair
ssh-keygen -t rsa -b 4096 -C "admin@workstation" -f ~/.ssh/id_rsa_server

# Copy public key to server
ssh-copy-id -i ~/.ssh/id_rsa_server.pub admin@192.168.1.10

# OR manually:
cat ~/.ssh/id_rsa_server.pub | ssh admin@192.168.1.10 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# On server: Set proper permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

#### Additional SSH Hardening

```bash
# Change SSH port (optional, security through obscurity)
# In /etc/ssh/sshd_config:
Port 2222  # or any port between 1024-65535

# Use SSH banner
echo "Authorized access only. All activity is monitored." | sudo tee /etc/ssh/banner
# In /etc/ssh/sshd_config:
Banner /etc/ssh/banner

# Disable SSH agent forwarding
AllowAgentForwarding no

# Disable TCP forwarding
AllowTcpForwarding no
```

#### Verification

```bash
# Check SSH configuration
sudo sshd -T

# Test SSH connection with key
ssh -i ~/.ssh/id_rsa_server admin@192.168.1.10

# Verify password authentication is disabled
ssh -o PreferredAuthentications=password admin@192.168.1.10
# Should fail: "Permission denied (publickey)"

# Check SSH logs
sudo journalctl -u sshd -n 50
sudo tail -f /var/log/auth.log | grep sshd
```

### ✅ SSH Hardening Checklist

- [ ] Root login disabled
- [ ] Password authentication disabled
- [ ] SSH keys configured and working
- [ ] Strong ciphers configured
- [ ] User access restricted (AllowUsers/AllowGroups)
- [ ] Login attempts limited (MaxAuthTries)
- [ ] Unnecessary authentication methods disabled
- [ ] SSH service restarted and verified
- [ ] Connection tested from workstation
- [ ] Configuration backed up

---

## 2. Firewall Configuration (UFW)

### UFW (Uncomplicated Firewall) Setup

#### Basic Configuration

```bash
# 1. Install UFW (usually pre-installed)
sudo apt install -y ufw

# 2. Set default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 3. Allow SSH from specific IP (workstation)
sudo ufw allow from 192.168.1.20 to any port 22 proto tcp comment "SSH from workstation"

# 4. Deny SSH from all other sources
sudo ufw deny 22/tcp

# 5. Enable UFW
sudo ufw enable

# 6. Check status
sudo ufw status verbose
```

#### Advanced Firewall Rules

```bash
# Allow specific services
sudo ufw allow 80/tcp comment "HTTP"
sudo ufw allow 443/tcp comment "HTTPS"

# Allow from specific subnet
sudo ufw allow from 192.168.1.0/24 to any port 3306 comment "MySQL from local network"

# Rate limiting (prevent brute force)
sudo ufw limit 22/tcp comment "Rate limit SSH"

# Allow application profiles
sudo ufw allow 'OpenSSH'
sudo ufw allow 'Nginx Full'

# Delete rules
sudo ufw status numbered
sudo ufw delete <number>

# Insert rule at specific position
sudo ufw insert 1 allow from 192.168.1.20 to any port 22
```

#### Logging Configuration

```bash
# Enable logging
sudo ufw logging on

# Set logging level
sudo ufw logging medium  # off, low, medium, high, full

# View firewall logs
sudo tail -f /var/log/ufw.log

# View blocked connections
sudo grep "\[UFW BLOCK\]" /var/log/ufw.log | tail -20
```

#### Verification

```bash
# Check UFW status
sudo ufw status verbose
sudo ufw status numbered

# Test SSH from workstation (should work)
ssh admin@192.168.1.10

# Test SSH from unauthorized IP (should fail)
# Use another machine or temporarily test

# Check active connections
sudo ss -tuln

# Verify iptables rules (UFW uses iptables underneath)
sudo iptables -L -n -v
sudo ip6tables -L -n -v
```

### ✅ Firewall Configuration Checklist

- [ ] UFW installed
- [ ] Default policies set (deny incoming, allow outgoing)
- [ ] SSH allowed from workstation only
- [ ] Unnecessary ports closed
- [ ] Rate limiting configured for SSH
- [ ] Logging enabled
- [ ] UFW enabled and active
- [ ] Rules tested and verified
- [ ] Documentation of all rules maintained

---

## 3. Mandatory Access Control (MAC)

### AppArmor (Ubuntu Default)

#### Enable and Configure AppArmor

```bash
# Check AppArmor status
sudo aa-status

# Install AppArmor utilities
sudo apt install -y apparmor-utils apparmor-profiles apparmor-profiles-extra

# View loaded profiles
sudo aa-status | grep "profiles are loaded"

# List profiles and their modes
sudo aa-status | grep -A 100 "profiles are in enforce mode"
```

#### Working with Profiles

```bash
# Put profile in complain mode (logging only)
sudo aa-complain /etc/apparmor.d/usr.sbin.nginx

# Put profile in enforce mode
sudo aa-enforce /etc/apparmor.d/usr.sbin.nginx

# Disable profile
sudo aa-disable /etc/apparmor.d/usr.sbin.nginx

# Reload profile
sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.nginx

# Reload all profiles
sudo systemctl reload apparmor
```

#### Create Custom Profile

```bash
# Generate profile automatically
sudo aa-genprof /path/to/program

# Example: Create profile for custom application
sudo aa-genprof /usr/local/bin/myapp
# Then use the application and answer questions

# Log profile
sudo aa-logprof
# Review logs and update profiles
```

#### Monitoring AppArmor

```bash
# View AppArmor denials
sudo journalctl -fx | grep -i apparmor
sudo dmesg | grep -i apparmor

# Check audit log
sudo grep "apparmor" /var/log/audit/audit.log
sudo grep "apparmor" /var/log/syslog

# View profile denials
sudo aa-notify -s 1 -v
```

### SELinux (Alternative to AppArmor)

```bash
# Note: Ubuntu uses AppArmor by default
# To use SELinux instead:

# Install SELinux
sudo apt install -y selinux-basics selinux-policy-default auditd

# Activate SELinux
sudo selinux-activate

# Check status
sudo selinux-config-enforcing

# Reboot required
sudo reboot

# After reboot, verify
getenforce
```

### ✅ MAC Implementation Checklist

- [ ] AppArmor installed and enabled
- [ ] AppArmor profiles loaded
- [ ] Critical services have profiles in enforce mode
- [ ] Profile violations monitored
- [ ] Custom profiles created for custom applications
- [ ] Documentation of profile modes maintained

---

## 4. Automatic Security Updates

### Unattended Upgrades Configuration

#### Installation and Setup

```bash
# Install unattended-upgrades
sudo apt install -y unattended-upgrades apt-listchanges

# Enable automatic updates
sudo dpkg-reconfigure -plow unattended-upgrades

# Edit configuration
sudo vim /etc/apt/apt.conf.d/50unattended-upgrades
```

#### Configuration File Settings

```bash
# /etc/apt/apt.conf.d/50unattended-upgrades

Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};

# Email notifications
Unattended-Upgrade::Mail "admin@example.com";
Unattended-Upgrade::MailReport "on-change";

# Automatic reboot if required
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";

# Remove unused dependencies
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";

# Keep debs
Unattended-Upgrade::Keep-Debs-After-Install "false";

# Logging
Unattended-Upgrade::SyslogEnable "true";
Unattended-Upgrade::SyslogFacility "daemon";
```

#### Auto-Update Configuration

```bash
# /etc/apt/apt.conf.d/20auto-upgrades

APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
```

#### Testing and Verification

```bash
# Test unattended-upgrades
sudo unattended-upgrades --dry-run --debug

# Run manually
sudo unattended-upgrades -v

# Check last update time
ls -la /var/lib/apt/periodic/

# View logs
sudo cat /var/log/unattended-upgrades/unattended-upgrades.log
sudo cat /var/log/unattended-upgrades/unattended-upgrades-dpkg.log

# Check for pending updates
apt list --upgradable

# Check if reboot required
cat /var/run/reboot-required
cat /var/run/reboot-required.pkgs
```

### ✅ Automatic Updates Checklist

- [ ] unattended-upgrades installed
- [ ] Security updates enabled
- [ ] Update frequency configured
- [ ] Email notifications set up (optional)
- [ ] Automatic reboot configured (optional)
- [ ] Tested with dry-run
- [ ] Logs being generated
- [ ] Monitoring for failed updates

---

## 5. User Privilege Management

### Principle of Least Privilege

#### Create Administrative User

```bash
# Create non-root user with sudo privileges
sudo adduser admin

# Add user to sudo group
sudo usermod -aG sudo admin

# Verify group membership
groups admin
id admin
```

#### Configure sudo

```bash
# Edit sudoers file (always use visudo)
sudo visudo

# Best practices in /etc/sudoers:

# Require password for sudo
Defaults passwd_timeout=15
Defaults timestamp_timeout=15

# Log all sudo commands
Defaults logfile="/var/log/sudo.log"
Defaults log_input, log_output

# Limit sudo to specific commands (if needed)
admin ALL=(ALL) /usr/sbin/systemctl, /usr/sbin/ufw, /usr/bin/apt

# OR full sudo access
admin ALL=(ALL:ALL) ALL

# Secure sudo path
Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
```

#### Disable Root Account

```bash
# Lock root password
sudo passwd -l root

# Verify root is locked
sudo passwd -S root
# Should show: "root L ..."

# Disable root shell (extreme measure)
# sudo usermod -s /usr/sbin/nologin root
```

#### User Account Policies

```bash
# Set password expiration
sudo chage -M 90 admin  # Max 90 days
sudo chage -m 7 admin   # Min 7 days between changes
sudo chage -W 14 admin  # Warn 14 days before expiry

# View account aging information
sudo chage -l admin

# Lock inactive accounts
sudo chage -I 30 admin  # Lock after 30 days of inactivity

# Set account expiration date
sudo chage -E 2025-12-31 tempuser
```

#### Password Policy

```bash
# Install password quality checking library
sudo apt install -y libpam-pwquality

# Configure password requirements
# Edit: /etc/security/pwquality.conf

minlen = 12
minclass = 3
maxrepeat = 3
maxsequence = 3
reject_username
enforcing = 1
```

### ✅ User Privilege Management Checklist

- [ ] Non-root administrative user created
- [ ] User added to sudo group
- [ ] Root login disabled
- [ ] Root password locked
- [ ] sudo logging enabled
- [ ] Password policies configured
- [ ] Account expiration policies set
- [ ] Principle of least privilege followed

---

## 6. Network Security

### Disable Unnecessary Services

```bash
# List all enabled services
systemctl list-unit-files --type=service --state=enabled

# Disable unnecessary services
sudo systemctl disable bluetooth.service
sudo systemctl disable cups.service
sudo systemctl disable avahi-daemon.service

# Stop services
sudo systemctl stop bluetooth.service
sudo systemctl stop cups.service

# Verify
systemctl is-enabled bluetooth.service
```

### Network Hardening

#### Kernel Network Parameters

```bash
# Edit /etc/sysctl.conf or create /etc/sysctl.d/99-security.conf

# IP forwarding (disable unless router)
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# Disable source routing
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Disable ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Enable SYN cookies (DDoS protection)
net.ipv4.tcp_syncookies = 1

# Log martian packets
net.ipv4.conf.all.log_martians = 1

# Ignore ICMP ping requests (optional)
net.ipv4.icmp_echo_ignore_all = 1

# Disable IPv6 (if not needed)
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1

# Apply changes
sudo sysctl -p
sudo sysctl --system
```

### TCP Wrappers

```bash
# Configure /etc/hosts.allow
# Allow SSH from workstation
sshd: 192.168.1.20

# Configure /etc/hosts.deny
# Deny everything else
ALL: ALL

# Test
sudo tcpdchk
```

### ✅ Network Security Checklist

- [ ] Unnecessary services disabled
- [ ] Network kernel parameters hardened
- [ ] IP forwarding disabled
- [ ] ICMP redirects disabled
- [ ] SYN cookies enabled
- [ ] IPv6 disabled (if not needed)
- [ ] TCP wrappers configured
- [ ] Network configuration tested

---

## Final Security Verification

### Complete Security Audit

```bash
#!/bin/bash
# security-audit.sh

echo "=== Security Configuration Audit ==="
echo ""

echo "1. SSH Configuration:"
sudo sshd -T | grep -E "^(permitrootlogin|passwordauthentication|pubkeyauthentication)"
echo ""

echo "2. Firewall Status:"
sudo ufw status verbose
echo ""

echo "3. AppArmor Status:"
sudo aa-status | head -20
echo ""

echo "4. Automatic Updates:"
sudo unattended-upgrades --dry-run --debug | grep -i "running"
echo ""

echo "5. Sudo Configuration:"
sudo grep -v "^#" /etc/sudoers | grep -v "^$"
echo ""

echo "6. Root Account:"
sudo passwd -S root
echo ""

echo "7. Listening Ports:"
sudo ss -tuln
echo ""

echo "8. Failed Login Attempts (last 24h):"
sudo journalctl -u sshd --since "24 hours ago" | grep "Failed password" | wc -l
echo ""

echo "=== Audit Complete ==="
```

### Security Compliance Matrix

| Security Control | Configured | Verified | Notes |
|------------------|------------|----------|-------|
| SSH Key Auth | ✅ | ✅ | Password auth disabled |
| SSH Root Disabled | ✅ | ✅ | Root login blocked |
| Firewall Active | ✅ | ✅ | UFW enabled, rules applied |
| AppArmor Enabled | ✅ | ✅ | Profiles in enforce mode |
| Auto Updates | ✅ | ✅ | Security updates automatic |
| Sudo Configured | ✅ | ✅ | Logging enabled |
| Root Locked | ✅ | ✅ | Password locked |
| Network Hardened | ✅ | ✅ | Kernel params configured |

---

## Maintenance Schedule

### Daily
- Review security logs for anomalies
- Check for failed login attempts
- Verify firewall is active

### Weekly
- Review sudo logs
- Check for available updates
- Verify backup integrity
- Review AppArmor denials

### Monthly
- Full security audit
- Review user accounts
- Update documentation
- Test disaster recovery

### Quarterly
- Security configuration review
- Penetration testing (if applicable)
- Policy updates

---

## References

- Ubuntu Security Guide: https://ubuntu.com/security
- CIS Benchmarks: https://www.cisecurity.org/benchmark/ubuntu_linux
- NIST Guidelines: https://csrc.nist.gov/
- OpenSSH Hardening: https://www.ssh.com/academy/ssh/sshd_config

# SSH Configuration and Key-Based Authentication

## Overview

Complete documentation for implementing secure SSH configuration with key-based authentication on Ubuntu Server 22.04.

---

## Phase 1: Initial Assessment

### Check Current SSH Configuration

```bash
# SSH to server
ssh admin@192.168.1.10

# Check SSH service status
sudo systemctl status sshd

# View current configuration
sudo cat /etc/ssh/sshd_config | grep -v "^#" | grep -v "^$"

# Check SSH version
ssh -V
# Expected: OpenSSH_8.9p1
```

---

## Phase 2: Backup Current Configuration

```bash
# Create backup with timestamp
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%Y%m%d-%H%M%S)

# Verify backup
ls -lh /etc/ssh/sshd_config.bak.*

# Create working copy
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.working
```

---

## Phase 3: Generate SSH Keys

### On Workstation (192.168.1.20)

```bash
# Generate Ed25519 key (recommended - modern, secure, fast)
ssh-keygen -t ed25519 -C "admin@workstation-$(date +%Y%m%d)" -f ~/.ssh/id_ed25519_server

# OR generate RSA 4096-bit key (wider compatibility)
ssh-keygen -t rsa -b 4096 -C "admin@workstation-$(date +%Y%m%d)" -f ~/.ssh/id_rsa_server

# Set strong passphrase when prompted (recommended)
# Or press Enter for no passphrase (less secure)

# Verify keys created
ls -l ~/.ssh/id_ed25519_server*
# Should see:
# id_ed25519_server (private key)
# id_ed25519_server.pub (public key)

# Set proper permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519_server
chmod 644 ~/.ssh/id_ed25519_server.pub

# View public key
cat ~/.ssh/id_ed25519_server.pub
```

---

## Phase 4: Deploy Public Key to Server

### Method 1: Using ssh-copy-id (Recommended)

```bash
# From workstation
ssh-copy-id -i ~/.ssh/id_ed25519_server.pub admin@192.168.1.10

# Enter password when prompted
# This will add the public key to ~/.ssh/authorized_keys on the server
```

### Method 2: Manual Copy

```bash
# From workstation
cat ~/.ssh/id_ed25519_server.pub | ssh admin@192.168.1.10 \
    "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# Or copy-paste manually
cat ~/.ssh/id_ed25519_server.pub
# Copy the output

# SSH to server
ssh admin@192.168.1.10

# On server:
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "<paste-public-key-here>" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### Verify Key Deployment

```bash
# On server: Check authorized_keys
cat ~/.ssh/authorized_keys

# Should contain your public key

# From workstation: Test key-based login
ssh -i ~/.ssh/id_ed25519_server admin@192.168.1.10
# Should log in without password (or with key passphrase only)
```

---

## Phase 5: Configure SSH Server (Hardening)

### Edit SSH Configuration

```bash
# On server
sudo vim /etc/ssh/sshd_config
```

### Recommended Configuration

```bash
# /etc/ssh/sshd_config - Hardened Configuration

# Protocol and Port
Port 22
Protocol 2

# Listening addresses
ListenAddress 0.0.0.0
ListenAddress ::

# Host keys (default is good)
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Logging
SyslogFacility AUTH
LogLevel VERBOSE

# Authentication
PermitRootLogin no
StrictModes yes
MaxAuthTries 3
MaxSessions 10

PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

# Disable password authentication
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no

# Kerberos and GSSAPI
KerberosAuthentication no
GSSAPIAuthentication no

# PAM
UsePAM yes

# Forwarding
AllowAgentForwarding no
AllowTcpForwarding no
X11Forwarding no
PermitTunnel no

# Timeout settings
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 60

# User restrictions
AllowUsers admin
# Or use AllowGroups ssh-users

# Banner
Banner /etc/ssh/banner

# Subsystem
Subsystem sftp /usr/lib/openssh/sftp-server

# Strong ciphers and algorithms
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr

MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256

KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
```

### Apply Configuration Using sed (Automated)

```bash
#!/bin/bash
# ssh-harden.sh - Automated SSH hardening

# Backup
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%Y%m%d-%H%M%S)

# Disable root login
sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

# Disable password authentication
sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#*PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
sudo sed -i 's/^#*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config

# Enable public key authentication
sudo sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Set MaxAuthTries
sudo sed -i 's/^#*MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config

# Set logging level
sudo sed -i 's/^#*LogLevel.*/LogLevel VERBOSE/' /etc/ssh/sshd_config

# Disable X11 forwarding
sudo sed -i 's/^#*X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config

# Set ClientAliveInterval
if ! grep -q "^ClientAliveInterval" /etc/ssh/sshd_config; then
    echo "ClientAliveInterval 300" | sudo tee -a /etc/ssh/sshd_config
fi

if ! grep -q "^ClientAliveCountMax" /etc/ssh/sshd_config; then
    echo "ClientAliveCountMax 2" | sudo tee -a /etc/ssh/sshd_config
fi

# Add AllowUsers
if ! grep -q "^AllowUsers" /etc/ssh/sshd_config; then
    echo "AllowUsers admin" | sudo tee -a /etc/ssh/sshd_config
fi

echo "SSH configuration updated"
```

---

## Phase 6: Create SSH Banner

```bash
# Create banner file
sudo tee /etc/ssh/banner << 'EOF'
***************************************************************************
                    AUTHORIZED ACCESS ONLY
                    
This system is for authorized use only. All activity is monitored and 
logged. Unauthorized access is prohibited and will be prosecuted to the 
fullest extent of the law.

By accessing this system, you consent to monitoring and recording.
***************************************************************************
EOF

# Ensure banner is referenced in sshd_config
if ! grep -q "^Banner /etc/ssh/banner" /etc/ssh/sshd_config; then
    echo "Banner /etc/ssh/banner" | sudo tee -a /etc/ssh/sshd_config
fi
```

---

## Phase 7: Test and Apply Configuration

### Test Configuration

```bash
# Test syntax
sudo sshd -t
# No output = configuration is valid
# Error output = fix errors before proceeding

# Test detailed
sudo sshd -T | less
# Shows all effective settings

# Check specific settings
sudo sshd -T | grep -i "passwordauthentication"
# Should show: passwordauthentication no

sudo sshd -T | grep -i "permitrootlogin"
# Should show: permitrootlogin no

sudo sshd -T | grep -i "pubkeyauthentication"
# Should show: pubkeyauthentication yes
```

### Important: Test Before Closing Current Session

```bash
# KEEP YOUR CURRENT SSH SESSION OPEN

# Open NEW terminal on workstation
# Test SSH connection with key
ssh -i ~/.ssh/id_ed25519_server admin@192.168.1.10

# Should work without password
# If it works, proceed to restart SSH
# If it fails, troubleshoot before closing original session
```

### Restart SSH Service

```bash
# Method 1: Reload (preferred - doesn't drop connections)
sudo systemctl reload sshd

# Method 2: Restart (drops all connections)
# sudo systemctl restart sshd

# Verify SSH is running
sudo systemctl status sshd
# Should show: active (running)

# Check if listening
sudo ss -tuln | grep :22
# Should show: LISTEN on port 22
```

---

## Phase 8: Configure Workstation SSH Client

### Create SSH Config File

```bash
# On workstation
vim ~/.ssh/config
```

### Add Configuration

```bash
# ~/.ssh/config

Host prod-server
    HostName 192.168.1.10
    User admin
    Port 22
    IdentityFile ~/.ssh/id_ed25519_server
    IdentitiesOnly yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
    StrictHostKeyChecking yes
    UserKnownHostsFile ~/.ssh/known_hosts
    ForwardAgent no
    ForwardX11 no
    
Host 192.168.1.10
    User admin
    IdentityFile ~/.ssh/id_ed25519_server
    IdentitiesOnly yes
```

### Set Proper Permissions

```bash
chmod 600 ~/.ssh/config
```

### Test Connection

```bash
# Using alias
ssh prod-server

# Or using IP
ssh 192.168.1.10

# Should connect without password (or only key passphrase)
```

---

## Phase 9: Disable Password Authentication Completely

### Final Verification

```bash
# Test 1: Verify key-based auth works
ssh -i ~/.ssh/id_ed25519_server admin@192.168.1.10
# Should work

# Test 2: Verify password auth is disabled
ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no admin@192.168.1.10
# Should fail with: Permission denied (publickey)

# Test 3: Verify root login is disabled
ssh root@192.168.1.10
# Should fail with: Permission denied (publickey)
```

---

## Phase 10: Lock Root Account (Optional but Recommended)

```bash
# On server
# Lock root password
sudo passwd -l root

# Verify
sudo passwd -S root
# Should show: root L ...
# (L means locked)

# Note: This doesn't prevent sudo access to root
# Just prevents password-based root login
```

---

## Monitoring and Logging

### Monitor SSH Connections

```bash
# Real-time monitoring
sudo tail -f /var/log/auth.log | grep sshd

# Recent successful logins
sudo grep "Accepted publickey" /var/log/auth.log | tail -20

# Recent failed attempts
sudo grep "Failed password" /var/log/auth.log | tail -20

# Current SSH sessions
who
w

# Show login history
last | head -20

# Show failed login attempts
sudo lastb | head -20
```

### SSH Log Analysis Script

```bash
#!/bin/bash
# ssh-log-analysis.sh

echo "=== SSH Log Analysis ==="
echo ""

echo "Successful logins (last 10):"
sudo grep "Accepted publickey" /var/log/auth.log | tail -10
echo ""

echo "Failed login attempts (last 10):"
sudo grep "Failed" /var/log/auth.log | tail -10
echo ""

echo "Unique IPs with failed attempts:"
sudo grep "Failed" /var/log/auth.log | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn
echo ""

echo "Current active SSH sessions:"
who
echo ""

echo "Total failed attempts today:"
sudo grep "$(date +"%b %d")" /var/log/auth.log | grep "Failed" | wc -l
```

---

## Troubleshooting

### Issue 1: Cannot connect with key

```bash
# Check permissions on workstation
ls -l ~/.ssh/
# Private key should be 600, public key 644

# Check permissions on server
ssh admin@192.168.1.10
ls -la ~/.ssh/
# .ssh directory should be 700
# authorized_keys should be 600

# Fix permissions if needed
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# Check SELinux context (if applicable)
ls -Z ~/.ssh/authorized_keys
# May need: restorecon -Rv ~/.ssh
```

### Issue 2: "Permission denied (publickey)"

```bash
# Check if key is being offered
ssh -v admin@192.168.1.10
# Look for lines like:
# debug1: Offering public key: /home/user/.ssh/id_ed25519_server

# Check if server accepts the key
sudo grep "$(cat ~/.ssh/id_ed25519_server.pub | awk '{print $2}')" ~/.ssh/authorized_keys
# Should show matching key

# Check SSH logs on server
sudo tail -50 /var/log/auth.log | grep sshd
```

### Issue 3: Configuration test fails

```bash
# Test configuration
sudo sshd -t
# Read error messages carefully

# Common issues:
# - Typos in directives
# - Invalid values
# - Missing files (like banner)

# Restore from backup if needed
sudo cp /etc/ssh/sshd_config.bak.* /etc/ssh/sshd_config
```

---

## Security Best Practices

### 1. Key Management
- Use strong passphrases on private keys
- Never share private keys
- Rotate keys annually
- Use different keys for different servers
- Store backups securely (encrypted)

### 2. Configuration Review
- Review sshd_config quarterly
- Monitor for new security advisories
- Keep OpenSSH updated
- Test changes in non-production first

### 3. Access Control
- Use AllowUsers or AllowGroups
- Implement principle of least privilege
- Regular audit of authorized_keys
- Remove keys for departed users immediately

### 4. Monitoring
- Enable verbose logging
- Monitor failed login attempts
- Set up alerts for suspicious activity
- Review logs weekly

---

## Verification Checklist

- [ ] SSH keys generated on workstation
- [ ] Public key deployed to server
- [ ] Key-based authentication tested and working
- [ ] Password authentication disabled
- [ ] Root login disabled
- [ ] Root account locked
- [ ] Strong ciphers configured
- [ ] SSH banner created
- [ ] MaxAuthTries set to 3
- [ ] Logging level set to VERBOSE
- [ ] X11 forwarding disabled
- [ ] AllowUsers configured
- [ ] Configuration syntax tested (sshd -t)
- [ ] SSH service restarted
- [ ] Connection tested from workstation
- [ ] Password auth verified as disabled
- [ ] Configuration backed up
- [ ] Workstation SSH config created
- [ ] Documentation updated

---

## Evidence Collection

### Screenshots to Capture

1. **Before Configuration:**
   ```bash
   sudo sshd -T | grep -E "passwordauthentication|permitrootlogin|pubkeyauthentication"
   ```

2. **After Configuration:**
   ```bash
   sudo sshd -T | grep -E "passwordauthentication|permitrootlogin|pubkeyauthentication"
   ```

3. **Successful Key-Based Login:**
   ```bash
   ssh -i ~/.ssh/id_ed25519_server admin@192.168.1.10
   whoami
   pwd
   ```

4. **Failed Password Login Attempt:**
   ```bash
   ssh -o PreferredAuthentications=password admin@192.168.1.10
   # Shows: Permission denied (publickey)
   ```

5. **Auth Log Showing Key-Based Login:**
   ```bash
   sudo grep "Accepted publickey" /var/log/auth.log | tail -5
   ```

---

## Conclusion

SSH is now configured with:

1. ✅ Key-based authentication only
2. ✅ Password authentication disabled
3. ✅ Root login disabled
4. ✅ Strong cryptographic algorithms
5. ✅ Connection timeouts configured
6. ✅ User access restricted
7. ✅ Verbose logging enabled
8. ✅ Security banner displayed

The server is now significantly more secure against:
- Brute force attacks
- Password guessing
- Unauthorized access
- Root compromise

---

## References

- OpenSSH Manual: https://www.openssh.com/manual.html
- Mozilla SSH Guidelines: https://infosec.mozilla.org/guidelines/openssh
- SSH Audit Tool: https://www.ssh-audit.com/
- CIS Benchmark for OpenSSH: https://www.cisecurity.org/

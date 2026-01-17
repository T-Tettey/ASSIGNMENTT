# Threat Model and Risk Assessment

## Overview

This document identifies potential security threats to the Linux server infrastructure, analyzes their impact, and provides comprehensive mitigation strategies.

---

## Threat Modeling Methodology

### STRIDE Framework

We use the STRIDE threat modeling framework:
- **S**poofing: Impersonating a user or system
- **T**ampering: Unauthorized modification of data
- **R**epudiation: Denying actions performed
- **I**nformation Disclosure: Exposing sensitive information
- **D**enial of Service: Making systems unavailable
- **E**levation of Privilege: Gaining unauthorized access

### Risk Assessment Matrix

| Likelihood \ Impact | Low | Medium | High | Critical |
|---------------------|-----|--------|------|----------|
| **Very Likely** | Medium | High | Critical | Critical |
| **Likely** | Low | Medium | High | Critical |
| **Possible** | Low | Low | Medium | High |
| **Unlikely** | Low | Low | Low | Medium |

---

## Threat #1: Brute Force SSH Attacks

### Threat Description

**Category:** Spoofing / Elevation of Privilege

**Attack Vector:**
Attackers attempt to gain unauthorized access by systematically trying different username/password combinations against the SSH service.

```
[Attacker] ----> SSH Brute Force ----> [Server:22]
               (Dictionary Attack)
               (Credential Stuffing)
```

**Attack Characteristics:**
- Automated tools (hydra, medusa, ncrack)
- Dictionary-based attacks
- Credential stuffing from leaked databases
- Distributed attacks from botnets
- Thousands of login attempts per minute

### Risk Assessment

**Without Mitigation:**
- **Likelihood:** Very Likely (SSH is commonly targeted)
- **Impact:** Critical (full system compromise)
- **Risk Level:** 🔴 **CRITICAL**

**With Mitigation:**
- **Likelihood:** Unlikely
- **Impact:** Low
- **Risk Level:** 🟢 **LOW**

### Impact Analysis

**If Successful:**
1. **Complete System Compromise:** Attacker gains shell access
2. **Data Breach:** Access to all files and databases
3. **Lateral Movement:** Can attack other systems on network
4. **Resource Hijacking:** Use server for cryptomining, DDoS
5. **Backdoor Installation:** Persistent access mechanism
6. **Data Destruction:** Potential data loss or ransomware

**Financial Impact:**
- Incident response costs: $10,000+
- Downtime costs: $5,000-50,000/hour
- Reputation damage: Immeasurable
- Legal/compliance penalties: $50,000+

### Mitigation Strategies

#### Primary Defenses

**1. Disable Password Authentication**

```bash
# /etc/ssh/sshd_config
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no

# Restart SSH
sudo systemctl restart sshd
```

**Effectiveness:** 99% - Eliminates password-based attacks

**2. Implement Key-Based Authentication**

```bash
# Generate strong SSH key (4096-bit RSA or Ed25519)
ssh-keygen -t ed25519 -C "admin@workstation" -f ~/.ssh/id_ed25519
# OR
ssh-keygen -t rsa -b 4096 -C "admin@workstation" -f ~/.ssh/id_rsa

# Copy to server
ssh-copy-id -i ~/.ssh/id_ed25519.pub admin@192.168.1.10

# Set proper permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

**Effectiveness:** 99% - Requires physical key possession

**3. Install and Configure fail2ban**

```bash
# Install fail2ban
sudo apt install -y fail2ban

# Create local configuration
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Edit /etc/fail2ban/jail.local
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

# Start and enable
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Check status
sudo fail2ban-client status sshd
```

**Effectiveness:** 90% - Blocks IPs after failed attempts

**4. Firewall IP Whitelisting**

```bash
# Allow SSH only from known IP
sudo ufw allow from 192.168.1.20 to any port 22 proto tcp

# Deny all other SSH
sudo ufw deny 22/tcp

# Enable firewall
sudo ufw enable
```

**Effectiveness:** 95% - Restricts access to trusted sources

**5. Disable Root Login**

```bash
# /etc/ssh/sshd_config
PermitRootLogin no

# Lock root account
sudo passwd -l root
```

**Effectiveness:** 80% - Reduces attack surface

#### Secondary Defenses

**6. Change Default SSH Port (Security through Obscurity)**

```bash
# /etc/ssh/sshd_config
Port 2222

# Update firewall
sudo ufw allow from 192.168.1.20 to any port 2222 proto tcp
sudo ufw delete allow 22/tcp
```

**Effectiveness:** 50% - Reduces automated scans

**7. Implement Two-Factor Authentication**

```bash
# Install Google Authenticator
sudo apt install -y libpam-google-authenticator

# Configure for user
google-authenticator

# Edit /etc/pam.d/sshd
auth required pam_google_authenticator.so

# Edit /etc/ssh/sshd_config
ChallengeResponseAuthentication yes
AuthenticationMethods publickey,keyboard-interactive
```

**Effectiveness:** 99.9% - Requires both key and OTP

#### Monitoring and Detection

```bash
# Monitor failed login attempts
sudo journalctl -u sshd | grep "Failed password"

# Real-time monitoring
sudo tail -f /var/log/auth.log | grep sshd

# Count failed attempts
sudo grep "Failed password" /var/log/auth.log | wc -l

# List banned IPs (fail2ban)
sudo fail2ban-client status sshd

# Alert script
#!/bin/bash
# /usr/local/bin/ssh-alert.sh
FAILED_COUNT=$(grep "Failed password" /var/log/auth.log | grep "$(date +"%b %d")" | wc -l)
if [ $FAILED_COUNT -gt 10 ]; then
    echo "WARNING: $FAILED_COUNT failed SSH attempts today" | mail -s "SSH Alert" admin@example.com
fi
```

### Validation and Testing

```bash
# Test 1: Verify password auth is disabled
ssh -o PreferredAuthentications=password admin@192.168.1.10
# Expected: Permission denied (publickey)

# Test 2: Verify key-based auth works
ssh -i ~/.ssh/id_ed25519 admin@192.168.1.10
# Expected: Successful login

# Test 3: Check fail2ban
sudo fail2ban-client status sshd

# Test 4: Verify firewall rules
sudo ufw status verbose | grep 22

# Test 5: Check SSH configuration
sudo sshd -T | grep -E "passwordauthentication|permitrootlogin"
```

### Incident Response Plan

**If Attack Detected:**

1. **Immediate Actions:**
   ```bash
   # Block attacking IP
   sudo ufw deny from <attacker_ip>
   
   # Check for successful logins
   sudo last | head -20
   sudo lastb | head -20
   
   # Review active sessions
   who
   w
   ```

2. **Investigation:**
   ```bash
   # Analyze auth logs
   sudo grep "Accepted" /var/log/auth.log
   sudo grep "session opened" /var/log/auth.log
   
   # Check for suspicious processes
   ps aux | grep -v "\[" | sort -nrk 3,3 | head -20
   
   # Review command history
   sudo cat /home/*/.bash_history
   ```

3. **Recovery:**
   - Change all passwords and regenerate SSH keys
   - Review system for backdoors
   - Restore from known good backup if compromised
   - Document incident for future prevention

---

## Threat #2: Privilege Escalation via Misconfigured sudo

### Threat Description

**Category:** Elevation of Privilege

**Attack Vector:**
Attacker with limited user access exploits misconfigured sudo permissions to gain root privileges.

```
[Limited User] ---> sudo Exploit ---> [Root Access]
                 (Misconfiguration)
                 (Binary Exploitation)
```

**Attack Methods:**
1. **Sudo Misconfiguration:** NOPASSWD directives, overly permissive rules
2. **Binary Exploitation:** Abuse of sudo-allowed binaries (vim, less, find, etc.)
3. **Environment Variable Manipulation:** PATH hijacking, LD_PRELOAD
4. **Sudo Vulnerabilities:** CVE exploits (e.g., CVE-2021-3156 "Baron Samedit")

### Risk Assessment

**Without Mitigation:**
- **Likelihood:** Likely (common misconfiguration)
- **Impact:** Critical (full root access)
- **Risk Level:** 🔴 **CRITICAL**

**With Mitigation:**
- **Likelihood:** Unlikely
- **Impact:** Medium
- **Risk Level:** 🟡 **LOW-MEDIUM**

### Impact Analysis

**If Successful:**
1. **Complete System Control:** Full root privileges
2. **Security Bypass:** Disable logging, monitoring, security tools
3. **Persistence:** Install rootkits, backdoors
4. **Data Access:** Read any file, including /etc/shadow
5. **System Modification:** Install malware, modify system files
6. **Cover Tracks:** Delete logs, hide presence

### Real-World Examples

**Dangerous Sudo Configurations:**

```bash
# BAD: User can run anything as root without password
user ALL=(ALL) NOPASSWD: ALL

# BAD: Dangerous binaries with sudo
user ALL=(ALL) NOPASSWD: /usr/bin/vim
user ALL=(ALL) NOPASSWD: /usr/bin/find
user ALL=(ALL) NOPASSWD: /bin/bash
user ALL=(ALL) NOPASSWD: /usr/bin/python*

# BAD: Wildcard permissions
user ALL=(ALL) NOPASSWD: /usr/bin/*
```

**Exploitation Examples:**

```bash
# Vim escape
sudo vim -c ':!/bin/bash'

# Find command execution
sudo find / -exec /bin/bash \;

# Less pager escape
sudo less /etc/hosts
# Then type: !bash

# Python execution
sudo python -c 'import os; os.system("/bin/bash")'
```

### Mitigation Strategies

#### Primary Defenses

**1. Principle of Least Privilege**

```bash
# /etc/sudoers (use visudo to edit)

# GOOD: Specific commands only
admin ALL=(ALL) /usr/sbin/systemctl restart nginx, /usr/sbin/systemctl status nginx
admin ALL=(ALL) /usr/bin/apt update, /usr/bin/apt upgrade

# GOOD: Require password for sudo
Defaults passwd_timeout=15
Defaults timestamp_timeout=15

# GOOD: Log all sudo commands
Defaults logfile="/var/log/sudo.log"
Defaults log_input, log_output
Defaults log_year, log_host

# GOOD: Secure PATH
Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# GOOD: Prevent environment variable attacks
Defaults env_reset
Defaults env_keep -= "LD_PRELOAD"
Defaults env_keep -= "LD_LIBRARY_PATH"
```

**Effectiveness:** 90% - Limits sudo abuse

**2. Regular sudo Audits**

```bash
#!/bin/bash
# sudo-audit.sh

echo "=== Sudo Configuration Audit ==="
echo ""

echo "1. Users with sudo access:"
grep -Po '^sudo.+:\K.*$' /etc/group
echo ""

echo "2. NOPASSWD entries (HIGH RISK):"
sudo grep NOPASSWD /etc/sudoers /etc/sudoers.d/* 2>/dev/null
echo ""

echo "3. Wildcard permissions (HIGH RISK):"
sudo grep "\*" /etc/sudoers /etc/sudoers.d/* 2>/dev/null
echo ""

echo "4. Recent sudo usage:"
sudo grep "COMMAND" /var/log/sudo.log | tail -20
echo ""

echo "5. Dangerous binaries with sudo:"
sudo grep -E "(vim|find|less|more|nano|python|perl|ruby|bash|sh)" /etc/sudoers /etc/sudoers.d/* 2>/dev/null
```

**Effectiveness:** 85% - Identifies misconfigurations

**3. Keep sudo Updated**

```bash
# Check sudo version
sudo -V | head -1

# Update sudo
sudo apt update
sudo apt install --only-upgrade sudo

# Check for known vulnerabilities
sudo apt list --installed | grep sudo
apt-cache policy sudo
```

**Effectiveness:** 95% - Patches known vulnerabilities

**4. Implement AppArmor/SELinux Profiles**

```bash
# AppArmor restricts what even root can do
sudo aa-status

# Create profile for critical applications
sudo aa-genprof /usr/bin/sensitive-app

# Enforce profiles
sudo aa-enforce /etc/apparmor.d/*
```

**Effectiveness:** 80% - Defense in depth

#### Monitoring and Detection

```bash
# Monitor sudo usage in real-time
sudo tail -f /var/log/sudo.log

# Alert on suspicious sudo usage
#!/bin/bash
# /usr/local/bin/sudo-monitor.sh
SUSPICIOUS_COMMANDS="vim|nano|python|bash|sh|find"
sudo tail -n 0 -F /var/log/sudo.log | while read line; do
    if echo "$line" | grep -E "$SUSPICIOUS_COMMANDS" > /dev/null; then
        echo "ALERT: Suspicious sudo command detected: $line" | 
        mail -s "Sudo Alert" admin@example.com
    fi
done

# Run as systemd service
```

**Audit Questions:**
- [ ] Are there any NOPASSWD entries?
- [ ] Are wildcards used in sudo rules?
- [ ] Can users run shell interpreters (bash, python, etc.)?
- [ ] Can users run text editors (vim, nano)?
- [ ] Is sudo logging enabled?
- [ ] Are sudo logs monitored?
- [ ] Is sudo version up to date?

### Validation and Testing

```bash
# Test 1: Verify sudo requires password
sudo -n ls /root
# Expected: password required

# Test 2: Check sudo configuration
sudo visudo -c
# Expected: parsed OK

# Test 3: Review sudo permissions
sudo -l
# Review output for dangerous permissions

# Test 4: Check sudo logs
sudo cat /var/log/sudo.log | tail -20

# Test 5: Verify secure_path
sudo -V | grep "Value to override"
```

### Incident Response Plan

**If Privilege Escalation Detected:**

1. **Immediate Actions:**
   ```bash
   # Revoke sudo access
   sudo deluser <compromised_user> sudo
   
   # Kill user sessions
   sudo pkill -u <compromised_user>
   
   # Lock account
   sudo passwd -l <compromised_user>
   ```

2. **Investigation:**
   ```bash
   # Review sudo logs
   sudo grep <compromised_user> /var/log/sudo.log
   
   # Check command history
   sudo cat /home/<compromised_user>/.bash_history
   
   # Look for privilege escalation attempts
   sudo grep -E "(vim|find|python|bash).*(root|sudo)" /var/log/auth.log
   
   # Check for backdoors
   sudo find / -perm -4000 -type f 2>/dev/null
   ```

3. **Recovery:**
   - Review and fix sudo configuration
   - Reset all user passwords
   - Audit system for unauthorized changes
   - Restore from backup if necessary

---

## Threat #3: Denial of Service (DoS) Attacks

### Threat Description

**Category:** Denial of Service

**Attack Vector:**
Attacker floods the server with requests or exploits resource exhaustion to make services unavailable to legitimate users.

```
[Attacker/Botnet] ---> Flood Attack ---> [Server] ---> Service Unavailable
                   (Network Layer)
                   (Application Layer)
                   (Resource Exhaustion)
```

**Attack Types:**

1. **Network Layer DoS:**
   - SYN flood attacks
   - UDP flood
   - ICMP flood (ping flood)
   - Amplification attacks (DNS, NTP)

2. **Application Layer DoS:**
   - HTTP flood (GET/POST requests)
   - Slowloris (slow HTTP connections)
   - Application-specific exploits

3. **Resource Exhaustion:**
   - Fork bombs
   - Disk space exhaustion
   - Memory exhaustion
   - CPU exhaustion

### Risk Assessment

**Without Mitigation:**
- **Likelihood:** Possible (depends on visibility)
- **Impact:** High (service unavailability)
- **Risk Level:** 🟡 **MEDIUM-HIGH**

**With Mitigation:**
- **Likelihood:** Possible
- **Impact:** Low-Medium
- **Risk Level:** 🟢 **LOW**

### Impact Analysis

**If Successful:**
1. **Service Downtime:** Applications become unavailable
2. **Financial Loss:** Revenue loss during downtime
3. **Reputation Damage:** User trust erosion
4. **Productivity Loss:** Internal operations disrupted
5. **Resource Costs:** Bandwidth and infrastructure costs
6. **Cascade Effects:** Dependent services also fail

**Downtime Costs:**
- Small business: $8,000 - $74,000 per hour
- Enterprise: $100,000 - $540,000 per hour
- E-commerce: $200,000 - $300,000 per hour

### Mitigation Strategies

#### Primary Defenses

**1. Kernel Network Hardening**

```bash
# /etc/sysctl.d/99-dos-protection.conf

# SYN flood protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# Connection tracking
net.netfilter.nf_conntrack_max = 200000
net.ipv4.netfilter.ip_conntrack_max = 200000

# IP spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# ICMP flood protection
net.ipv4.icmp_echo_ignore_all = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# TCP hardening
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1800

# Limit number of connections
net.core.somaxconn = 2048
net.core.netdev_max_backlog = 2048

# Apply settings
sudo sysctl -p /etc/sysctl.d/99-dos-protection.conf
```

**Effectiveness:** 80% - Mitigates network-layer attacks

**2. Connection Rate Limiting with UFW**

```bash
# Limit SSH connections
sudo ufw limit 22/tcp comment "Rate limit SSH"

# Limit HTTP connections (if web server)
sudo ufw limit 80/tcp
sudo ufw limit 443/tcp

# Custom rate limiting
# Allow max 10 connections per minute from same IP
sudo iptables -A INPUT -p tcp --dport 80 -m state --state NEW -m recent --set
sudo iptables -A INPUT -p tcp --dport 80 -m state --state NEW -m recent --update --seconds 60 --hitcount 10 -j DROP
```

**Effectiveness:** 70% - Slows down application-layer attacks

**3. Resource Limits (ulimit)**

```bash
# /etc/security/limits.conf

# Limit processes per user
* hard nproc 1000
* soft nproc 800

# Limit open files
* hard nofile 10000
* soft nofile 8000

# Limit CPU time (minutes)
* hard cpu 60
* soft cpu 30

# Limit memory (KB)
* hard as 4000000
* soft as 3000000

# Apply to current session
sudo sysctl -p

# Verify limits
ulimit -a
```

**Effectiveness:** 85% - Prevents resource exhaustion

**4. Application-Level Protection**

```bash
# For web servers (Nginx example)
# /etc/nginx/nginx.conf

http {
    # Connection limits
    limit_conn_zone $binary_remote_addr zone=addr:10m;
    limit_conn addr 10;
    
    # Request rate limiting
    limit_req_zone $binary_remote_addr zone=one:10m rate=10r/s;
    limit_req zone=one burst=20 nodelay;
    
    # Timeout settings
    client_body_timeout 10s;
    client_header_timeout 10s;
    keepalive_timeout 30s;
    send_timeout 10s;
    
    # Buffer size limits
    client_body_buffer_size 128k;
    client_header_buffer_size 1k;
    client_max_body_size 10m;
}
```

**Effectiveness:** 75% - Protects web applications

**5. Fail2ban for Application DoS**

```bash
# /etc/fail2ban/jail.local

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
action = iptables-multiport[name=ReqLimit, port="http,https", protocol=tcp]
logpath = /var/log/nginx/error.log
findtime = 600
bantime = 7200
maxretry = 10

[nginx-dos]
enabled = true
filter = nginx-dos
action = iptables-multiport[name=NosDos, port="http,https", protocol=tcp]
logpath = /var/log/nginx/access.log
findtime = 60
bantime = 600
maxretry = 200
```

**Effectiveness:** 70% - Blocks repeat offenders

#### Monitoring and Detection

```bash
# Real-time connection monitoring
watch -n 1 'ss -s'

# Monitor bandwidth usage
iftop -i enp0s8

# Check for SYN flood
netstat -tuna | grep SYN_RECV | wc -l

# Connection count per IP
netstat -ntu | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -n

# Monitor system load
uptime
watch -n 1 'cat /proc/loadavg'

# Alert script
#!/bin/bash
# /usr/local/bin/dos-monitor.sh
MAX_LOAD=5.0
MAX_CONNECTIONS=1000

LOAD=$(cat /proc/loadavg | awk '{print $1}')
CONNS=$(ss -s | grep "TCP:" | awk '{print $2}')

if (( $(echo "$LOAD > $MAX_LOAD" | bc -l) )); then
    echo "High load detected: $LOAD" | mail -s "DoS Alert" admin@example.com
fi

if [ $CONNS -gt $MAX_CONNECTIONS ]; then
    echo "High connection count: $CONNS" | mail -s "DoS Alert" admin@example.com
fi
```

### Validation and Testing

```bash
# Test 1: Verify SYN cookies enabled
sysctl net.ipv4.tcp_syncookies
# Expected: net.ipv4.tcp_syncookies = 1

# Test 2: Check connection limits
ulimit -a

# Test 3: Test rate limiting (be careful!)
# From another machine:
for i in {1..20}; do curl http://192.168.1.10 & done
# Some should be rate limited

# Test 4: Monitor resource usage under load
stress --cpu 2 --io 1 --vm 1 --vm-bytes 512M --timeout 60s &
watch -n 1 'top -bn1 | head -20'

# Test 5: Verify fail2ban is active
sudo fail2ban-client status
```

### Incident Response Plan

**If DoS Attack Detected:**

1. **Immediate Actions:**
   ```bash
   # Identify top connection sources
   netstat -ntu | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head -10
   
   # Block attacking IPs
   sudo ufw deny from <attacker_ip>
   
   # Enable aggressive rate limiting
   sudo sysctl -w net.ipv4.tcp_syn_retries=1
   sudo sysctl -w net.ipv4.tcp_synack_retries=1
   ```

2. **Mitigation:**
   ```bash
   # Drop all new connections temporarily
   sudo iptables -A INPUT -m state --state NEW -j DROP
   
   # Allow only known good IPs
   sudo iptables -I INPUT -s 192.168.1.20 -j ACCEPT
   
   # Restart affected services
   sudo systemctl restart nginx
   ```

3. **Post-Incident:**
   - Document attack characteristics
   - Review and strengthen defenses
   - Consider CDN/DDoS protection service
   - Update incident response procedures

---

## Additional Threats (Brief)

### Threat #4: Malware and Rootkits

**Mitigation:**
- Regular system scans (rkhunter, chkrootkit, ClamAV)
- File integrity monitoring (AIDE, Tripwire)
- Keep systems updated
- Restrict execution permissions

### Threat #5: Data Exfiltration

**Mitigation:**
- Monitor network traffic for unusual patterns
- Encrypt sensitive data at rest
- Implement data loss prevention (DLP)
- Regular audit of file access logs

### Threat #6: Supply Chain Attacks

**Mitigation:**
- Verify package signatures
- Use official repositories only
- Pin critical package versions
- Regular security audits of dependencies

---

## Comprehensive Security Posture

### Defense in Depth Strategy

```
┌─────────────────────────────────────────────┐
│ Layer 7: Security Awareness & Training     │
├─────────────────────────────────────────────┤
│ Layer 6: Physical Security                 │
├─────────────────────────────────────────────┤
│ Layer 5: Application Security              │
│ - Input validation, secure coding          │
├─────────────────────────────────────────────┤
│ Layer 4: Access Control (MAC)              │
│ - AppArmor/SELinux profiles                │
├─────────────────────────────────────────────┤
│ Layer 3: Authentication & Authorization    │
│ - SSH keys, sudo, user management          │
├─────────────────────────────────────────────┤
│ Layer 2: Network Security                  │
│ - Firewall, IDS/IPS, network segmentation │
├─────────────────────────────────────────────┤
│ Layer 1: Host Hardening                    │
│ - Minimal install, updates, monitoring     │
└─────────────────────────────────────────────┘
```

### Security Metrics and KPIs

| Metric | Target | Measurement |
|--------|--------|-------------|
| Failed SSH attempts | < 100/day | `grep "Failed password" /var/log/auth.log` |
| Blocked IPs (fail2ban) | Monitor | `fail2ban-client status` |
| Security updates pending | 0 | `apt list --upgradable | grep security` |
| Sudo policy violations | 0 | Review sudo logs |
| System load average | < CPU count | `uptime` |
| AppArmor denials | < 10/day | `aa-notify` |
| Firewall blocks | Monitor | `grep "UFW BLOCK" /var/log/ufw.log` |

### Regular Security Tasks

**Daily:**
- [ ] Review auth logs for suspicious activity
- [ ] Check fail2ban banned IPs
- [ ] Monitor system load and resources
- [ ] Verify critical services are running

**Weekly:**
- [ ] Review sudo logs
- [ ] Check for available security updates
- [ ] Audit user accounts
- [ ] Review firewall logs
- [ ] Scan for malware (rkhunter)

**Monthly:**
- [ ] Full security audit
- [ ] Review and update access controls
- [ ] Test backup restoration
- [ ] Update documentation
- [ ] Security training refresher

**Quarterly:**
- [ ] Penetration testing
- [ ] Review threat model
- [ ] Update incident response procedures
- [ ] Third-party security assessment

---

## Conclusion

This threat model identifies the three most critical threats:

1. **🔴 Brute Force SSH Attacks** - Mitigated through key-based auth, fail2ban, and IP whitelisting
2. **🔴 Privilege Escalation** - Mitigated through proper sudo configuration and monitoring
3. **🟡 DoS Attacks** - Mitigated through kernel hardening, rate limiting, and resource controls

By implementing the mitigation strategies outlined in this document, the overall security posture is significantly improved, reducing risk from **CRITICAL** to **LOW** for most threats.

### Key Takeaways

- **Defense in Depth:** Multiple layers of security controls
- **Proactive Monitoring:** Early detection and response
- **Regular Updates:** Patch management is critical
- **Least Privilege:** Minimize attack surface
- **Incident Response:** Be prepared for security events

---

## References

- OWASP Top 10: https://owasp.org/www-project-top-ten/
- CIS Controls: https://www.cisecurity.org/controls
- NIST Cybersecurity Framework: https://www.nist.gov/cyberframework
- MITRE ATT&CK: https://attack.mitre.org/
- Linux Security Best Practices: https://linux-audit.com/

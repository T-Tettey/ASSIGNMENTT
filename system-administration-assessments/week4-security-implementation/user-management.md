# User Management and Privilege Configuration

## Overview

Complete guide for user management, sudo configuration, and implementing the principle of least privilege.

---

## Phase 1: Create Administrative User

### Create User Account

```bash
# SSH to server
ssh admin@192.168.1.10

# Create new user
sudo adduser admin

# Set strong password
# Enter password when prompted
# Fill in user information (or press Enter to skip)
```

### Add User to sudo Group

```bash
# Add user to sudo group
sudo usermod -aG sudo admin

# Verify group membership
groups admin
# Should show: admin : admin sudo

id admin
# Should show sudo in groups
```

### Test sudo Access

```bash
# Switch to new user
su - admin

# Test sudo
sudo whoami
# Should show: root

# Check sudo permissions
sudo -l
# Should show allowed commands
```

---

## Phase 2: Disable Root Account

### Lock Root Password

```bash
# Lock root account
sudo passwd -l root

# Verify root is locked
sudo passwd -S root
# Output should show: root L ...
# L = Locked
```

### Disable Root SSH Login

```bash
# Already done in SSH configuration
# Verify in /etc/ssh/sshd_config:
sudo grep "^PermitRootLogin" /etc/ssh/sshd_config
# Should show: PermitRootLogin no
```

### Verify Root Cannot Login

```bash
# Try to SSH as root (should fail)
ssh root@192.168.1.10
# Should get: Permission denied (publickey)

# Try to login at console (if available)
# Should fail with locked account
```

---

## Phase 3: Configure sudo

### Edit sudoers File (Always use visudo)

```bash
# Edit sudoers safely
sudo visudo

# NEVER edit /etc/sudoers directly!
# visudo checks syntax before saving
```

### Recommended sudo Configuration

```bash
# Add to /etc/sudoers

# Defaults
Defaults    env_reset
Defaults    mail_badpass
Defaults    secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"

# Password timeout (15 minutes)
Defaults    timestamp_timeout=15

# Require password for sudo
Defaults    passwd_timeout=0

# Log all sudo commands
Defaults    logfile="/var/log/sudo.log"
Defaults    log_year, log_host, log_input, log_output

# User privilege specification
root    ALL=(ALL:ALL) ALL

# Members of admin group
%admin  ALL=(ALL) ALL

# Members of sudo group  
%sudo   ALL=(ALL:ALL) ALL

# Specific user with full access
admin   ALL=(ALL:ALL) ALL
```

### Limited sudo Access Example

```bash
# User can only restart specific services
admin ALL=(ALL) NOPASSWD: /usr/sbin/systemctl restart nginx, /usr/sbin/systemctl restart postgresql

# User can only run monitoring commands
admin ALL=(ALL) NOPASSWD: /usr/bin/top, /usr/bin/htop, /usr/bin/iostat

# User can manage packages
admin ALL=(ALL) /usr/bin/apt update, /usr/bin/apt upgrade, /usr/bin/apt install
```

---

## Phase 4: Password Policies

### Install Password Quality Library

```bash
# Install libpam-pwquality
sudo apt install -y libpam-pwquality
```

### Configure Password Requirements

```bash
# Edit password quality configuration
sudo vim /etc/security/pwquality.conf

# Recommended settings:
minlen = 12
minclass = 3
maxrepeat = 3
maxsequence = 3
reject_username
enforcing = 1
dcredit = -1
ucredit = -1
ocredit = -1
lcredit = -1
```

**Settings Explanation:**
- `minlen = 12`: Minimum password length
- `minclass = 3`: At least 3 character classes (upper, lower, digit, special)
- `maxrepeat = 3`: Max consecutive repeated characters
- `maxsequence = 3`: Max monotonic character sequences
- `reject_username`: Password cannot contain username
- `dcredit = -1`: At least 1 digit required
- `ucredit = -1`: At least 1 uppercase required
- `ocredit = -1`: At least 1 special character required
- `lcredit = -1`: At least 1 lowercase required

### Test Password Policy

```bash
# Try to set weak password
sudo passwd admin
# Try: admin123
# Should be rejected

# Try strong password
# Example: P@ssw0rd2024!
# Should be accepted
```

---

## Phase 5: Account Expiration Policies

### Configure Password Aging

```bash
# Set password aging for user
sudo chage -M 90 admin   # Max 90 days
sudo chage -m 7 admin    # Min 7 days between changes
sudo chage -W 14 admin   # Warn 14 days before expiry
sudo chage -I 30 admin   # Inactive 30 days after expiry

# View aging information
sudo chage -l admin
```

### Set Account Expiration Date

```bash
# Set expiration date (for temporary accounts)
sudo chage -E 2025-12-31 tempuser

# Remove expiration
sudo chage -E -1 admin

# View expiration
sudo chage -l admin | grep "Account expires"
```

### Default Password Aging (System-Wide)

```bash
# Edit login.defs
sudo vim /etc/login.defs

# Set defaults:
PASS_MAX_DAYS   90
PASS_MIN_DAYS   7
PASS_WARN_AGE   14
PASS_MIN_LEN    12
```

---

## Phase 6: User Audit and Management

### List All Users

```bash
# All users
cat /etc/passwd

# Human users only (UID >= 1000)
awk -F: '$3 >= 1000 {print $1}' /etc/passwd

# Users with login shell
grep -v "/nologin\|/false" /etc/passwd
```

### List Users with sudo Access

```bash
# Users in sudo group
getent group sudo

# Users in admin group
getent group admin

# Check specific user
sudo -l -U admin
```

### User Activity Monitoring

```bash
# Currently logged in users
who
w

# Last logins
last | head -20

# Failed login attempts
sudo lastb | head -20

# User's command history
sudo cat /home/admin/.bash_history
```

---

## Phase 7: sudo Logging and Monitoring

### Enable sudo Logging

```bash
# Already configured in visudo
# Verify log file exists
ls -l /var/log/sudo.log

# View recent sudo commands
sudo tail -50 /var/log/sudo.log

# View specific user's sudo commands
sudo grep "admin" /var/log/sudo.log | tail -20
```

### Monitor sudo Usage

```bash
#!/bin/bash
# sudo-monitor.sh

echo "=== Sudo Usage Report ==="
echo "Generated: $(date)"
echo ""

echo "--- Recent sudo Commands (Last 20) ---"
sudo tail -20 /var/log/sudo.log
echo ""

echo "--- Failed sudo Attempts ---"
sudo grep "authentication failure" /var/log/auth.log | grep sudo | tail -10
echo ""

echo "--- Sudo Users ---"
getent group sudo
echo ""

echo "--- Users with NOPASSWD ---"
sudo grep "NOPASSWD" /etc/sudoers /etc/sudoers.d/* 2>/dev/null
```

---

## Phase 8: Additional Security Measures

### Restrict su Command

```bash
# Only allow sudo group to use su
sudo dpkg-statoverride --update --add root sudo 4750 /bin/su

# Verify
ls -l /bin/su
# Should show: -rwsr-x--- 1 root sudo
```

### Disable Unused Accounts

```bash
# Lock account
sudo usermod -L username

# Expire account
sudo usermod -e 1 username

# Set shell to nologin
sudo usermod -s /usr/sbin/nologin username
```

### Remove Unused Users

```bash
# Delete user and home directory
sudo deluser --remove-home username

# Or keep home directory for backup
sudo deluser username
sudo tar -czf /backup/username-home-$(date +%Y%m%d).tar.gz /home/username
```

---

## User Management Scripts

### Create User Script

```bash
#!/bin/bash
# create-admin-user.sh

if [ $# -ne 1 ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

USERNAME=$1

echo "Creating administrative user: $USERNAME"

# Create user
sudo adduser --gecos "" $USERNAME

# Add to sudo group
sudo usermod -aG sudo $USERNAME

# Set password aging
sudo chage -M 90 -m 7 -W 14 $USERNAME

# Verify
echo ""
echo "User created successfully:"
id $USERNAME
sudo chage -l $USERNAME
```

### User Audit Script

```bash
#!/bin/bash
# audit-users.sh

echo "=== User Account Audit ==="
echo "Generated: $(date)"
echo ""

echo "--- Human Users (UID >= 1000) ---"
awk -F: '$3 >= 1000 {printf "%-15s UID: %-5s Home: %s\n", $1, $3, $6}' /etc/passwd
echo ""

echo "--- Users with sudo Access ---"
getent group sudo admin
echo ""

echo "--- Locked Accounts ---"
sudo passwd -S -a | grep " L "
echo ""

echo "--- Accounts Without Password ---"
sudo passwd -S -a | grep "NP"
echo ""

echo "--- Password Aging Information ---"
for user in $(awk -F: '$3 >= 1000 {print $1}' /etc/passwd); do
    echo "User: $user"
    sudo chage -l $user | grep -E "Last password change|Password expires|Account expires"
    echo ""
done
```

---

## Principle of Least Privilege

### Implementation Checklist

1. **User Access**
   - [ ] Create dedicated user accounts (no shared accounts)
   - [ ] Disable root login
   - [ ] Use sudo for administrative tasks
   - [ ] Grant minimum necessary permissions

2. **sudo Configuration**
   - [ ] Require password for sudo
   - [ ] Set reasonable timeout (15 minutes)
   - [ ] Log all sudo commands
   - [ ] Review sudo permissions regularly

3. **Password Security**
   - [ ] Enforce strong passwords (12+ characters)
   - [ ] Implement password aging (90 days max)
   - [ ] Prevent password reuse
   - [ ] Lock accounts after failed attempts

4. **Account Management**
   - [ ] Regular user audits
   - [ ] Remove/disable unused accounts
   - [ ] Monitor sudo usage
   - [ ] Review login attempts

---

## Verification Checklist

- [ ] Admin user created
- [ ] Admin user added to sudo group
- [ ] sudo access tested and working
- [ ] Root account locked
- [ ] Root SSH login disabled
- [ ] sudoers file configured
- [ ] sudo logging enabled
- [ ] Password policy configured (12+ chars, complexity)
- [ ] Password aging set (90 day max)
- [ ] Unused accounts disabled/removed
- [ ] User audit script created
- [ ] sudo monitoring in place
- [ ] Documentation updated

---

## Evidence Collection

### Screenshots/Output to Capture

```bash
# 1. User creation
id admin
groups admin

# 2. sudo access
sudo -l
sudo whoami

# 3. Root account locked
sudo passwd -S root

# 4. sudoers configuration
sudo cat /etc/sudoers | grep -v "^#" | grep -v "^$"

# 5. Password policy
sudo cat /etc/security/pwquality.conf | grep -v "^#" | grep -v "^$"

# 6. Password aging
sudo chage -l admin

# 7. sudo log
sudo tail -20 /var/log/sudo.log

# 8. Current users
who
w
```

---

## Troubleshooting

### Issue: User cannot sudo

```bash
# Check group membership
groups username

# Add to sudo group
sudo usermod -aG sudo username

# User must logout and login again
exit
ssh admin@192.168.1.10
```

### Issue: sudo requires password every time

```bash
# Check timestamp_timeout
sudo grep timestamp_timeout /etc/sudoers

# Default is 15 minutes
# Set to 0 for always require password
# Set to -1 for never timeout (not recommended)
```

### Issue: Locked out after locking root

```bash
# Access via console or VirtualBox
# Or ensure another admin user exists first

# Unlock root if needed
sudo passwd -u root
```

---

## Best Practices Summary

1. **Never share accounts** - Each person gets their own account
2. **Use sudo, not root** - Don't login as root
3. **Strong passwords** - Enforce complexity and aging
4. **Monitor activity** - Log and review sudo usage
5. **Regular audits** - Review users and permissions monthly
6. **Least privilege** - Grant only necessary permissions
7. **Document changes** - Keep records of user management actions

---

## Conclusion

User management is now configured with:

1. ✅ Administrative user with sudo access
2. ✅ Root account disabled
3. ✅ sudo properly configured and logged
4. ✅ Strong password policies enforced
5. ✅ Password aging implemented
6. ✅ Monitoring and auditing in place

Security improvements:
- Reduced attack surface (no root login)
- Accountability (all sudo commands logged)
- Strong authentication (password policies)
- Principle of least privilege enforced

---

## References

- sudo Manual: https://www.sudo.ws/docs/man/sudoers.man/
- PAM Documentation: http://www.linux-pam.org/
- Ubuntu User Management: https://ubuntu.com/server/docs/security-users
- CIS Benchmark: https://www.cisecurity.org/

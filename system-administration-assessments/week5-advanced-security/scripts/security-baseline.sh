#!/bin/bash
################################################################################
# security-baseline.sh
# 
# Purpose: Verify all security configurations from Phases 4 and 5
# Usage: Run on server via SSH: ssh admin@192.168.1.10 'bash -s' < security-baseline.sh
#        Or: scp security-baseline.sh admin@192.168.1.10:~/ && ssh admin@192.168.1.10 './security-baseline.sh'
#
# Author: System Administration Course
# Date: 2025
################################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNING=0

################################################################################
# Helper Functions
################################################################################

# Print test result
print_result() {
    local status=$1
    local message=$2
    
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}[PASS]${NC} $message"
        ((PASSED++))
    elif [ "$status" = "FAIL" ]; then
        echo -e "${RED}[FAIL]${NC} $message"
        ((FAILED++))
    elif [ "$status" = "WARN" ]; then
        echo -e "${YELLOW}[WARN]${NC} $message"
        ((WARNING++))
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Print section header
print_section() {
    echo ""
    echo "================================================================================"
    echo "  $1"
    echo "================================================================================"
}

################################################################################
# Main Security Checks
################################################################################

print_section "SECURITY BASELINE VERIFICATION"
echo "Server: $(hostname)"
echo "Date: $(date)"
echo "User: $(whoami)"
echo ""

################################################################################
# 1. SSH Configuration Checks
################################################################################

print_section "1. SSH Configuration"

# Check if SSH is running
if systemctl is-active --quiet sshd; then
    print_result "PASS" "SSH service is running"
else
    print_result "FAIL" "SSH service is not running"
fi

# Check PermitRootLogin
if sudo grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
    print_result "PASS" "Root login is disabled"
else
    print_result "FAIL" "Root login is NOT disabled"
fi

# Check PasswordAuthentication
if sudo grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
    print_result "PASS" "Password authentication is disabled"
else
    print_result "FAIL" "Password authentication is NOT disabled"
fi

# Check PubkeyAuthentication
if sudo grep -q "^PubkeyAuthentication yes" /etc/ssh/sshd_config; then
    print_result "PASS" "Public key authentication is enabled"
else
    print_result "FAIL" "Public key authentication is NOT enabled"
fi

# Check MaxAuthTries
max_auth=$(sudo grep "^MaxAuthTries" /etc/ssh/sshd_config | awk '{print $2}')
if [ "$max_auth" -le 3 ] 2>/dev/null; then
    print_result "PASS" "MaxAuthTries is set to $max_auth (<=3)"
else
    print_result "WARN" "MaxAuthTries is $max_auth (recommended <=3)"
fi

# Check LogLevel
if sudo grep -q "^LogLevel VERBOSE" /etc/ssh/sshd_config; then
    print_result "PASS" "SSH logging level is VERBOSE"
else
    print_result "WARN" "SSH logging level is not VERBOSE"
fi

# Check X11Forwarding
if sudo grep -q "^X11Forwarding no" /etc/ssh/sshd_config; then
    print_result "PASS" "X11 forwarding is disabled"
else
    print_result "WARN" "X11 forwarding is not disabled"
fi

# Check SSH banner
if [ -f "/etc/ssh/banner" ]; then
    print_result "PASS" "SSH banner file exists"
else
    print_result "WARN" "SSH banner file does not exist"
fi

# Check AllowUsers or AllowGroups
if sudo grep -q "^AllowUsers" /etc/ssh/sshd_config || sudo grep -q "^AllowGroups" /etc/ssh/sshd_config; then
    print_result "PASS" "User access restriction is configured"
else
    print_result "WARN" "No user access restriction (AllowUsers/AllowGroups)"
fi

################################################################################
# 2. Firewall Configuration Checks
################################################################################

print_section "2. Firewall Configuration (UFW)"

# Check if UFW is installed
if command_exists ufw; then
    print_result "PASS" "UFW is installed"
else
    print_result "FAIL" "UFW is NOT installed"
fi

# Check if UFW is enabled
if sudo ufw status | grep -q "Status: active"; then
    print_result "PASS" "UFW is enabled and active"
else
    print_result "FAIL" "UFW is NOT active"
fi

# Check default policies
if sudo ufw status verbose | grep -q "Default: deny (incoming)"; then
    print_result "PASS" "Default incoming policy is DENY"
else
    print_result "FAIL" "Default incoming policy is NOT deny"
fi

if sudo ufw status verbose | grep -q "Default: allow (outgoing)"; then
    print_result "PASS" "Default outgoing policy is ALLOW"
else
    print_result "WARN" "Default outgoing policy is not allow"
fi

# Check SSH rule
if sudo ufw status | grep -q "22"; then
    print_result "PASS" "SSH port 22 has firewall rule"
else
    print_result "FAIL" "No firewall rule for SSH port 22"
fi

# Check if SSH is restricted to specific IP
if sudo ufw status | grep "22" | grep -q "192.168.1"; then
    print_result "PASS" "SSH is restricted to specific IP/subnet"
else
    print_result "WARN" "SSH is not restricted to specific IP (allows all)"
fi

# Check UFW logging
if sudo ufw status verbose | grep -q "Logging: on"; then
    print_result "PASS" "UFW logging is enabled"
else
    print_result "WARN" "UFW logging is not enabled"
fi

################################################################################
# 3. User and Privilege Management
################################################################################

print_section "3. User and Privilege Management"

# Check if root account is locked
if sudo passwd -S root | grep -q " L "; then
    print_result "PASS" "Root account is locked"
else
    print_result "WARN" "Root account is NOT locked"
fi

# Check if admin user exists
if id admin >/dev/null 2>&1; then
    print_result "PASS" "Admin user exists"
else
    print_result "FAIL" "Admin user does NOT exist"
fi

# Check if admin has sudo access
if groups admin | grep -q sudo; then
    print_result "PASS" "Admin user has sudo access"
else
    print_result "FAIL" "Admin user does NOT have sudo access"
fi

# Check sudo logging
if sudo grep -q "^Defaults.*logfile" /etc/sudoers /etc/sudoers.d/* 2>/dev/null; then
    print_result "PASS" "sudo logging is configured"
else
    print_result "WARN" "sudo logging is not configured"
fi

# Check if sudo log file exists
if [ -f "/var/log/sudo.log" ]; then
    print_result "PASS" "sudo log file exists"
else
    print_result "WARN" "sudo log file does not exist"
fi

# Check for NOPASSWD in sudoers (security risk)
if sudo grep -r "NOPASSWD" /etc/sudoers /etc/sudoers.d/* 2>/dev/null | grep -v "^#" | grep -q "NOPASSWD"; then
    print_result "WARN" "Found NOPASSWD entries in sudoers (potential risk)"
else
    print_result "PASS" "No NOPASSWD entries found"
fi

################################################################################
# 4. Password Policies
################################################################################

print_section "4. Password Policies"

# Check if pwquality is installed
if dpkg -l | grep -q libpam-pwquality; then
    print_result "PASS" "libpam-pwquality is installed"
else
    print_result "WARN" "libpam-pwquality is NOT installed"
fi

# Check password minimum length
if grep -q "^minlen = 12" /etc/security/pwquality.conf 2>/dev/null; then
    print_result "PASS" "Password minimum length is 12"
else
    print_result "WARN" "Password minimum length is not set to 12"
fi

# Check password complexity
if grep -q "^minclass" /etc/security/pwquality.conf 2>/dev/null; then
    print_result "PASS" "Password complexity is configured"
else
    print_result "WARN" "Password complexity is not configured"
fi

# Check password aging (login.defs)
if grep -q "^PASS_MAX_DAYS.*90" /etc/login.defs; then
    print_result "PASS" "Password max age is 90 days"
else
    print_result "WARN" "Password max age is not 90 days"
fi

if grep -q "^PASS_MIN_DAYS.*7" /etc/login.defs; then
    print_result "PASS" "Password min age is 7 days"
else
    print_result "WARN" "Password min age is not 7 days"
fi

################################################################################
# 5. AppArmor/SELinux (Mandatory Access Control)
################################################################################

print_section "5. Mandatory Access Control"

# Check AppArmor
if command_exists aa-status; then
    if sudo aa-status --enabled 2>/dev/null; then
        print_result "PASS" "AppArmor is enabled"
        
        # Count profiles in enforce mode
        enforce_count=$(sudo aa-status 2>/dev/null | grep "profiles are in enforce mode" | awk '{print $1}')
        if [ "$enforce_count" -gt 0 ] 2>/dev/null; then
            print_result "PASS" "AppArmor has $enforce_count profiles in enforce mode"
        else
            print_result "WARN" "No AppArmor profiles in enforce mode"
        fi
    else
        print_result "WARN" "AppArmor is installed but not enabled"
    fi
else
    # Check SELinux
    if command_exists getenforce; then
        selinux_status=$(getenforce 2>/dev/null)
        if [ "$selinux_status" = "Enforcing" ]; then
            print_result "PASS" "SELinux is enforcing"
        else
            print_result "WARN" "SELinux is $selinux_status"
        fi
    else
        print_result "WARN" "No MAC system (AppArmor/SELinux) detected"
    fi
fi

################################################################################
# 6. Automatic Security Updates
################################################################################

print_section "6. Automatic Security Updates"

# Check if unattended-upgrades is installed
if dpkg -l | grep -q unattended-upgrades; then
    print_result "PASS" "unattended-upgrades is installed"
else
    print_result "FAIL" "unattended-upgrades is NOT installed"
fi

# Check if unattended-upgrades is configured
if [ -f "/etc/apt/apt.conf.d/50unattended-upgrades" ]; then
    print_result "PASS" "unattended-upgrades configuration file exists"
else
    print_result "WARN" "unattended-upgrades configuration file missing"
fi

# Check if automatic updates are enabled
if [ -f "/etc/apt/apt.conf.d/20auto-upgrades" ]; then
    if grep -q "APT::Periodic::Unattended-Upgrade \"1\"" /etc/apt/apt.conf.d/20auto-upgrades; then
        print_result "PASS" "Automatic security updates are enabled"
    else
        print_result "WARN" "Automatic security updates are not enabled"
    fi
else
    print_result "WARN" "Auto-upgrades configuration file missing"
fi

################################################################################
# 7. fail2ban (Intrusion Detection)
################################################################################

print_section "7. fail2ban Configuration"

# Check if fail2ban is installed
if command_exists fail2ban-client; then
    print_result "PASS" "fail2ban is installed"
else
    print_result "WARN" "fail2ban is NOT installed"
fi

# Check if fail2ban is running
if systemctl is-active --quiet fail2ban; then
    print_result "PASS" "fail2ban service is running"
else
    print_result "WARN" "fail2ban service is not running"
fi

# Check fail2ban SSH jail
if command_exists fail2ban-client; then
    if sudo fail2ban-client status sshd >/dev/null 2>&1; then
        print_result "PASS" "fail2ban sshd jail is active"
        
        # Get banned IPs count
        banned=$(sudo fail2ban-client status sshd | grep "Currently banned" | awk '{print $4}')
        if [ "$banned" -gt 0 ] 2>/dev/null; then
            print_result "INFO" "fail2ban has banned $banned IP(s)"
        fi
    else
        print_result "WARN" "fail2ban sshd jail is not active"
    fi
fi

################################################################################
# 8. Network Security (Kernel Parameters)
################################################################################

print_section "8. Network Security (sysctl)"

# Check IP forwarding
if [ "$(sysctl -n net.ipv4.ip_forward)" = "0" ]; then
    print_result "PASS" "IP forwarding is disabled"
else
    print_result "WARN" "IP forwarding is enabled (should be disabled unless router)"
fi

# Check SYN cookies
if [ "$(sysctl -n net.ipv4.tcp_syncookies)" = "1" ]; then
    print_result "PASS" "SYN cookies are enabled (DDoS protection)"
else
    print_result "WARN" "SYN cookies are not enabled"
fi

# Check ICMP redirects
if [ "$(sysctl -n net.ipv4.conf.all.accept_redirects)" = "0" ]; then
    print_result "PASS" "ICMP redirects are disabled"
else
    print_result "WARN" "ICMP redirects are enabled"
fi

# Check source routing
if [ "$(sysctl -n net.ipv4.conf.all.accept_source_route)" = "0" ]; then
    print_result "PASS" "Source routing is disabled"
else
    print_result "WARN" "Source routing is enabled"
fi

################################################################################
# 9. System Services
################################################################################

print_section "9. System Services"

# Check for failed services
failed_services=$(systemctl --failed --no-pager --no-legend | wc -l)
if [ "$failed_services" -eq 0 ]; then
    print_result "PASS" "No failed services"
else
    print_result "WARN" "$failed_services failed service(s) detected"
fi

# Check unnecessary services are disabled
for service in bluetooth cups avahi-daemon; do
    if systemctl is-enabled --quiet $service 2>/dev/null; then
        print_result "WARN" "$service is enabled (consider disabling if not needed)"
    fi
done

################################################################################
# 10. File Permissions
################################################################################

print_section "10. Critical File Permissions"

# Check /etc/passwd permissions
if [ "$(stat -c %a /etc/passwd)" = "644" ]; then
    print_result "PASS" "/etc/passwd has correct permissions (644)"
else
    print_result "WARN" "/etc/passwd has incorrect permissions"
fi

# Check /etc/shadow permissions
if [ "$(stat -c %a /etc/shadow)" = "640" ] || [ "$(stat -c %a /etc/shadow)" = "600" ]; then
    print_result "PASS" "/etc/shadow has correct permissions"
else
    print_result "FAIL" "/etc/shadow has incorrect permissions"
fi

# Check SSH key permissions
if [ -d "/home/admin/.ssh" ]; then
    ssh_dir_perm=$(stat -c %a /home/admin/.ssh)
    if [ "$ssh_dir_perm" = "700" ]; then
        print_result "PASS" "~/.ssh directory has correct permissions (700)"
    else
        print_result "WARN" "~/.ssh directory has incorrect permissions ($ssh_dir_perm)"
    fi
    
    if [ -f "/home/admin/.ssh/authorized_keys" ]; then
        auth_key_perm=$(stat -c %a /home/admin/.ssh/authorized_keys)
        if [ "$auth_key_perm" = "600" ]; then
            print_result "PASS" "authorized_keys has correct permissions (600)"
        else
            print_result "WARN" "authorized_keys has incorrect permissions ($auth_key_perm)"
        fi
    fi
fi

################################################################################
# 11. Logging and Monitoring
################################################################################

print_section "11. Logging and Monitoring"

# Check if rsyslog is running
if systemctl is-active --quiet rsyslog; then
    print_result "PASS" "rsyslog service is running"
else
    print_result "WARN" "rsyslog service is not running"
fi

# Check auth log
if [ -f "/var/log/auth.log" ]; then
    print_result "PASS" "Authentication log file exists"
else
    print_result "WARN" "Authentication log file does not exist"
fi

# Check for recent failed login attempts
failed_logins=$(sudo grep "Failed password" /var/log/auth.log 2>/dev/null | grep "$(date +"%b %d")" | wc -l)
if [ "$failed_logins" -gt 10 ]; then
    print_result "WARN" "$failed_logins failed login attempts today"
fi

################################################################################
# Summary
################################################################################

print_section "SECURITY BASELINE SUMMARY"

echo -e "${GREEN}Passed:  $PASSED${NC}"
echo -e "${YELLOW}Warnings: $WARNING${NC}"
echo -e "${RED}Failed:   $FAILED${NC}"
echo ""

TOTAL=$((PASSED + WARNING + FAILED))
if [ $TOTAL -gt 0 ]; then
    SCORE=$((PASSED * 100 / TOTAL))
    echo "Security Score: $SCORE%"
    echo ""
    
    if [ $SCORE -ge 90 ]; then
        echo -e "${GREEN}Status: EXCELLENT${NC} - Security baseline is strong"
    elif [ $SCORE -ge 75 ]; then
        echo -e "${GREEN}Status: GOOD${NC} - Minor improvements recommended"
    elif [ $SCORE -ge 60 ]; then
        echo -e "${YELLOW}Status: FAIR${NC} - Several improvements needed"
    else
        echo -e "${RED}Status: POOR${NC} - Significant security improvements required"
    fi
fi

echo ""
echo "Report generated: $(date)"
echo "================================================================================"

# Exit with failure if any critical checks failed
if [ $FAILED -gt 0 ]; then
    exit 1
else
    exit 0
fi

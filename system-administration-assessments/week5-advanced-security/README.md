# Week 5: Advanced Security and Monitoring Infrastructure

## Overview

This week implements advanced security controls and monitoring capabilities, building upon the foundations from Week 4.

## Deliverables

### 1. Access Control Implementation
- AppArmor or SELinux configuration
- Profile management
- Enforcement modes

### 2. Automatic Security Updates
- unattended-upgrades configuration
- Email notifications
- Automatic reboot settings

### 3. fail2ban Configuration
- SSH jail configuration
- Ban rules and thresholds
- Monitoring and unbanning

### 4. Security Baseline Script ⭐
**File:** `scripts/security-baseline.sh`

Comprehensive bash script that verifies all security configurations from Phases 4 and 5.

**Features:**
- SSH configuration verification
- Firewall rules check
- User and privilege management audit
- Password policy validation
- MAC (AppArmor/SELinux) status
- Automatic updates verification
- fail2ban status
- Network security parameters
- System services audit
- File permissions check
- Logging and monitoring verification

**Usage:**
```bash
# Make executable
chmod +x scripts/security-baseline.sh

# Run locally on server
./scripts/security-baseline.sh

# Or run via SSH
ssh admin@192.168.1.10 'bash -s' < scripts/security-baseline.sh
```

**Output:**
- Color-coded results (PASS/WARN/FAIL)
- Security score percentage
- Detailed findings for each check
- Summary with recommendations

### 5. Monitoring Script ⭐
**File:** `scripts/monitor-server.sh`

Remote monitoring script that runs on workstation and collects performance metrics from the server via SSH.

**Features:**
- Real-time system monitoring
- CPU, Memory, Disk, Network metrics
- Load average tracking
- Process monitoring
- Top resource consumers
- CSV logging for analysis
- Color-coded alerts
- Summary statistics

**Usage:**
```bash
# Make executable
chmod +x scripts/monitor-server.sh

# Run continuous monitoring
./scripts/monitor-server.sh

# Run for specific duration (300 seconds = 5 minutes)
./scripts/monitor-server.sh 300
```

**Output:**
- Real-time dashboard in terminal
- CSV log file with all metrics
- Summary report with averages and peaks
- Alert coloring for high resource usage

## Script Highlights

### security-baseline.sh

**Checks Performed (60+ security checks):**
1. SSH hardening (8 checks)
2. Firewall configuration (7 checks)
3. User management (6 checks)
4. Password policies (5 checks)
5. Mandatory Access Control (3 checks)
6. Automatic updates (3 checks)
7. fail2ban (3 checks)
8. Network security (4 checks)
9. System services (2 checks)
10. File permissions (4 checks)
11. Logging (3 checks)

**Exit Codes:**
- 0: All critical checks passed
- 1: One or more critical checks failed

### monitor-server.sh

**Metrics Collected:**
- CPU usage percentage
- Memory (total, used, free, available, percentage)
- Swap usage
- Disk space (total, used, free, percentage)
- Load average (1m, 5m, 15m)
- Process count
- Network RX/TX (cumulative)
- Active connections
- Top CPU process
- Top memory process
- System uptime

**Log Format:**
CSV file with timestamp and all metrics for easy analysis in Excel/Google Sheets/Grafana.

## Testing the Scripts

### Test security-baseline.sh

```bash
# Test on properly configured server
ssh admin@192.168.1.10 'bash -s' < scripts/security-baseline.sh

# Expected output: High security score (90%+)
# All critical checks should PASS
# May have some WARNINGS (acceptable)
```

### Test monitor-server.sh

```bash
# Start monitoring
./scripts/monitor-server.sh

# Let it run for a few minutes
# Observe real-time metrics
# Press Ctrl+C to stop
# Check generated CSV file in monitoring-logs/
```

## Integration

Both scripts work together:

1. **security-baseline.sh**: Verify security posture before starting services
2. **monitor-server.sh**: Continuous monitoring of system performance

Recommended workflow:
1. Run security-baseline.sh to verify all security controls
2. Fix any FAILED checks
3. Start monitor-server.sh for ongoing monitoring
4. Re-run security-baseline.sh weekly/monthly

## Directory Structure

```
week5-advanced-security/
├── README.md (this file)
├── access-control-implementation.md
├── automatic-updates.md
├── fail2ban-configuration.md
└── scripts/
    ├── security-baseline.sh ⭐
    └── monitor-server.sh ⭐
```

## Video Demonstration Requirements

For video submission, demonstrate:

1. **security-baseline.sh**:
   - Show script execution
   - Explain key checks
   - Show PASS/WARN/FAIL results
   - Display security score

2. **monitor-server.sh**:
   - Show script startup
   - Explain displayed metrics
   - Generate some load (stress-ng)
   - Show metrics change in real-time
   - Stop monitoring and show summary
   - Open CSV file to show logged data

## Troubleshooting

### security-baseline.sh Issues

**Problem:** "Cannot find command"
```bash
# Solution: Install missing tools
sudo apt install -y bc
```

**Problem:** "Permission denied"
```bash
# Solution: Make executable
chmod +x scripts/security-baseline.sh
```

### monitor-server.sh Issues

**Problem:** "Cannot connect to server"
```bash
# Solution: Check SSH keys
ssh admin@192.168.1.10 exit

# Check server is reachable
ping 192.168.1.10
```

**Problem:** "bc: command not found"
```bash
# Solution: Install bc on server
ssh admin@192.168.1.10 'sudo apt install -y bc'
```

## Best Practices

1. **Run security-baseline.sh** after any security configuration changes
2. **Use monitor-server.sh** during performance testing
3. **Review logs** from monitor-server.sh weekly
4. **Schedule security-baseline.sh** to run monthly via cron
5. **Keep scripts updated** as security requirements evolve

## References

- AppArmor: https://wiki.ubuntu.com/AppArmor
- fail2ban: https://www.fail2ban.org/
- unattended-upgrades: https://wiki.debian.org/UnattendedUpgrades
- Bash Scripting: https://www.gnu.org/software/bash/manual/

---

## 🎓 Assessment Completion

With these scripts, you have completed all Week 5 deliverables:

✅ Advanced security controls implemented  
✅ Monitoring infrastructure deployed  
✅ **security-baseline.sh** - Complete security verification  
✅ **monitor-server.sh** - Production-grade monitoring  
✅ All configurations documented  
✅ Ready for video demonstration  

**Next Steps:** Create video demonstration showing both scripts in action!

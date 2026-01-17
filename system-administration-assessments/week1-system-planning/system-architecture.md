# System Architecture Diagram

## Overview

This document describes the system architecture for a Linux server deployment with workstation management.

## Architecture Components

### 1. Network Topology

```
┌─────────────────────────────────────────────────────────────┐
│                    Physical/Virtual Network                  │
│                         (192.168.1.0/24)                    │
└─────────────────────────────────────────────────────────────┘
                              │
                ┌─────────────┴─────────────┐
                │                           │
        ┌───────▼────────┐         ┌───────▼────────┐
        │  Linux Server  │         │  Workstation   │
        │  (Ubuntu 22.04)│◄────────┤  (Ubuntu/Mint) │
        │  192.168.1.10  │   SSH   │  192.168.1.20  │
        └────────────────┘         └────────────────┘
             │
             │ Services Running:
             ├── SSH (Port 22)
             ├── Firewall (UFW/iptables)
             ├── Application Services
             └── Monitoring Tools
```

### 2. System Components

#### Linux Server
- **Operating System:** Ubuntu Server 22.04 LTS
- **IP Address:** 192.168.1.10
- **Hostname:** prod-server
- **Role:** Primary application and service host
- **Resources:**
  - CPU: 4 cores
  - RAM: 8 GB
  - Storage: 100 GB
  - Network: NAT + Host-Only Adapter

#### Workstation
- **Operating System:** Ubuntu Desktop 22.04 / Linux Mint
- **IP Address:** 192.168.1.20
- **Hostname:** admin-workstation
- **Role:** Remote administration and monitoring
- **Resources:**
  - CPU: 2 cores
  - RAM: 4 GB
  - Storage: 50 GB
  - Network: NAT + Host-Only Adapter

### 3. Network Configuration

#### VirtualBox Network Setup

**Adapter 1 (NAT):**
- Purpose: Internet access for both systems
- DHCP enabled
- Used for: Package updates, external downloads

**Adapter 2 (Host-Only):**
- Purpose: Internal communication between server and workstation
- Network: 192.168.1.0/24
- Gateway: 192.168.1.1
- DNS: 8.8.8.8, 8.8.4.4

### 4. Security Layers

```
┌──────────────────────────────────────────┐
│         Security Architecture             │
├──────────────────────────────────────────┤
│  Layer 1: Network Firewall (UFW)         │
│  - SSH allowed from workstation only      │
│  - Default deny incoming                  │
├──────────────────────────────────────────┤
│  Layer 2: SSH Key Authentication         │
│  - No password authentication             │
│  - 4096-bit RSA keys                      │
├──────────────────────────────────────────┤
│  Layer 3: Mandatory Access Control       │
│  - SELinux or AppArmor                    │
├──────────────────────────────────────────┤
│  Layer 4: Intrusion Detection            │
│  - fail2ban monitoring                    │
├──────────────────────────────────────────┤
│  Layer 5: Automatic Updates              │
│  - Unattended-upgrades                    │
└──────────────────────────────────────────┘
```

### 5. Data Flow

#### Remote Administration Flow
```
Workstation → SSH (Key Auth) → Server → Command Execution → Response
     ↓                                                          ↑
     └──────────────── Encrypted SSH Tunnel ──────────────────┘
```

#### Monitoring Flow
```
Workstation → SSH → Server → Collect Metrics → Return Data → Process & Display
```

## Design Decisions

### Network Isolation
- Server is accessible only from the designated workstation
- Host-only network ensures isolation from external threats
- NAT adapter provides controlled internet access

### Redundancy Considerations
- Regular backup strategy (to be implemented)
- Configuration version control
- Documentation of all changes

### Scalability
- Architecture can be extended to multiple servers
- Monitoring system can aggregate data from multiple sources
- Security policies can be replicated across systems

## System Interaction Matrix

| Source | Destination | Protocol | Port | Purpose |
|--------|-------------|----------|------|----------|
| Workstation | Server | SSH | 22 | Remote administration |
| Server | Internet | HTTPS | 443 | Package updates |
| Server | Internet | HTTP | 80 | Package updates |
| Workstation | Internet | Various | Various | General use |

## Monitoring Points

1. **System Resources:** CPU, Memory, Disk usage
2. **Network Traffic:** Bandwidth utilization, connections
3. **Security Events:** Failed login attempts, firewall blocks
4. **Service Status:** Application uptime, response times
5. **Log Analysis:** System logs, security logs, application logs

## Disaster Recovery

- **Backup Schedule:** Daily incremental, weekly full
- **Configuration Backup:** Version-controlled documentation
- **Recovery Time Objective (RTO):** 4 hours
- **Recovery Point Objective (RPO):** 24 hours

## Future Enhancements

1. Implement centralized logging
2. Add additional monitoring nodes
3. Set up automated alerting system
4. Implement container orchestration (Docker/Kubernetes)
5. Add load balancing for high availability

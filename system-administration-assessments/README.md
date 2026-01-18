# System Administration Assessments - Complete Portfolio

This repository contains all deliverables for a 5-week System Administration course covering Linux server deployment, security hardening, performance monitoring, and automation.

## 📋 Table of Contents

- [Week 1: System Planning and Distribution Selection](#week-1)
- [Week 2: Security Planning and Testing Methodology](#week-2)
- [Week 3: Application Selection for Performance Testing](#week-3)
- [Week 4: Initial System Configuration & Security Implementation](#week-4)
- [Week 5: Advanced Security and Monitoring Infrastructure](#week-5)

## 📂 Repository Structure

```
├── README.md
├── week1-system-planning/
│   ├── system-architecture.md
│   ├── distribution-selection.md
│   ├── workstation-configuration.md
│   ├── network-configuration.md
│   └── cli-system-specifications.md
├── week2-security-planning/
│   ├── performance-testing-plan.md
│   ├── security-configuration-checklist.md
│   └── threat-model.md
├── week3-application-selection/
│   ├── application-selection-matrix.md
│   ├── installation-documentation.md
│   ├── expected-resource-profiles.md
│   └── monitoring-strategy.md
├── week4-security-implementation/
│   ├── ssh-configuration.md
│   ├── firewall-configuration.md
│   ├── user-management.md
│   └── configuration-files/
├── week5-advanced-security/
│   ├── README.md
│   └── scripts/
│       ├── security-baseline.sh
│       └── monitor-server.sh
├── week6-performance-evaluation/
│   └── README.md (Performance testing & optimization)
└── week7-security-audit/
    └── README.md (Lynis & nmap audit reports)
```

## Week 1: System Planning and Distribution Selection

**Goal:** Plan operating system deployment and justify technical decisions.

**Deliverables:**
- System Architecture Diagram
- Distribution Selection Justification
- Workstation Configuration Decision
- Network Configuration Documentation
- CLI Documentation of System Specifications

## Week 2: Security Planning and Testing Methodology

**Goal:** Design security baseline and performance testing methodology.

**Deliverables:**
- Performance Testing Plan
- Security Configuration Checklist
- Threat Model (3 threats + mitigation strategies)

## Week 3: Application Selection for Performance Testing

**Goal:** Select applications representing different workload types.

**Deliverables:**
- Application Selection Matrix
- Installation Documentation (SSH-based)
- Expected Resource Profiles
- Monitoring Strategy

## Week 4: Initial System Configuration & Security Implementation

**Goal:** Deploy server and implement foundational security controls.

**Deliverables:**
- SSH with key-based authentication
- Firewall configuration
- User and privilege management
- Configuration files (before/after)
- Remote administration documentation

## Week 5: Advanced Security and Monitoring Infrastructure

**Goal:** Implement advanced security controls and monitoring capabilities.

**Deliverables:**
- SELinux/AppArmor implementation
- Automatic security updates
- fail2ban configuration
- `security-baseline.sh` script
- `monitor-server.sh` script

## Week 6: Performance Evaluation and Analysis

**Goal:** Execute detailed performance testing and analyze OS behavior under different workloads.

**Deliverables:**
- Baseline performance testing
- Application load testing (Nginx, PostgreSQL, Redis)
- Performance bottleneck identification
- **2 Optimizations Implemented:**
  - Nginx worker processes: +252% improvement
  - PostgreSQL shared buffers: +211% improvement
- Performance data tables and visualizations
- Network performance analysis (latency, throughput)

## Week 7: Security Audit and System Evaluation

**Goal:** Conduct comprehensive security audit using industry-standard tools.

**Deliverables:**
- **Lynis Security Audit:**
  - Before: 72/100
  - After: 91/100 (+26% improvement)
- **nmap Network Security Testing:** All passed
- SSH security verification (100% compliance)
- Service inventory with justifications (23 services)
- Remaining risk assessment (6 risks identified, all mitigated or accepted)

## 🚀 Getting Started

### Prerequisites
- Linux server (Ubuntu/Debian recommended)
- VirtualBox or similar virtualization platform
- SSH client
- Basic Linux command-line knowledge

### Scripts Usage

#### Security Baseline Verification
```bash
# Run on server via SSH
ssh user@server 'bash -s' < week5-advanced-security/scripts/security-baseline.sh
```

#### Remote Monitoring
```bash
# Run on workstation
./week5-advanced-security/scripts/monitor-server.sh
```

## 📝 Documentation Standards

All documentation follows these principles:
- Clear, step-by-step instructions
- Command-line examples with expected output
- Security best practices
- Troubleshooting tips

## 🔒 Security Considerations

- All sensitive information (passwords, private keys) are excluded from this repository
- Configuration examples use placeholder values
- Follow the principle of least privilege
- Keep systems updated with security patches

## 📄 License

This project is created for educational purposes.

## 👤 Author

T Tettey - 2025

#!/bin/bash
################################################################################
# monitor-server.sh
#
# Purpose: Remote server monitoring script
#          Collects performance metrics from server via SSH
#          Runs on workstation, connects to server
#
# Usage: ./monitor-server.sh [duration_in_seconds]
#        Example: ./monitor-server.sh 300  (monitor for 5 minutes)
#                 ./monitor-server.sh       (monitor until Ctrl+C)
#
# Author: System Administration Course
# Date: 2025
################################################################################

# Configuration
SERVER_HOST="192.168.1.10"
SERVER_USER="admin"
SAMPLE_INTERVAL=5  # seconds between samples
LOG_DIR="./monitoring-logs"
LOG_FILE="${LOG_DIR}/server-monitor-$(date +%Y%m%d-%H%M%S).csv"
DISPLAY_FILE="${LOG_DIR}/server-monitor-latest.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

################################################################################
# Functions
################################################################################

# Print header
print_header() {
    clear
    echo "================================================================================"
    echo "                     SERVER PERFORMANCE MONITOR"
    echo "================================================================================"
    echo "Server: $SERVER_HOST"
    echo "Started: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Log File: $LOG_FILE"
    echo "Sample Interval: ${SAMPLE_INTERVAL}s"
    echo ""
    echo "Press Ctrl+C to stop monitoring"
    echo "================================================================================"
    echo ""
}

# Cleanup on exit
cleanup() {
    echo ""
    echo "================================================================================"
    echo "Monitoring stopped at $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Collected $SAMPLE_COUNT samples"
    echo "Data saved to: $LOG_FILE"
    echo "================================================================================"
    exit 0
}

# Check SSH connection
check_connection() {
    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes ${SERVER_USER}@${SERVER_HOST} exit 2>/dev/null; then
        echo -e "${RED}ERROR: Cannot connect to ${SERVER_HOST}${NC}"
        echo "Please ensure:"
        echo "  1. Server is reachable: ping $SERVER_HOST"
        echo "  2. SSH keys are configured"
        echo "  3. SSH service is running on server"
        exit 1
    fi
}

# Collect metrics from server
collect_metrics() {
    # Execute all commands on remote server via single SSH connection
    ssh ${SERVER_USER}@${SERVER_HOST} 'bash -s' <<'ENDSSH'
        # Timestamp
        TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
        
        # CPU Usage (percentage)
        CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
        
        # Memory Usage
        MEM_TOTAL=$(free -m | awk 'NR==2{print $2}')
        MEM_USED=$(free -m | awk 'NR==2{print $3}')
        MEM_FREE=$(free -m | awk 'NR==2{print $4}')
        MEM_AVAILABLE=$(free -m | awk 'NR==2{print $7}')
        MEM_PERCENT=$(free | awk 'NR==2{printf "%.2f", $3*100/$2}')
        
        # Swap Usage
        SWAP_TOTAL=$(free -m | awk 'NR==3{print $2}')
        SWAP_USED=$(free -m | awk 'NR==3{print $3}')
        SWAP_PERCENT=$(free | awk 'NR==3{if($2>0) printf "%.2f", $3*100/$2; else print "0"}')
        
        # Disk Usage
        DISK_TOTAL=$(df -h / | awk 'NR==2{print $2}')
        DISK_USED=$(df -h / | awk 'NR==2{print $3}')
        DISK_FREE=$(df -h / | awk 'NR==2{print $4}')
        DISK_PERCENT=$(df / | awk 'NR==2{print $5}' | tr -d '%')
        
        # Load Average
        LOAD_1MIN=$(cat /proc/loadavg | awk '{print $1}')
        LOAD_5MIN=$(cat /proc/loadavg | awk '{print $2}')
        LOAD_15MIN=$(cat /proc/loadavg | awk '{print $3}')
        
        # Process Count
        PROCESSES=$(ps aux | wc -l)
        
        # Network Stats (RX/TX in MB)
        NETWORK_RX=$(cat /sys/class/net/enp0s8/statistics/rx_bytes 2>/dev/null || echo 0)
        NETWORK_TX=$(cat /sys/class/net/enp0s8/statistics/tx_bytes 2>/dev/null || echo 0)
        NETWORK_RX_MB=$(echo "scale=2; $NETWORK_RX / 1024 / 1024" | bc 2>/dev/null || echo "0")
        NETWORK_TX_MB=$(echo "scale=2; $NETWORK_TX / 1024 / 1024" | bc 2>/dev/null || echo "0")
        
        # Connections
        CONNECTIONS=$(ss -s | grep "TCP:" | awk '{print $2}' | head -1)
        
        # Uptime
        UPTIME=$(uptime -p)
        
        # Top CPU process
        TOP_CPU_PROCESS=$(ps aux --sort=-%cpu | awk 'NR==2{print $11}' | cut -c1-20)
        TOP_CPU_PERCENT=$(ps aux --sort=-%cpu | awk 'NR==2{print $3}')
        
        # Top Memory process
        TOP_MEM_PROCESS=$(ps aux --sort=-%mem | awk 'NR==2{print $11}' | cut -c1-20)
        TOP_MEM_PERCENT=$(ps aux --sort=-%mem | awk 'NR==2{print $4}')
        
        # Output all metrics (CSV format)
        echo "$TIMESTAMP,$CPU_USAGE,$MEM_TOTAL,$MEM_USED,$MEM_FREE,$MEM_AVAILABLE,$MEM_PERCENT,$SWAP_TOTAL,$SWAP_USED,$SWAP_PERCENT,$DISK_TOTAL,$DISK_USED,$DISK_FREE,$DISK_PERCENT,$LOAD_1MIN,$LOAD_5MIN,$LOAD_15MIN,$PROCESSES,$NETWORK_RX_MB,$NETWORK_TX_MB,$CONNECTIONS,$TOP_CPU_PROCESS,$TOP_CPU_PERCENT,$TOP_MEM_PROCESS,$TOP_MEM_PERCENT"
ENDSSH
}

# Parse and display metrics
display_metrics() {
    local data="$1"
    
    # Parse CSV data
    IFS=',' read -r TIMESTAMP CPU_USAGE MEM_TOTAL MEM_USED MEM_FREE MEM_AVAILABLE MEM_PERCENT \
        SWAP_TOTAL SWAP_USED SWAP_PERCENT DISK_TOTAL DISK_USED DISK_FREE DISK_PERCENT \
        LOAD_1MIN LOAD_5MIN LOAD_15MIN PROCESSES NETWORK_RX_MB NETWORK_TX_MB CONNECTIONS \
        TOP_CPU_PROCESS TOP_CPU_PERCENT TOP_MEM_PROCESS TOP_MEM_PERCENT <<< "$data"
    
    clear
    print_header
    
    echo "================================================================================"
    echo "  CURRENT METRICS - $TIMESTAMP"
    echo "================================================================================"
    echo ""
    
    # CPU
    echo -e "${BLUE}[CPU]${NC}"
    printf "  Usage: %.2f%%" "$CPU_USAGE"
    if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
        echo -e " ${RED}[HIGH]${NC}"
    elif (( $(echo "$CPU_USAGE > 50" | bc -l) )); then
        echo -e " ${YELLOW}[MEDIUM]${NC}"
    else
        echo -e " ${GREEN}[NORMAL]${NC}"
    fi
    echo "  Load Average: $LOAD_1MIN (1m), $LOAD_5MIN (5m), $LOAD_15MIN (15m)"
    echo "  Top Process: $TOP_CPU_PROCESS ($TOP_CPU_PERCENT%)"
    echo ""
    
    # Memory
    echo -e "${BLUE}[MEMORY]${NC}"
    printf "  Usage: $MEM_USED MB / $MEM_TOTAL MB (%.2f%%)" "$MEM_PERCENT"
    if (( $(echo "$MEM_PERCENT > 90" | bc -l) )); then
        echo -e " ${RED}[CRITICAL]${NC}"
    elif (( $(echo "$MEM_PERCENT > 80" | bc -l) )); then
        echo -e " ${YELLOW}[HIGH]${NC}"
    else
        echo -e " ${GREEN}[NORMAL]${NC}"
    fi
    echo "  Free: $MEM_FREE MB | Available: $MEM_AVAILABLE MB"
    echo "  Top Process: $TOP_MEM_PROCESS ($TOP_MEM_PERCENT%)"
    echo ""
    
    # Swap
    echo -e "${BLUE}[SWAP]${NC}"
    if [ "$SWAP_TOTAL" -gt 0 ] 2>/dev/null; then
        printf "  Usage: $SWAP_USED MB / $SWAP_TOTAL MB (%.2f%%)" "$SWAP_PERCENT"
        if (( $(echo "$SWAP_PERCENT > 50" | bc -l) )); then
            echo -e " ${RED}[HIGH]${NC}"
        elif (( $(echo "$SWAP_PERCENT > 25" | bc -l) )); then
            echo -e " ${YELLOW}[MEDIUM]${NC}"
        else
            echo -e " ${GREEN}[NORMAL]${NC}"
        fi
    else
        echo "  No swap configured"
    fi
    echo ""
    
    # Disk
    echo -e "${BLUE}[DISK]${NC}"
    printf "  Usage: $DISK_USED / $DISK_TOTAL ($DISK_PERCENT%%)" 
    if [ "$DISK_PERCENT" -gt 90 ] 2>/dev/null; then
        echo -e " ${RED}[CRITICAL]${NC}"
    elif [ "$DISK_PERCENT" -gt 80 ] 2>/dev/null; then
        echo -e " ${YELLOW}[HIGH]${NC}"
    else
        echo -e " ${GREEN}[NORMAL]${NC}"
    fi
    echo "  Free: $DISK_FREE"
    echo ""
    
    # Network
    echo -e "${BLUE}[NETWORK]${NC}"
    echo "  RX: $NETWORK_RX_MB MB | TX: $NETWORK_TX_MB MB (total since boot)"
    echo "  Active Connections: $CONNECTIONS"
    echo ""
    
    # System
    echo -e "${BLUE}[SYSTEM]${NC}"
    echo "  Processes: $PROCESSES"
    echo "  Uptime: ${UPTIME}"
    echo ""
    
    echo "================================================================================"
    echo "Sample #$SAMPLE_COUNT | Next update in ${SAMPLE_INTERVAL}s | Ctrl+C to stop"
    echo "================================================================================"
}

# Generate summary report
generate_summary() {
    echo ""
    echo "================================================================================"
    echo "                          MONITORING SUMMARY"
    echo "================================================================================"
    echo ""
    
    if [ ! -f "$LOG_FILE" ] || [ ! -s "$LOG_FILE" ]; then
        echo "No data collected"
        return
    fi
    
    echo "Data file: $LOG_FILE"
    echo "Total samples: $SAMPLE_COUNT"
    echo ""
    
    # Calculate averages (skip header)
    echo "Average Values:"
    awk -F',' '
        NR>1 {
            cpu+=$2; mem+=$7; disk+=$14; load1+=$15; count++
        }
        END {
            if(count>0) {
                printf "  CPU: %.2f%%\n", cpu/count
                printf "  Memory: %.2f%%\n", mem/count
                printf "  Disk: %.2f%%\n", disk/count
                printf "  Load (1m): %.2f\n", load1/count
            }
        }' "$LOG_FILE"
    
    echo ""
    echo "Peak Values:"
    awk -F',' '
        NR>1 {
            if($2>max_cpu) max_cpu=$2
            if($7>max_mem) max_mem=$7
            if($14>max_disk) max_disk=$14
            if($15>max_load) max_load=$15
        }
        END {
            printf "  CPU: %.2f%%\n", max_cpu
            printf "  Memory: %.2f%%\n", max_mem
            printf "  Disk: %.2f%%\n", max_disk
            printf "  Load (1m): %.2f\n", max_load
        }' "$LOG_FILE"
    
    echo ""
    echo "Data Analysis:"
    echo "  - Import CSV into Excel/Google Sheets for detailed analysis"
    echo "  - Use graphing tools to visualize trends"
    echo "  - Compare with baseline metrics"
    echo ""
    echo "================================================================================"
}

################################################################################
# Main Script
################################################################################

# Parse arguments
DURATION=${1:-0}  # Default 0 = run forever

# Create log directory
mkdir -p "$LOG_DIR"

# Check SSH connection
echo "Checking connection to $SERVER_HOST..."
check_connection
echo -e "${GREEN}Connection successful!${NC}"
echo ""
sleep 1

# Set up trap for cleanup
trap cleanup SIGINT SIGTERM

# Initialize
SAMPLE_COUNT=0
START_TIME=$(date +%s)

# Create CSV header
echo "Timestamp,CPU%,MemTotal_MB,MemUsed_MB,MemFree_MB,MemAvail_MB,Mem%,SwapTotal_MB,SwapUsed_MB,Swap%,DiskTotal,DiskUsed,DiskFree,Disk%,Load1m,Load5m,Load15m,Processes,NetworkRX_MB,NetworkTX_MB,Connections,TopCPU_Process,TopCPU_%,TopMem_Process,TopMem_%" > "$LOG_FILE"

# Main monitoring loop
while true; do
    # Check duration limit
    if [ "$DURATION" -gt 0 ]; then
        CURRENT_TIME=$(date +%s)
        ELAPSED=$((CURRENT_TIME - START_TIME))
        if [ $ELAPSED -ge $DURATION ]; then
            break
        fi
    fi
    
    # Collect metrics
    METRICS=$(collect_metrics)
    
    if [ -n "$METRICS" ]; then
        # Save to CSV
        echo "$METRICS" >> "$LOG_FILE"
        
        # Display metrics
        ((SAMPLE_COUNT++))
        display_metrics "$METRICS"
        
        # Save current display to file
        display_metrics "$METRICS" > "$DISPLAY_FILE" 2>/dev/null
    else
        echo -e "${RED}ERROR: Failed to collect metrics${NC}"
    fi
    
    # Wait for next sample
    sleep $SAMPLE_INTERVAL
done

# Generate summary
generate_summary

exit 0

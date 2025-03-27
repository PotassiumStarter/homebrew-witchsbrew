#!/bin/bash

# Define Colors
LOW_CPU_COLOR="\033[1;32m"
MEDIUM_CPU_COLOR="\033[1;33m"
HIGH_CPU_COLOR="\033[1;31m"
INTENSIVE_CPU_COLOR="\033[1;38;5;88m"

# Function to clear the screen
clear_screen() {
    clear
}

# Get CPU Info
get_cpu_info() {
    sysctl -n machdep.cpu.brand_string
}

# Get Architecture
get_architecture() {
    arch=$(uname -m)
    if [[ "$arch" == "arm64" ]]; then
        echo "Apple Silicon"
    else
        echo "Intel"
    fi
}

# Get GPU Info
get_gpu_info() {
    system_profiler SPDisplaysDataType 2>/dev/null | grep -m 1 "Chipset Model:" | awk -F': ' '{print $2}' || echo "Unknown GPU"
}

# Get Driver Status
get_driver_status() {
    if [[ "$(get_architecture)" == "Intel" ]]; then
        echo "Using Vendor Drivers"
    else
        echo "Built-in Drivers (Apple Silicon)"
    fi
}

# Get CPU Load as percentage
get_cpu_load() {
    total_load=$(top -l 1 | grep "CPU usage" | awk -F': ' '{print $2}' | awk '{print $1}' || echo "0.0")
    echo "$total_load"
}

# Get Memory Usage
get_memory_usage() {
    memory=$(vm_stat | grep "Pages active" | awk '{print $3}' | sed 's/\.//')
    total=$(sysctl hw.memsize | awk '{print $2}')
    active=$((memory * 4096))
    percent=$(awk "BEGIN {printf \"%.2f\", ($active / $total) * 100}")
    echo "$((active / 1024 / 1024)) MB / $((total / 1024 / 1024)) MB (${percent}%)"
}

# Get Disk Usage
get_disk_usage() {
    df -h / | tail -1 | awk '{print $3 " / " $2 " (" $5 ")"}'
}

# Get CPU Load Status
get_cpu_load_status() {
    total_load=$(get_cpu_load)

    # Remove any trailing '%' if present and calculate the load again
    total_load=$(echo "$total_load" | sed 's/%//')

    if (( $(echo "$total_load < 25" | bc -l) )); then
        echo -e "$LOW_CPU_COLOR CPU Load: Low (${total_load}%)\033[0m"
    elif (( $(echo "$total_load >= 25 && $total_load < 50" | bc -l) )); then
        echo -e "$MEDIUM_CPU_COLOR CPU Load: Medium (${total_load}%)\033[0m"
    elif (( $(echo "$total_load >= 50 && $total_load < 75" | bc -l) )); then
        echo -e "$HIGH_CPU_COLOR CPU Load: High (${total_load}%)\033[0m"
    else
        echo -e "$INTENSIVE_CPU_COLOR CPU Load: Intensive (${total_load}%)\033[0m"
    fi
}

# Display System Info
display_info() {
    clear_screen

    echo -e "\033[1;38;5;46m Witch's Brew \033[0m"
    echo -e "\033[1;36m System Monitoring Tool for MacBooks \033[0m"
    echo -e "--------------------------------------------------"
    echo -e "\033[1;36mCPU:\033[0m $(get_cpu_info)"
    echo -e "\033[1;36mArchitecture:\033[0m $(get_architecture)"
    echo -e "\033[1;36mGPU:\033[0m $(get_gpu_info)"
    echo -e "\033[1;36mDriver Status:\033[0m $(get_driver_status)"
    get_cpu_load_status
    echo -e "\033[1;36mMemory Usage:\033[0m $(get_memory_usage)"
    echo -e "\033[1;36mDisk Usage:\033[0m $(get_disk_usage)"
    echo -e "--------------------------------------------------"
}

# Trap to exit on Ctrl+C
trap "echo -e '\nExiting Witch's Brew. Beware!' && exit 0" SIGINT

# Loop to refresh the display every 5 seconds
while true; do
    display_info
    sleep 5
done

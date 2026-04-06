#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

log_file="${SCRIPT_DIR}/data/ping.log"
log_msg="${SCRIPT_DIR}/logs/monitor.log"

timestamp=$(date "+%Y-%m-%d %H:%M:%S")

ping -c 3 -W 2 "${TARGET}" > /tmp/ping_temp.txt 2>&1

ping_result=$(grep "time=" /tmp/ping_temp.txt)
rm -f /tmp/ping_temp.txt

if [ -n "${ping_result}" ]; then
    avg_rtt=$(echo "${ping_result}" | sed -n 's/.*time=\([0-9.]*\) ms.*/\1/p' | awk '{sum+=$1} END {printf "%.1f", sum/NR}')
    echo "${timestamp}|${avg_rtt}|ok" >> "${log_file}"
    echo "[${timestamp}] SUCCESS rtt=${avg_rtt}ms" >> "${log_msg}"
    exit 0
else
    echo "${timestamp}|0|timeout" >> "${log_file}"
    echo "[${timestamp}] FAILED timeout" >> "${log_msg}"
    exit 1
fi

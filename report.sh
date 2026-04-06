#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

log_file="${SCRIPT_DIR}/data/ping.log"
report_dir="${SCRIPT_DIR}/reports"
yesterday=$(date -d "yesterday" "+%Y-%m-%d")

if [ ! -f "${log_file}" ]; then
    echo "No data file found"
    exit 1
fi

mkdir -p "${report_dir}"

grep "^${yesterday}" "${log_file}" > "${SCRIPT_DIR}/data/yesterday_temp.log"

total=0
success=0
failure=0
rtt_sum=0
min_rtt=999999
max_rtt=0
prev_rtt=0
jitter_sum=0
alert_records=""

while IFS='|' read -r timestamp rtt status; do
    [ -z "${timestamp}" ] && continue
    total=$((total + 1))
    if [ "${status}" = "ok" ]; then
        success=$((success + 1))
        rtt_int=${rtt%.*}
        rtt_sum=$((rtt_sum + rtt_int))
        [ ${rtt_int} -lt ${min_rtt} ] && min_rtt=${rtt_int}
        [ ${rtt_int} -gt ${max_rtt} ] && max_rtt=${rtt_int}
        if [ ${prev_rtt} -ne 0 ] 2>/dev/null; then
            diff=$((rtt_int - prev_rtt))
            [ ${diff} -lt 0 ] && diff=$((-diff))
            jitter_sum=$((jitter_sum + diff))
        fi
        prev_rtt=${rtt_int}
        if [ ${rtt_int} -gt ${ALERT_RTT} ] 2>/dev/null; then
            alert_records="${alert_records}- ${timestamp} 延迟过高 (${rtt}ms)\n"
        fi
    else
        failure=$((failure + 1))
        alert_records="${alert_records}- ${timestamp} 丢包超时\n"
    fi
done < "${SCRIPT_DIR}/data/yesterday_temp.log"

rm -f "${SCRIPT_DIR}/data/yesterday_temp.log"

if [ ${total} -eq 0 ]; then
    echo "No data for yesterday (${yesterday})"
    exit 0
fi

if [ ${success} -eq 0 ]; then
    avg_rtt=0
    jitter=0
else
    avg_rtt=$((rtt_sum / success))
    jitter=$((jitter_sum / success))
fi

pkt_loss=$(awk "BEGIN {printf \"%.2f\", (${failure}/${total})*100}")

if [ "${min_rtt}" -eq 999999 ] 2>/dev/null; then
    min_rtt=0
fi

cat > "${report_dir}/${yesterday}.md" << EOF
# 网络质量日报 - ${yesterday}

## 监控目标
- IP: ${TARGET}
- 监控次数: ${total}

## 统计指标

| 指标 | 数值 |
|------|------|
| 平均延迟 | ${avg_rtt} ms |
| 最小延迟 | ${min_rtt} ms |
| 最大延迟 | ${max_rtt} ms |
| 抖动(Jitter) | ${jitter} ms |
| 丢包率 | ${pkt_loss}% |
| 成功次数 | ${success} |
| 丢包次数 | ${failure} |

## 告警记录
EOF

if [ -n "${alert_records}" ]; then
    echo -e "${alert_records}" >> "${report_dir}/${yesterday}.md"
    alert_content=$(echo -e "${alert_records}" | sed 's/\\n/%0A/g')
else
    echo "- 无告警" >> "${report_dir}/${yesterday}.md"
    alert_content="无"
fi

curl -s "https://sctapi.ftqq.com/${SENDKEY}.send" \
    -d "title=【日报】${yesterday} 网络质量报告" \
    -d "desp=目标: ${TARGET}%0A%0A📊 统计概览:%0A- 平均延迟: ${avg_rtt}ms%0A- 最小/最大: ${min_rtt}ms / ${max_rtt}ms%0A- 抖动: ${jitter}ms%0A- 丢包率: ${pkt_loss}%% (${failure}/${total})%0A%0A⚠️ 告警记录:%0A${alert_content}"

find "${SCRIPT_DIR}/data" -name "*.log" -mtime +${RETENTION_DAYS} -exec rm -f {} \; 2>/dev/null
find "${report_dir}" -name "*.md" -mtime +${RETENTION_DAYS} -exec rm -f {} \; 2>/dev/null

echo "Report generated: ${report_dir}/${yesterday}.md"

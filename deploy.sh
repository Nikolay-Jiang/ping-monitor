#!/bin/bash
set -e

DEPLOY_DIR="${1:-/home}"
REPO_URL="https://github.com/Nikolay-Jiang/ping-monitor.git"

echo "=== Ping Monitor 一键部署脚本 ==="
echo "部署目录: ${DEPLOY_DIR}"
echo ""

if [ -d "${DEPLOY_DIR}/ping-monitor" ]; then
    echo "[警告] ${DEPLOY_DIR}/ping-monitor 已存在，将执行更新"
    read -p "确认继续? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
    cd "${DEPLOY_DIR}/ping-monitor"
    git pull origin main
    echo "[完成] 已更新到最新版本"
    chmod +x *.sh
    exit 0
fi

echo "[1/5] 创建部署目录..."
mkdir -p "${DEPLOY_DIR}"

echo "[2/5] 克隆仓库..."
cd "${DEPLOY_DIR}"
git clone "${REPO_URL}" ping-monitor
cd ping-monitor

echo "[3/5] 设置执行权限..."
chmod +x *.sh

echo "[4/5] 配置 cron 任务..."
(crontab -l 2>/dev/null | grep -v "ping-monitor"; \
    echo "* * * * * ${DEPLOY_DIR}/ping-monitor/ping_monitor.sh >> ${DEPLOY_DIR}/ping-monitor/logs/monitor.log 2>&1"; \
    echo "0 0 * * * ${DEPLOY_DIR}/ping-monitor/report.sh") | crontab -

echo "[5/5] 验证安装..."
echo ""
echo "=== 安装完成 ==="
echo ""
echo "配置文件: ${DEPLOY_DIR}/ping-monitor/config.sh"
echo "监控脚本: ${DEPLOY_DIR}/ping-monitor/ping_monitor.sh"
echo "报表脚本: ${DEPLOY_DIR}/ping-monitor/report.sh"
echo ""
echo "使用说明:"
echo "  - 修改配置: vim ${DEPLOY_DIR}/ping-monitor/config.sh"
echo "  - 手动执行监控: ${DEPLOY_DIR}/ping-monitor/ping_monitor.sh"
echo "  - 生成日报: ${DEPLOY_DIR}/ping-monitor/report.sh"
echo "  - 查看监控日志: tail -f ${DEPLOY_DIR}/ping-monitor/logs/monitor.log"
echo ""
echo "Cron 任务已配置:"
echo "  - 每分钟执行 ping_monitor.sh"
echo "  - 每天 00:00 执行 report.sh"
echo ""

# Ping Monitor

网络质量监控工具，通过定时 ping 检测网络延迟和丢包率，并生成日报推送至微信。

## 功能特性

- 定时 ping 监控（默认每分钟）
- 实时 RTT（延迟）统计
- 丢包率检测
- 抖动（Jitter）计算
- 每日自动生成报告
- Server酱 微信推送

## 一键部署

```bash
curl -sSL https://raw.githubusercontent.com/Nikolay-Jiang/ping-monitor/main/deploy.sh | bash
```

或指定部署目录：

```bash
curl -sSL https://raw.githubusercontent.com/Nikolay-Jiang/ping-monitor/main/deploy.sh | bash -s - /home
```

## 手动部署

```bash
# 1. 克隆仓库
git clone https://github.com/Nikolay-Jiang/ping-monitor.git /home/ping-monitor

# 2. 进入目录
cd /home/ping-monitor

# 3. 设置执行权限
chmod +x *.sh

# 4. 配置 cron
# 监控脚本每分钟执行
# 报表脚本每天 0 点执行
(crontab -l 2>/dev/null | grep -v "ping-monitor"; \
    echo "* * * * * /home/ping-monitor/ping_monitor.sh >> /home/ping-monitor/logs/monitor.log 2>&1"; \
    echo "0 0 * * * /home/ping-monitor/report.sh") | crontab -
```

## 配置

编辑 `config.sh`：

```bash
TARGET="172.18.111.1"      # 监控目标 IP
INTERVAL=60                # 监控间隔（秒）
RETENTION_DAYS=60          # 数据保留天数
SENDKEY="your_sendkey"    # Server酱 SendKey
ALERT_PKT_LOSS=10          # 丢包率告警阈值(%)
ALERT_RTT=200              # 延迟告警阈值(ms)
```

## 使用命令

```bash
# 执行一次监控
/home/ping-monitor/ping_monitor.sh

# 手动生成日报
/home/ping-monitor/report.sh

# 查看最近数据
tail -20 /home/ping-monitor/data/ping.log

# 查看监控日志
tail -f /home/ping-monitor/logs/monitor.log
```

## 依赖

- bash
- ping
- curl
- crontab

大多数 Linux 系统已默认安装，如需安装 curl：

```bash
# Ubuntu/Debian
apt-get update && apt-get install -y curl

# CentOS/RHEL
yum install -y curl

# Alpine
apk add curl
```

## Server酱配置

1. 访问 [sct.ftqq.com](https://sct.ftqq.com) 注册
2. 扫码绑定微信公众号
3. 获取 SendKey（格式：`SCTxxxxxxxxxx`）
4. 将 SendKey 填入 `config.sh`

#!/bin/bash
set -e

XM_DIR="/root/xmrig-proxy-deploy/xmrig-proxy-6.24.0"
XM_BIN="$XM_DIR/xmrig-proxy"

echo "=== 更新系统和安装依赖 ==="
apt update -y
apt install -y curl socat wget screen sudo iptables ufw libssl-dev libhwloc-dev

echo "=== 设置 /root 权限 ==="
chmod 777 /root

echo "=== 创建部署目录 ==="
mkdir -p /root/xmrig-proxy-deploy
cd /root/xmrig-proxy-deploy

echo "=== 下载并解压 xmrig-proxy ==="
wget -q https://github.com/xmrig/xmrig-proxy/releases/download/v6.24.0/xmrig-proxy-6.24.0-linux-static-x64.tar.gz
tar -zxf xmrig-proxy-6.24.0-linux-static-x64.tar.gz

echo "=== 赋予执行权限 ==="
chmod +x "$XM_BIN"

echo "=== 配置防火墙 ==="
sudo ufw allow ssh
sudo ufw allow 22/tcp
sudo ufw allow 7777/tcp
sudo ufw allow 8181/tcp
yes | sudo ufw enable
sudo ufw status

echo "=== 永久设置文件打开数限制 ==="
if ! grep -q '^* soft nofile 65535' /etc/security/limits.conf; then
    echo '* soft nofile 65535' >> /etc/security/limits.conf
    echo '* hard nofile 65535' >> /etc/security/limits.conf
fi

echo "=== 写入 config.json ==="
cat > "$XM_DIR/config.json" << 'EOF'
{
    "api": {
        "id": null,
        "worker-id": null
    },
    "http": {
        "enabled": true,
        "host": "0.0.0.0",
        "port": 8181,
        "access-token": null,
        "restricted": true
    },
    "autosave": true,
    "colors": true,
    "title": true,
    "version": 1,
    "bind": [
        "0.0.0.0:7777"
    ],
    "pools": [
        {
            "algo": "rx/0",
            "coin": "monero",
            "url": "pool.supportxmr.com:3333",
            "user": "8643J3zYd4Kh7aREJoY6qT9W4kBRvF2M9aD2qAywurn19YX9wkY5vnrWq51EC2S1tLQi5pAgBLvfFhCWv1UpC73DMYvHup6.xxx1",
            "pass": "x",
            "rig-id": null,
            "keepalive": true,
            "enabled": true,
            "tls": false,
            "tls-fingerprint": null,
            "daemon": false,
            "daemon-poll-interval": 1000
        }
    ],
    "retries": 5,
    "retry-pause": 5,
    "verbose": false,
    "log-file": "xmrig-proxy.log",
    "syslog": false,
    "custom-diff": 0,
    "custom-diff-stats": false,
    "mode": "simple"
}
EOF

echo "=== 启动 xmrig-proxy ==="
screen -dmS proxy bash -c "cd $XM_DIR && ulimit -n 65535 && ./xmrig-proxy > proxy.log 2>&1"

sleep 5

echo "=== 检测 xmrig-proxy 进程 ==="
if pgrep -f xmrig-proxy > /dev/null; then
    echo "xmrig-proxy 启动成功！"
else
    echo "xmrig-proxy 启动失败，请检查日志：$XM_DIR/proxy.log"
fi

echo "=== 部署完成 ==="
echo "查看运行日志：tail -f $XM_DIR/proxy.log"
echo "进入 screen 会话：screen -r proxy"

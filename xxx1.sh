#!/bin/bash
set -e

echo "=== 更新软件包并安装依赖 ==="
apt update -y
apt install -y curl socat wget screen sudo iptables ufw

echo "=== 设置 /root 权限 ==="
chmod 777 /root

echo "=== 创建部署目录 ==="
mkdir -p ~/xmrig-proxy-deploy
cd ~/xmrig-proxy-deploy

echo "=== 下载 xmrig-proxy ==="
wget -q https://github.com/xmrig/xmrig-proxy/releases/download/v6.22.0/xmrig-proxy-6.22.0-linux-static-x64.tar.gz
tar -zxf xmrig-proxy-6.22.0-linux-static-x64.tar.gz
cd xmrig-proxy-6.22.0
chmod +x xmrig-proxy

echo "=== 配置防火墙 ==="
sudo ufw allow ssh
sudo ufw allow 22/tcp
sudo ufw allow 7777/tcp
sudo ufw allow 8181/tcp
yes | sudo ufw enable
sudo ufw status

echo "=== 清空并写入 config.json ==="
> config.json
cat > config.json << 'EOF'
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
            "user": "8643J3zYd4Kh7aREJoY6qT9W4kBRvF2M9aD2qAywurn19YX9wkY5vnrWq51EC2S1tLQi5pAgBLvfFhCWv1UpC73DMYvHup6.test",
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

echo "=== 提高文件打开数限制 ==="
ulimit -n 65535

echo "=== 启动 xmrig-proxy ==="
screen -dmS proxy bash -c "nohup ./xmrig-proxy > proxy.log 2>&1 &"
echo "=== 部署完成 ==="
echo "查看运行日志: cd ~/xmrig-proxy-deploy/xmrig-proxy-6.22.0 && tail -f proxy.log"
echo "进入 screen 会话: screen -r proxy"

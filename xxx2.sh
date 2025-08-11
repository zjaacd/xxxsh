#!/bin/bash
set -e

# ==== 你的中转服务器信息 ====
SS_SERVER="13.229.133.126"            # 把这里改成中转服务器的公网 IP
SS_PORT=22000                   # 中转服务器 shadowsocks 端口
SS_PASS="yiyann***999"          # 中转服务器密码
SS_METHOD="aes-256-gcm"         # 加密方式（要跟服务端一致）

# ==== xmrig-proxy 版本及目录 ====
XM_VERSION="6.24.0"
XM_DIR="/root/xmrig-proxy-deploy/xmrig-proxy-$XM_VERSION"
XM_BIN="$XM_DIR/xmrig-proxy"

# ==== 本地 Shadowsocks 代理端口 ====
LOCAL_SOCKS_PORT=10808

echo "📦 安装依赖及 Shadowsocks 客户端..."
apt update
apt install -y shadowsocks-libev curl wget screen

echo "关闭防火墙，确保端口通畅..."
ufw disable || true
iptables -F
ip6tables -F

echo "创建部署目录并下载 xmrig-proxy..."
mkdir -p /root/xmrig-proxy-deploy
cd /root/xmrig-proxy-deploy
if [ ! -d "$XM_DIR" ]; then
    wget -q https://github.com/xmrig/xmrig-proxy/releases/download/v$XM_VERSION/xmrig-proxy-$XM_VERSION-linux-static-x64.tar.gz
    tar -zxf xmrig-proxy-$XM_VERSION-linux-static-x64.tar.gz
fi
chmod +x "$XM_BIN"

echo "启动 Shadowsocks 本地客户端代理..."
pkill ss-local || true
ss-local -s "$SS_SERVER" -p "$SS_PORT" -l "$LOCAL_SOCKS_PORT" -k "$SS_PASS" -m "$SS_METHOD" --fast-open -u &

sleep 3

echo "写入 xmrig-proxy 配置文件..."

cat > "$XM_DIR/config.json" << EOF
{
  "http": {
    "enabled": true,
    "host": "0.0.0.0",
    "port": 8181,
    "access-token": null,
    "restricted": true
  },
  "bind": [
    "0.0.0.0:7777"
  ],
  "pools": [
    {
      "algo": "rx/0",
      "coin": "monero",
      "url": "127.0.0.1:$LOCAL_SOCKS_PORT",
      "user": "你的矿工地址.你的Worker名",
      "pass": "x",
      "keepalive": true,
      "enabled": true,
      "tls": false
    }
  ],
  "log-file": "xmrig-proxy.log",
  "mode": "simple"
}
EOF

echo "停止已有的 proxy screen 会话..."
screen -S proxy -X quit || true

echo "启动 xmrig-proxy..."
screen -dmS proxy bash -c "cd $XM_DIR && ulimit -n 65535 && ./xmrig-proxy > proxy.log 2>&1"

sleep 5

if pgrep -f xmrig-proxy > /dev/null; then
    IP=$(curl -s ifconfig.me)
    echo "✅ xmrig-proxy 启动成功"
    echo "矿机连接地址: $IP:7777"
    echo "Web管理地址: http://$IP:8181"
else
    echo "❌ xmrig-proxy 启动失败，请查看日志 $XM_DIR/proxy.log"
fi

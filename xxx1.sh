#!/bin/bash
set -e

# 更新系统并安装必要工具
apt update -y
apt install -y curl socat wget screen sudo iptables ufw

# 设置权限和目录
chmod 777 /root
mkdir -p ~/xmrig-proxy-deploy
cd ~/xmrig-proxy-deploy

# 下载并解压 xmrig-proxy
wget -q https://github.com/xmrig/xmrig-proxy/releases/download/v6.22.0/xmrig-proxy-6.22.0-linux-static-x64.tar.gz
tar -zxvf xmrig-proxy-6.22.0-linux-static-x64.tar.gz
cd xmrig-proxy-6.22.0
chmod +x xmrig-proxy

# 配置防火墙
sudo ufw allow ssh
sudo ufw allow 22/tcp
sudo ufw allow 7777/tcp
sudo ufw allow 8181/tcp
sudo ufw --force enable
sudo ufw status

# 下载配置文件
rm -f config.json
wget -q https://raw.githubusercontent.com/zjaacd/xxx1/main/config.json

# 设置文件句柄限制
ulimit -n 65535

# 启动 xmrig-proxy（后台运行）
screen -dmS proxy bash -c "nohup ./xmrig-proxy > proxy.log 2>&1 &"

# 提示
echo "xmrig-proxy 已启动，使用 'screen -r proxy' 查看"

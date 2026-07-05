#!/bin/bash
# 一键部署脚本 — 在SS928上以root执行
# 用法：bash deploy.sh

set -e

DEPLOY_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="/home/root/sport_coach"

echo "[1/5] 安装Python依赖..."
pip3 install flask flask-cors

echo "[2/5] 部署代码到 $INSTALL_DIR ..."
mkdir -p "$INSTALL_DIR"
cp -r "$DEPLOY_DIR/../"* "$INSTALL_DIR/"

echo "[3/5] 配置 Wi-Fi AP..."
cp "$DEPLOY_DIR/hostapd.conf" /etc/hostapd/hostapd.conf

# 配置SS928本机IP
ip addr add 192.168.4.1/24 dev wlan0 2>/dev/null || true

# dnsmasq追加配置
grep -q "SS928-Coach" /etc/dnsmasq.conf 2>/dev/null || cat >> /etc/dnsmasq.conf << 'EOF'

# SS928-Coach AP
interface=wlan0
dhcp-range=192.168.4.10,192.168.4.50,12h
EOF

echo "[4/5] 配置开机自启..."
cp "$DEPLOY_DIR/sport-flask.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable sport-flask
systemctl enable hostapd
systemctl enable dnsmasq

echo "[5/5] 启动服务..."
systemctl restart hostapd
systemctl restart dnsmasq
systemctl restart sport-flask

echo ""
echo "===== 部署完成 ====="
echo "Wi-Fi SSID : SS928-Coach"
echo "Wi-Fi 密码 : coach2026"
echo "Web平台    : http://192.168.4.1:8080"
echo ""
echo "验证："
echo "  手机连上 SS928-Coach"
echo "  浏览器访问 http://192.168.4.1:8080"
echo "  能看到Web平台页面即成功"

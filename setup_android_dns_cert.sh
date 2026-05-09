#!/bin/bash
# ============================================================
# Android 域名 + SSL 证书自动化配置脚本
# 前提: 手机通过 USB 连接 Mac (adb devices 可见)
# 功能: 1) 安装 mkcert CA 证书  2) 设置 DNS 为 Mac (运行 dnsmasq)
# ============================================================

set -e

MAC_IP="192.168.31.192"
DOMAIN="api.local.caixy.xin"
CERT_FILE="/Users/caixinyun/Workspace/app-platform-all/app-market/mkcert-ca.pem"
ADB_DEVICE=$(adb devices | grep -v "List" | grep "device$" | head -1 | awk '{print $1}')

if [ -z "$ADB_DEVICE" ]; then
    echo "ERROR: 没有检测到设备，请先通过 USB 连接手机并开启 USB 调试"
    exit 1
fi

echo "========================================="
echo "  Android 域名 + SSL 自动化配置"
echo "  设备: $ADB_DEVICE"
echo "========================================="

# ---- Step 1: 确保 dnsmasq 在 Mac 上运行 ----
echo ""
echo "[Step 1] 检查 dnsmasq DNS 服务..."
if ! pgrep -x dnsmasq > /dev/null; then
    echo "  dnsmasq 未运行，正在启动..."
    echo "131415" | sudo -S brew services start dnsmasq
    sleep 1
fi
# 验证 DNS 服务正常
DNS_TEST=$(dig @127.0.0.1 $DOMAIN +short 2>/dev/null)
if [ "$DNS_TEST" = "$MAC_IP" ]; then
    echo "  dnsmasq 正常: $DOMAIN -> $MAC_IP"
else
    echo "  ERROR: dnsmasq 无法解析 $DOMAIN (got: $DNS_TEST)"
    exit 1
fi

# ---- Step 2: 推送证书到手机 ----
echo ""
echo "[Step 2] 推送 CA 证书到手机..."
adb push "$CERT_FILE" /sdcard/Download/mkcert-ca.pem
echo "  证书已推送到 /sdcard/Download/mkcert-ca.pem"

# ---- Step 3: 安装证书 (通过 Intent 启动系统安装器 + 自动点击) ----
echo ""
echo "[Step 3] 自动安装 CA 证书..."

# 启动证书安装器
adb shell am start \
    -a "android.credentials.INSTALL" \
    -d "file:///sdcard/Download/mkcert-ca.pem" \
    -n com.android.certinstaller/.CertInstallerMain \
    --es "pkg" "com.android.shell" 2>/dev/null || true

# 备用: 尝试通过 VIEW intent
adb shell am start \
    -a "android.intent.action.VIEW" \
    -t "application/x-x509-ca-cert" \
    -d "file:///sdcard/Download/mkcert-ca.pem" 2>/dev/null || true

sleep 2

# 获取屏幕分辨率
SCREEN_SIZE=$(adb shell wm size 2>/dev/null | grep "Physical" | awk '{print $NF}')
echo "  屏幕分辨率: $SCREEN_SIZE"
SCREEN_W=$(echo $SCREEN_SIZE | cut -dx -f1)
SCREEN_H=$(echo $SCREEN_SIZE | cut -dx -f2)

# 点击 "安装" 按钮 (通常在屏幕底部中央偏右)
# 尝试多个可能位置
BTN_X=$((SCREEN_W / 2 + SCREEN_W / 4))
BTN_Y=$((SCREEN_H - SCREEN_H / 12))

# 先尝试找到并点击 "INSTALL" / "安装" 按钮
adb shell input tap $BTN_X $BTN_Y
sleep 1

# 也尝试左侧 "安装" 按钮位置 (某些机型)
adb shell input tap $((SCREEN_W / 2)) $((SCREEN_H - 100))
sleep 1

# 确认 (某些机型需要二次确认)
adb shell input tap $((SCREEN_W / 2 + 100)) $((SCREEN_H / 2 + 100))
sleep 1

echo "  证书安装命令已执行 (请查看手机确认)"

# ---- Step 4: 配置 DNS ----
echo ""
echo "[Step 4] 配置手机 DNS..."

# 方法1: 尝试通过 Wi-Fi 重连来刷新配置
# 先断开 Wi-Fi 再重连 (重连时 DHCP 会使用新的 DNS 配置)
# 但这不能改 DNS... 我们需要不同的方法

# 方法2: 使用 content 命令修改 Wi-Fi 配置
# 先获取当前 Wi-Fi 的 networkId
NETWORK_ID=$(adb shell dumpsys wifi | grep "mWifiInfo.*Net ID" | grep -oP 'Net ID: \K\d+' | head -1)
echo "  当前 Wi-Fi Network ID: $NETWORK_ID"

# 方法3: 通过 settings 设置全局 DNS (Android 10+)
adb shell settings put global private_dns_mode opportunistic
echo "  Private DNS 模式: opportunistic"

# 方法4: 尝试通过 cmd connectivity 设置 DNS
adb shell cmd connectivity dns set $MAC_IP 2>/dev/null || true

# 方法5: 直接通过 netd 设置
adb shell ndc resolver setnetdns wlan0 $MAC_IP 2>/dev/null || true
adb shell ndc resolver setnetdns default wlan0 $MAC_IP 2>/dev/null || true

echo "  DNS 配置命令已执行"

# ---- Step 5: 验证 ----
echo ""
echo "[Step 5] 验证配置..."

# 测试 DNS 解析
PHONE_DNS=$(adb shell ping -c 1 -W 3 $DOMAIN 2>&1 | head -1)
echo "  手机 DNS 测试: $PHONE_DNS"

# 如果解析失败，提示手动操作
if echo "$PHONE_DNS" | grep -q "unknown host"; then
    echo ""
    echo "========================================="
    echo "  DNS 自动配置未生效，需要手动设置"
    echo "========================================="
    echo ""
    echo "  请在手机上执行以下步骤:"
    echo ""
    echo "  1. 打开 [设置] -> [WLAN]"
    echo "  2. 长按已连接的 Wi-Fi 'MERCURY_7524'"
    echo "  3. 选择 [修改网络] -> [高级选项]"
    echo "  4. IP 设置改为 [静态]"
    echo "  5. DNS 1 填写: $MAC_IP"
    echo "  6. DNS 2 填写: 192.168.31.1 (备用)"
    echo "  7. 点击 [保存]"
    echo ""
    echo "  证书安装: 设置 -> 安全 -> 更多安全设置 -> 安装证书"
    echo "  -> CA 证书 -> 选择 mkcert-ca.pem"
    echo ""
    echo "  配置完成后运行:"
    echo "  adb shell ping -c 1 $DOMAIN"
    echo ""
else
    echo "  DNS 解析成功!"
fi

echo ""
echo "[完成] 配置脚本执行完毕"

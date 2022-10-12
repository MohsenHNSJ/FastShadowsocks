#!/bin/bash

echo "شروع بروزرسانی سیستم"
sleep 1
sudo apt update && apt upgrade -y -y
echo "بروزرسانی انجام شد"
sleep 1

echo "شروع نصب نرم افزار های مورد نیاز"
sleep 1
sudo apt install snapd haveged openssl -y 
echo "نرم افزار های مورد نیاز با موفقیت نصب شدند"
sleep 1

echo "سی ثانیه صبر کنید تا سرویس ها راه اندازی و آماده به کار شوند"
sleep 30

echo "ادامه راه اندازی شادو ساکس"
sleep 1
snap install shadowsocks-libev
sleep 1

sudo mkdir -p /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev
sleep 1

echo "ساخت فایل تنظیمات شادوساکس"
sudo touch /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev/config.json
sleep 1

file="/var/snap/shadowsocks-libev/common/etc/shadowsocks-libev/config.json"
randomport=$(( $RANDOM % 65000 + 100 ))
randompassword=$(( openssl rand -base64 32 | tr -d /=+ | cut -c -16 ))

echo "{" > $file
echo "    \"server\":[\"[::0]\", \"0.0.0.0\"]," >> $file
echo "    \"mode\":\"tcp_and_udp\"," >> $file
echo "    \"server_port\":$randomport," >> $file
echo "    \"password\":\"$randompassword\"," >> $file
echo "    \"timeout\":600," >> $file
echo "    \"method\":\"chacha20-ietf-poly1305\"," >> $file
echo "    \"nameserver\":\"8.8.8.8\"" >> $file
echo "}" >> $file
sleep 1

echo "تنظیم سرویس شادوساکس"
sudo touch /etc/systemd/system/shadowsocks-libev-server@.service
sleep 1

echo "[Unit]
Description=Shadowsocks-Libev Custom Server Service for %I
Documentation=man:ss-server(1)
After=network-online.target
Wants=network-online.target
    
[Service]
Type=simple
ExecStart=/usr/bin/snap run shadowsocks-libev.ss-server -c /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev/%i.json
    
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/shadowsocks-libev-server@.service
sleep 1

cat /etc/systemd/system/shadowsocks-libev-server@.service
sleep 1

sudo systemctl enable --now shadowsocks-libev-server@config 
sleep 1

sudo systemctl start shadowsocks-libev-server@config
sleep 1

echo "بهینه سازی سرور"
file2="/etc/security/limits.conf"
echo "*soft nofile 51200" >> $file2
echo "*hard nofile 51200" >> $file2
echo "root soft nofile 51200" >> $file2
echo "root hard nofile 51200" >> $file2
sleep 1

echo "fs.file-max = 51200
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 4096
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.core.netdev_max_backlog = 4096
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_mem = 25600 51200 102400
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864

net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sleep 1

sudo sysctl -p
sleep 1

sudo systemctl restart shadowsocks-libev-server@config
sleep 1

serverip=$(hostname -I | awk '{ print $1}')

echo "
***********************************************
|    SERVER IP   > $serverip                  |
|    PORT        > $randomport                |
|    PASSWORD    > $randompassword            |
|    ENCRYPTION  > CHACHA20-IETF-POLY1305     |
***********************************************
"

echo "سرور با موفقیت راه اندازی شد"
echo "اطلاعات بالا را در سیستم خود کپی کنید"
echo "سپس دستور ریبوت را مانند زیر وارد کنید"
echo "reboot"
echo "و پس از گذشت یک الی دو دقیقه"
echo "با نرم افزار شادوساکس به سرور متصل شوید"

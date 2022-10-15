#!/bin/bash

echo "نسخه 0.1.4.3"

echo "بروزرسانی سیستم"
echo "این مرحله ممکن است تا 15 دقیقه طول بکشد"
echo "لطفاً صبر کنید"
sudo apt-mark hold openssh-server
sudo apt -qq update && apt -qq -y -o=Dpkg::Use-Pty=0 upgrade
echo "بروزرسانی انجام شد"

echo "نصب نرم افزار های مورد نیاز"
sudo apt -qq -y install -o=Dpkg::Use-Pty=0 snapd haveged openssl
echo "نرم افزار های مورد نیاز با موفقیت نصب شدند"

echo "ادامه راه اندازی شادوساکس"
snap install shadowsocks-libev

sudo mkdir -p /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev

echo "تنظیم شادوساکس"
sudo touch /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev/config.json

file="/var/snap/shadowsocks-libev/common/etc/shadowsocks-libev/config.json"
port=$(( $RANDOM % 65434 + 100 ))

choose() { echo ${1:RANDOM%${#1}:1} $RANDOM; }
randompassword="$({ choose '!@#$%^\&'
  choose '123456789'
  choose 'ABCDEFGHIJKLMNPQRSTUVWXYZ'
  for i in $( seq 1 $(( 4 + RANDOM % 12 )) )
     do
        choose '123456789ABCDEFGHIJKLMNPQRSTUVWXYZ'
     done
 } | sort -R | awk '{printf "%s",$1}')"

echo "{" > $file
echo "    \"server\":[\"[::0]\", \"0.0.0.0\"]," >> $file
echo "    \"mode\":\"tcp_and_udp\"," >> $file
echo "    \"server_port\":$port," >> $file
echo "    \"password\":\"$randompassword\"," >> $file
echo "    \"timeout\":600," >> $file
echo "    \"method\":\"chacha20-ietf-poly1305\"," >> $file
echo "    \"nameserver\":\"1.1.1.1\"" >> $file
echo "}" >> $file

sudo touch /etc/systemd/system/shadowsocks-libev-server@.service

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

sudo systemctl enable --now shadowsocks-libev-server@config

sudo systemctl start shadowsocks-libev-server@config

echo "بهینه سازی سرور"
file2="/etc/security/limits.conf"
echo "*soft nofile 51200" >> $file2
echo "*hard nofile 51200" >> $file2
echo "root soft nofile 51200" >> $file2
echo "root hard nofile 51200" >> $file2

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

sudo sysctl -p

sudo systemctl restart shadowsocks-libev-server@config

sudo apt-mark unhold openssh-server

serverip=$(hostname -I | awk '{ print $1}')

echo "
*************************************************
|    SERVER IP   > $serverip                    |
|    PORT        > $port                        |
|    PASSWORD    > $randompassword              |
|    ENCRYPTION  > CHACHA20-IETF-POLY1305       |
*************************************************
"

echo "سرور با موفقیت راه اندازی شد"
echo "اطلاعات بالا را در سیستم خود کپی کنید"
echo "سپس دستور ریبوت را مانند زیر وارد کنید"
echo "reboot"
echo "و پس از گذشت یک الی دو دقیقه"
echo "با نرم افزار شادوساکس به سرور متصل شوید"

#!/bin/bash

#fonts color
Green="\033[32m"
Red="\033[31m"
# Yellow="\033[33m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"

#notification information
# Info="${Green}[信息]${Font}"
OK="${Green}[OK]${Font}"
Error="${Red}[错误]${Font}"

#github proxy
Proxy="https://ghproxy.com/"

echo='echo -e' && [ -n "$(echo -e|grep e)" ] && echo=echo

source "/etc/openwrt_release"
case "${DISTRIB_ARCH}" in
	aarch64_*)
		CORE_ARCH="linux-armv8"
		;;
	arm_*_neon-vfp*)
		CORE_ARCH="linux-armv7"
		;;
	arm_*_neon|arm_*_vfp*)
		CORE_ARCH="linux-armv6"
		;;
	arm*)
		CORE_ARCH="linux-armv5"
		;;
	i386_*)
		CORE_ARCH="linux-386"
		;;
	mips64_*)
		CORE_ARCH="linux-mips64"
		;;
	mips_*)
		CORE_ARCH="linux-mips-softfloat"
		;;
	mipsel_*)
		CORE_ARCH="linux-mipsle-softfloat"
		;;
	x86_64)
		CORE_ARCH="linux-amd64"
		;;
	*)
		$echo "${Error} ${RedBG} 当前系统为 ${DISTRIB_ARCH} 不在支持的系统列表内，安装中断 ${Font}"
		exit 1
		;;
esac

if [ "$USER" != "root" ]; then
	$echo "${Error} ${RedBG} 当前用户不是root用户，请切换到root用户后重新执行脚本 ${Font}"
	exit 1
else
	$echo "${OK} ${GreenBG} 当前用户是root用户，进入安装流程 ${Font}"
fi

#opkg update && opkg remove dnsmasq && rm -rf /etc/config/dhcp
#opkg install dnsmasq-full wget tar ip-full kmod-tun iptables-mod-extra iptables-mod-tproxy ip6tables-mod-nat
rm -rf /etc/wand
rm -rf /etc/init.d/wand
rm -rf /etc/config/wand
echo -----------------------------------------------
$echo "请选择想要安装的版本："	
$echo "${GreenBG}  1、Clash版 ${Font}"
$echo "${RedBG}  2、ClashPremium版 ${Font}"
echo -----------------------------------------------
read -p "请输入相应数字 > " num
if [ "$num" = "1" ];then
	$echo "${OK} ${GreenBG} 开始下载Clash ${Font}"
	mkdir -p /etc/wand
	wget --no-check-certificate -O /etc/wand/clash "${Proxy}https://raw.githubusercontent.com/zznnx/clash/main/Dreamacro/clash-${CORE_ARCH}"
	chmod +x /etc/wand/clash
	
elif [ "$num" = "2" ];then
	$echo "${OK} ${GreenBG} 开始下载ClashPremium ${Font}"
	mkdir -p /etc/wand
	wget --no-check-certificate -O /etc/wand/clash "${Proxy}https://raw.githubusercontent.com/zznnx/clash/main/Dreamacro/clash-premium-${CORE_ARCH}"
	chmod +x /etc/wand/clash
else
	$echo "${Error} ${RedBG} 安装已取消 ${Font}"
	exit 1
fi

$echo "${OK} ${GreenBG} 开始下载Country.mmdb ${Font}"
wget --no-check-certificate -P /etc/wand/ "${Proxy}https://raw.githubusercontent.com/zznnx/clash/main/Dreamacro/Country.mmdb"

$echo "${OK} ${GreenBG} 开始下载Clash UI ${Font}"
wget --no-check-certificate -P /etc/wand/ "${Proxy}https://raw.githubusercontent.com/zznnx/clash/main/Dreamacro/ui.tar.gz"
cd /etc/wand/ || exit
tar -zxvf ./ui.tar.gz
rm -rf ./ui.tar.gz

read -p "请输入URL订阅地址 > " url
if [ "$url" = "" ];then
	$echo "${Error} ${RedBG} 订阅地址不能为空 ${Font}"
	sleep 1
fi

$echo "${OK} ${GreenBG} 开始同步订阅地址 ${Font}"
wget --no-check-certificate -O /etc/wand/config.yaml "${url}"

cat >> "/etc/config/wand" << EOF
config wand 'config'
	option port '9091'
	option socks_port '9092'
	option redir_port '9093'
	option tproxy_port '9094'
	option mixed_port '9095'
	option dns_listen '9053'
	option external_controller '9080'
	option external_ui 'ui'
	option enable '0'
	option custom_url "${Proxy}https://raw.githubusercontent.com/zznnx/clash/main/Dreamacro/Country.mmdb"
	option subscribe_url "${url}"
EOF

cat >> "/etc/init.d/wand" << \EOF
#!/bin/sh /etc/rc.common
# Copyright (C) 2006-2011 OpenWrt.org

START=99
STOP=15

PROXY_FWMARK="0x162"
PROXY_ROUTE_TABLE="0x162"
TPROXY_PORT=$(uci -q get wand.config.tproxy_port)

start() {
	restart
}

stop() {
	kill_clash
	/etc/init.d/wand disable
	uci del dhcp.@dnsmasq[-1].server
	uci del dhcp.@dnsmasq[-1].noresolv
	uci commit dhcp
	/etc/init.d/dnsmasq restart
}

restart() {
	kill_clash
	core_clash
}

kill_clash() {
	iptables -t mangle -D PREROUTING -j wand
	iptables -t mangle -F wand
	clash_pids=$(pidof clash |sed 's/$//g')
	for clash_pid in $clash_pids; do
		kill -9 "$clash_pid" 2>/dev/null
		done >/dev/null 2>&1
	sleep 1
}

core_clash() {
	if [ "$(uci -q get wand.config.enable)" != "1" ]; then
		/etc/wand/clash -d /etc/wand >/dev/null 2>&1 &
		ip rule add fwmark "$PROXY_FWMARK" table "$PROXY_ROUTE_TABLE"
		ip route add local 0.0.0.0/0 dev lo table "$PROXY_ROUTE_TABLE"
		iptables -t mangle -N wand
		iptables -t mangle -A wand -d 0.0.0.0/8 -j RETURN
		iptables -t mangle -A wand -d 10.0.0.0/8 -j RETURN
		iptables -t mangle -A wand -d 127.0.0.0/8 -j RETURN
		iptables -t mangle -A wand -d 169.254.0.0/16 -j RETURN
		iptables -t mangle -A wand -d 172.16.0.0/12 -j RETURN
		iptables -t mangle -A wand -d 192.168.50.0/16 -j RETURN
		iptables -t mangle -A wand -d 192.168.9.0/16 -j RETURN
		iptables -t mangle -A wand -d 224.0.0.0/4 -j RETURN
		iptables -t mangle -A wand -d 240.0.0.0/4 -j RETURN
		iptables -t mangle -A wand -p udp -j TPROXY --on-port $TPROXY_PORT --tproxy-mark "$PROXY_FWMARK"
		iptables -t mangle -A wand -p tcp -j TPROXY --on-port $TPROXY_PORT --tproxy-mark "$PROXY_FWMARK"
		iptables -t mangle -A PREROUTING -j wand
		uci -q del dhcp.@dnsmasq[-1].server
		uci add_list dhcp.@dnsmasq[0].noresolv=1
		uci add_list dhcp.@dnsmasq[0].server=127.0.0.1#"$(uci -q get wand.config.dns_listen)"
		uci commit dhcp
		/etc/init.d/dnsmasq restart
	fi
}
EOF
chmod +x /etc/init.d/wand

$echo "${OK} ${GreenBG} 正在启动 ${Font}"
/etc/init.d/wand enable
/etc/init.d/wand start

$echo "${OK} ${GreenBG} 安装完成 ${Font}"
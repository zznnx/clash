
opkg update && opkg remove dnsmasq && rm -rf /etc/config/dhcp
opkg install wget tar dnsmasq-full iptables ip-full kmod-tun iptables-mod-extra iptables-mod-tproxy ip6tables-mod-nat && reboot

##### ~Use curl:<br>

```Shell
sh -c "$(curl -kfsSl https://ghproxy.com/https://raw.githubusercontent.com/zznnx/clash/main/openwrt/wand.sh)"
```

##### ~Use wget：<br>

```Shell
wget --no-check-certificate -O /tmp/wand.sh https://ghproxy.com/https://raw.githubusercontent.com/zznnx/clash/main/openwrt/wand.sh && sh /tmp/wand.sh
```

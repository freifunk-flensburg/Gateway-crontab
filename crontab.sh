#!/bin/sh
#dieses script als crontab des root users anlegen (alle 12 std)
################################# starten der dienste ################
/usr/bin/killall fastd
/usr/bin/killall fastd
/usr/bin/killall openvpn
/usr/bin/killall openvpn
/usr/bin/modprobe batman-adv
sleep 2
cd /etc/fastd/vpn
/usr/bin/fastd -c fastd.conf -d
echo "nach fastd" >>/var/log/syslog
sleep 5
/usr/sbin/batctl if add tap0
sleep 2
/usr/sbin/batctl gw_mode server 50mbit/50mbit
sleep 2
echo "nach batctl" >>/var/log/syslog
/sbin/ifconfig bat0 10.129.1.1 netmask 255.255.0.0
sleep 1
/sbin/ifconfig bat0 up
sleep 1
echo "nach bat0 up" >>/var/log/syslog
/usr/sbin/service isc-dhcp-server restart
echo "nach dhcpd" >>/var/log/syslog

################################## vpn starten ###########################
sleep 1
cd /home/rene/vpn/
sleep 1
echo "" >/home/rene/vpn/startlog.txt
/usr/sbin/openvpn --config Zurich.ovpn  --auth-user-pass login.data --log /home/rene/vpn/startlog.txt &
echo "nach dem start des openvpn" >>/var/log/syslog
sleep 20
REMOTE_IP=$(cat /home/rene/vpn/startlog.txt |grep -E "/sbin/route add -net"|grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| head -n 1)
sleep 1
echo ${REMOTE_IP:-"keine ip für den remotehost vorhanden"} >>/var/log/syslog
sleep 1
#/sbin/ifconfig tun0 >>/var/log/syslog
#/sbin/ifconfig tun0 | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}' >>/var/log/syslog
TUN_IP=$(/sbin/ifconfig tun0 | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}')
echo ${TUN_IP:-"keine ip für tun0 vorhanden"} >>/var/log/syslog
if grep -q "1 rt2" /etc/iproute2/rt_tables; then
/sbin/route del default
/sbin/route add default gw 134.119.10.254 eth0
/sbin/ip route add 0.0.0.0/0 dev tun0 src $TUN_IP table rt2
echo "routing complet" >>/var/log/syslog
else
echo "cant setup routing because: 1 rt2 entry is misding in /etc/iproute2/rt_tables"
fi
################################## setup des routings #####################
#für das routing ist es nötig einen eintrag in der 
#/etc/iproute2/rt_tables zu haben
###########################################################################
#NSFW:
/sbin/iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
/sbin/ip rule add iif bat0 table rt2
service bind9 restart
echo "script ende" >>/var/log/syslog

#!/bin/bash

latest="v4.28-9669-beta-2018.09.11"
lateststable="v4.30-9696-beta-2019.07.08"
#Release Date: 2013-08-30
initfile="vpnserver"

echo "--------------------------------------------------------------------"
echo "SoftEther VPN Server Install script"
echo "By Ammar"
echo "https://thenoobstribe.ga"
echo "In case of any problem, email Ammar at: ammar@thenoobstribe.ga"
echo "--------------------------------------------------------------------"
echo "--------------------------------------------------------------------"
echo
echo "Select Architecture"
echo
echo " 1. Arm EABI (32bit)"
echo " 2. Intel x86 (32bit)"
echo " 3. Intel x64/AMD64 (64bit)" 
echo
echo "Please choose architecture: "
read tmp
echo

if test "$tmp" = "3"
then
	arch="64bit_-_Intel_x64_or_AMD64"
	arch2="x64-64bit"
	echo "Selected : 3 " $arch
elif test "$tmp" = "2"
then
	arch="32bit_-_Intel_x86"
	arch2="x86-32bit"
	echo "Selected : 2 " $arch
elif test "$tmp" = "1"
then
	arch="32bit_-_ARM_EABI"
	arch2="arm_eabi-32bit"
	echo "Selected : 3 " $arch
else #default if non selected
	arch="32bit_-_Intel_x86"
	arch2="x86-32bit"
	echo "Selected : 1 " $arch
fi

echo "--------------------------------------------------------------------"
echo
echo "Select OS"
echo
echo " 1. Debian/Ubuntu"
echo " 2. CentOS/Fedora"
echo
echo "Please choose OS: "
read tmp
echo

if test "$tmp" = "2"
then
	os="cent"
	echo "Selected : 2 CentOS/Fedora"
else
	os="deb"
	echo "Selected : 1 Debian/Ubuntu"
fi

echo "--------------------------------------------------------------------"
echo
echo "Select build"
echo
echo " 1. latest(might include beta/rc)"
echo " 2. latest stable"
echo
echo "Please choose build: "
read tmp
echo

if test "$tmp" = "2"
then
	version="$lateststable"
	echo "Latest stable selected: 2 "$lateststable
else
	version="$latest"
	echo "Latest build(stable/beta) selected: 1 "$latest
fi

file="softether-vpnserver-"$version"-linux-"$arch2".tar.gz"
link="http://www.softether-download.com/files/softether/"$version"-tree/Linux/SoftEther_VPN_Server/"$arch"/"$file

if [ ! -s "$file" ]||[ ! -r "$file" ];then
	#remove and redownload empty or unreadable file
	rm -f "$link"
	wget "$link"
elif [ ! -f "file" ];then
	#download if not exist
	wget "$file"
fi

if [ -f "$file" ];then
	tar xzf "$file"
	dir=$(pwd)
	echo "current dir " $dir
	cd vpnserver
	dir=$(pwd)
	echo "changed to dir " $dir
else
	echo "Archive not found. Please rerun this script or check permission."
	break
fi

if [ "$os" -eq "cent" ];then
	yum upgrade
	yum groupinstall "Development Tools" gcc
else
	apt-get update && apt-get upgrade -y && apt-get dist-upgrade -y
	apt-get install htop nload -y
	apt-get install whiptail -y
	apt-get install build-essential -y
fi

# making the executeable and pressing '1' a few times to accept the license agreement.
printf '1\n1\n1\n' | make
cd ..
mv vpnserver /usr/local
dir=$(pwd)
echo "current dir " $dir
cd /usr/local/vpnserver/
dir=$(pwd)
echo "changed to dir " $dir
chmod 600 *
chmod 700 vpnserver
chmod 700 vpncmd

mkdir /var/lock/subsys

touch /etc/init.d/"$initfile"
#need to cat two time to pass varible($initfile) value inside
cat > /etc/init.d/"$initfile" <<EOF
#!/bin/sh
# chkconfig: 2345 99 01
# description: SoftEther VPN Server
DAEMON=/usr/local/vpnserver/$initfile
LOCK=/var/lock/subsys/$initfile
EOF

cat >> /etc/init.d/"$initfile" <<'EOF'
test -x $DAEMON || exit 0
case "$1" in
start)
$DAEMON start
touch $LOCK
;;
stop)
$DAEMON stop
rm $LOCK
;;
restart)
$DAEMON stop
sleep 3
$DAEMON start
;;
*)
echo "Usage: $0 {start|stop|restart}"
exit 1
esac
exit 0
EOF

chmod 755 /etc/init.d/"$initfile"
if [ "$os" -eq "cent" ];then
	chkconfig --add "$initfile" 
	/etc/init.d/"$initfile" start
else
	update-rc.d "$initfile" defaults
	/etc/init.d/"$initfile" start
fi

echo "How do you want to configure your VPN server?"
echo
echo " 1. No configuration as I will do it manually"
echo " 2. vNAT and vDHCP (SecureNAT)"
echo " 3. Local Bridge (dnsmasq as our DHCP server and our own NAT using POSTROUTE/IPTABLES)"
echo
echo "Please choose your configuration: "
read tmp
echo

if test "$tmp" = "1"
then
echo "--------------------------------------------------------------------"
echo "--------------------------------------------------------------------"
echo "Installation done. Hurray!"
echo "Now you may want to change VPN server password."
echo "Run in terminal:"
echo "./vpncmd"
echo "Press 1 to select \"Management of VPN Server or VPN Bridge\","
echo "then press Enter without typing anything to connect to the "
echo "localhost server, and again press Enter without inputting "
echo "anything to connect to server by server admin mode."
echo "Then use command below to change admin password:"
echo "ServerPasswordSet"
echo "Done...."
	echo "Selected : 1 "
elif test "$tmp" = "2"
then
echo "Waiting for 5 seconds to make sure everything has started and is ready to be configured..."
sleep 5
# Most important stuff. This huge ass line creates the Hubs, sets the passwords and whatever. Don't edit it unless you know what you're doing!
printf '1\n127.0.0.1\n\nServerPasswordSet PASSWORD\nHubCreate VPN /PASSWORD:PASSWORD\nHub VPN\nUserCreate VPN\n\n\n\nUserPasswordSet VPN /PASSWORD:PASSWORD\nIPsecEnable\nyes\nyes\nyes\nvpn\nVPN\nSecureNatEnable\nDhcpSet /start:192.168.30.10 /end:192.168.30.200 /mask:255.255.255.0 /expire:7200 /gw:192.168.30.1 /dns:188.165.43.132 /dns2:162.248.164.44 /domain=thenoobstribe.ga /log:yes\nHubDelete DEFAULT' | ./vpncmd
echo "Waiting for 5 seconds to make sure everything has started and is ready to be configured..."
sleep 5
/etc/init.d/vpnserver restart
echo "The installation script -should- be completed without errors. I didn't add any error reporting so uh... should b good (scroll up and check for errors to be sure)!"
echo "Here is the info that you need to connect: "
echo "Admin password: PASSWORD "
echo "Client username: VPN "
echo "Client password: PASSWORD "
echo "DHCP range: 192.168.30.10 - 192.168.30.200 "
echo "DNS servers: 188.165.43.132 and 162.248.164.44 "
echo "All options mentioned above can be changed in the SoftEther VPN Server Manager"
echo "In case of any problem, email Ammar at: ammar@thenoobstribe.ga"
	echo "Selected : 2 "
elif test "$tmp" = "3"
then
#INTERFACE is the outgoing network interface. On OpenVZ it's usually venet0:0, but on KVM/Xen/whatever it's eth0.
INTERFACE=eth0
# some stuff to fetch the IP address of an interface
IP="$(/sbin/ifconfig $INTERFACE | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')"
cd /usr/local/vpnserver

echo "Waiting for 5 seconds to make sure everything has started and is ready to be configured..."
sleep 5
# Most important stuff. This huge ass line creates the Hubs, sets the passwords and whatever. Don't edit it unless you know what you're doing!
printf '1\n127.0.0.1\n\nServerPasswordSet PASSWORD\nHubCreate VPN /PASSWORD:PASSWORD\nHub VPN\nUserCreate VPN\n\n\n\nUserPasswordSet VPN /PASSWORD:PASSWORD\nIPsecEnable\nyes\nyes\nyes\nvpn\nVPN\nBridgeCreate VPN /TAP:yes\nsoft\nSecureNatEnable\nDhcpSet /start:192.168.7.100 /end:192.168.7.200 /mask:255.255.255.0 /expire:7200 /gw:192.168.7.1 /dns:188.165.43.132 /dns2:162.248.164.44 /domain=thenoobstribe.ga /log:yes\nNatDisable\nHubDelete DEFAULT' | ./vpncmd
#/etc/init.d/vpnserver restart
# Stuff for localbridge, to make the transfer speeds faster.
echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/ipv4_forwarding.conf
sysctl --system
iptables -t nat -A POSTROUTING -s 192.168.7.0/24 -j SNAT --to-source $IP
whiptail --msgbox "Due to a bug, you need to press yes twice at the following prompt. Please press any key to continue." 10 100
apt-get install iptables-persistent -y

echo '#!/bin/sh
### BEGIN INIT INFO
# Provides:          vpnserver
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start daemon at boot time
# Description:       Enable Softether by daemon.
### END INIT INFO
DAEMON=/usr/local/vpnserver/vpnserver
LOCK=/var/lock/subsys/vpnserver
TAP_ADDR=192.168.7.1

test -x $DAEMON || exit 0
case "$1" in
start)
$DAEMON start
touch $LOCK
sleep 1
/sbin/ifconfig tap_soft $TAP_ADDR
;;
stop)
$DAEMON stop
rm $LOCK
;;
restart)
$DAEMON stop
sleep 3
$DAEMON start
sleep 1
/sbin/ifconfig tap_soft $TAP_ADDR
;;
*)
echo "Usage: $0 {start|stop|restart}"
exit 1
esac
exit 0' > /etc/init.d/vpnserver
chmod 755 /etc/init.d/vpnserver && /etc/init.d/vpnserver restart

clear
echo "The installation script -should- be completed without errors. I didn't add any error reporting so uh... should b good (scroll up and check for errors to be sure)!"
echo "Here is the info that you need to connect: "
echo "IP address: $IP"
echo "Admin password: PASSWORD "
echo "Client username: VPN "
echo "Client password: PASSWORD "
echo "DHCP range: 192.168.7.100 - 192.168.7.200 "
echo "DNS servers: 188.165.43.132 and 162.248.164.44 "
echo "All options mentioned above can be changed in the SoftEther VPN Server Manager"
echo "In case of any problem, email Ammar at: ammar@thenoobstribe.ga"
	echo "Selected : 3 "
else #default if non selected
echo "--------------------------------------------------------------------"
echo "--------------------------------------------------------------------"
echo "Installation done. Hurray!"
echo "Now you may want to change VPN server password."
echo "Run in terminal:"
echo "./vpncmd"
echo "Press 1 to select \"Management of VPN Server or VPN Bridge\","
echo "then press Enter without typing anything to connect to the "
echo "localhost server, and again press Enter without inputting "
echo "anything to connect to server by server admin mode."
echo "Then use command below to change admin password:"
echo "ServerPasswordSet"
echo "Done...."
	echo "Selected : 1 "
fi
	

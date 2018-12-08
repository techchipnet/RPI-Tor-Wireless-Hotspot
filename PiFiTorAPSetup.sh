/#!/bin/sh
#This script create for auto setup Raspberry Pi 3 Tor Access Point
# Author - Anil Parashar
# www.techchip.net
# www.youtube.com/techchipnet
clear
/bin/cat <<'Techchip'
 _______        _      _____ _     _       
|__   __|      | |    / ____| |   (_)      
   | | ___  ___| |__ | |    | |__  _ _ __  
   | |/ _ \/ __| '_ \| |    | '_ \| | '_ \ 
   | |  __/ (__| | | | |____| | | | | |_) |
   |_|\___|\___|_| |_|\_____|_| |_|_| .__/ 
                                    | |    
    Your True Tech Navigator        |_|.net    
www.techchip.net | youtube.com/techchipnet	
Techchip
if [ $? != 0 ] 
then
  echo "This program must be run as root. run again as root"
  exit 1
fi
read -r -p "This script make change your system's network configurations files, I am not responsible for any damage, Do you agree with it? [y/N] " check

case "$check" in
[nN][oO]|[nN])
echo "Thank you!! have a nice day ;) don't forget subscribe TechChip Youtube Channel"
exit 1
;;
*)
echo ""
echo "First you need to be update your system"
read -p "Do you want update your system (Highly Recommended) (Y/N)?" ans

if [ $ans = "y" ] || [ $ans = "Y" ]
then
  echo "Updating package index.."
  sudo apt-get update -y
  echo "Updating old packages.."
  sudo apt-get upgrade -y
fi
echo ""
echo "Downloading and installing necessary packages.."
sudo apt install hostapd dnsmasq tor -y
echo ""
echo "Checking..."
if [ ! -f /etc/tor/torrc ]
        then
                sudo apt update --fix-missing
                sudo apt install hostapd dnsmasq tor -y
fi
echo ""
echo "configuration start..."
echo ""
read -p "Enter your PIFI SSID: " apname
read -p "Enter password (password must be >= 8 char): " appass
if [ ! $apname ]
then
apname="PiFiTorAP"
echo ""
echo "SSID can't be blank now your SSID is :" $apname
fi
if [ ${#appass} -lt 8 ]
then
appass="techchipnet"
echo ""
echo "Your password length is short now your WiFi password is : " $appass
fi
sudo cat > hostapd.conf <<EOF
# WiFi access point configuration
interface=wlan0
driver=nl80211
hw_mode=g
channel=6
ieee80211n=1
wmm_enabled=0
macaddr_acl=0
ignore_broadcast_ssid=0
auth_algs=1
wpa=2
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
ssid=$apname
wpa_passphrase=$appass

EOF
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq
sudo mv hostapd.conf /etc/hostapd/hostapd.conf
repl2="DAEMON_CONF\=\"\/etc\/hostapd\/hostapd\.conf\""
sudo sed -i "/#DAEMON_CONF=\"\"/ s/#DAEMON_CONF=\"\"/$repl2/" /etc/default/hostapd 
repl1="DAEMON_CONF\=\/etc\/hostapd\/hostapd.conf"
sudo sed -i "/$repl1/! s/DAEMON_CONF=/$repl1/" /etc/init.d/hostapd
if [ ! -f /etc/dhcpcd.conf.oldtc ]
        then
        sudo mv /etc/dhcpcd.conf /etc/dhcpcd.conf.oldtc
        else
        sudo rm /etc/dhcpcd.conf
fi
sudo cp config/dhcpcd.conf /etc/
sudo systemctl restart dhcpcd
if [ ! -f /etc/dnsmasq.conf.oldtc ]
        then
        sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.oldtc
        else
        sudo rm /etc/dnsmasq.conf
fi
sudo cp config/dnsmasq.conf /etc/dnsmasq.conf
if [ ! -f /etc/sysctl.conf.oldtc ]
        then
        sudo cp /etc/sysctl.conf /etc/sysctl.conf.oldtc
fi
repl3="net\.ipv4\.ip_forward=1"
sudo sed -i "/#$repl3/ s/#$repl3/$repl3/" /etc/sysctl.conf
repl="iptables-restore \< \/etc\/iptables\.ipv4\.nat"
sudo sed -i "20 s/exit 0/$repl\nexit 0/" /etc/rc.local
if [ ! -f /etc/tor/torrc.oldtc ]
        then
        sudo mv /etc/tor/torrc /etc/tor/torrc.oldtc
        else
        sudo rm /etc/tor/torrc
fi
sudo cat /etc/tor/torrc.oldtc config/torrc.conf >> torrc
sudo mv torrc /etc/tor/torrc
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 22 -j REDIRECT --to-ports 22
sudo iptables -t nat -A PREROUTING -i wlan0 -p udp --dport 53 -j REDIRECT --to-ports 53
sudo iptables -t nat -A PREROUTING -i wlan0 -p tcp --syn -j REDIRECT --to-ports 9040
sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"
sudo touch /var/log/tor/notices.log
sudo chown debian-tor /var/log/tor/notices.log
sudo chmod 644 /var/log/tor/notices.log
sudo service hostapd start
sudo service dnsmasq start
sudo service tor start
sudo update-rc.d tor enable
echo ""
echo "Configuration is completed"
echo "Reboot your system for start PiFiTorAP(Raspberry Pi Tor Access Point)"
echo ""
echo "Don't forget to subscribe TechChip Youtube channel"
echo ""
read -p "Press [Enter] key to reboot or terminate here, press (ctrl+c).." chk
sudo reboot
;;
esac

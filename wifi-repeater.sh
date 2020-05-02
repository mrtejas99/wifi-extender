#!/bin/bash

read -p 'Router SSID: ' ssid
read -p 'Router Password: ' pass
echo "SSID is $ssid and Password is $pass, press y to confirm "
read option
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
else
    echo "User interection is not needed anymore. Please wait while the scripts finishes execution"
    apt update -y
    apt upgrade -y
    systemctl mask networking.service dhcpcd.service
    mv /etc/network/interfaces /etc/network/interfaces~
    sed -i '1i resolvconf=NO' /etc/resolvconf.conf
    systemctl enable systemd-networkd.service systemd-resolved.service
    ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

   cat > /etc/wpa_supplicant/wpa_supplicant-wlan0.conf <<EOF
country=IN
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="RPi-AP"
    mode=2
    key_mgmt=WPA-PSK
    psk="raspberry"
    frequency=2412
}
EOF

    chmod 600 /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
    systemctl disable wpa_supplicant.service
    systemctl enable wpa_supplicant@wlan0.service

    cat > /etc/wpa_supplicant/wpa_supplicant-wlan1.conf <<EOF
country=IN
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="Asus RT-AC5300"
    psk="12345678"
}
EOF

    chmod 600 /etc/wpa_supplicant/wpa_supplicant-wlan1.conf
    systemctl disable wpa_supplicant.service
    systemctl enable wpa_supplicant@wlan1.service


    cat > /etc/systemd/network/08-wlan0.network <<EOF
    [Match]
    Name=wlan0
    [Network]
    Address=192.168.7.1/24
    # IPMasquerade is doing NAT
    IPMasquerade=yes
    IPForward=yes
    DHCPServer=yes
    [DHCPServer]
    DNS=84.200.69.80 1.1.1.1
EOF
    cat > /etc/systemd/network/12-wlan1.network <<EOF
    [Match]
    Name=wlan1
    [Network]
    DHCP=yes
EOF
    echo "Process completed successfully, Please reboot"
fi

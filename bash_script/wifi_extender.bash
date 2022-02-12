#!/usr/bin/bash


# 30/01/2021
# Raspberry pi wifi extender
# Make sure you have 2 wireless interfaces
# Based on https://github.com/mrtejas99/wifi-extender


# Script must run as root
if [[ $EUID -gt 0 ]]; then # we can compare directly with this syntax.
    echo "Please run as root/sudo"
    exit 1
fi



##### CONFIGURATIONS TO BE CHANGED ####
WLAN0="wlan0"
WLAN1="wlan1"

# Config files, don't change
wp0conf="/etc/wpa_supplicant/wpa_supplicant-wlan0.conf"
ws_wlan1="/etc/wpa_supplicant/wpa_supplicant-wlan1.conf"
wlan0_network="/etc/systemd/network/08-wlan0.network"
wlan1_network="/etc/systemd/network/12-wlan1.network"



interactive_configurations() {
    # Ask the user to input the correct configurations for ssid(s) and passwords
    read -p 'Please enter the name (SSID) of the network you wish to connect the pi: ' ORIGINAL_SSID
    while read -p "Please enter the password of the wifi network: " ORIGINAL_PASS && [ ${#ORIGINAL_PASS} -lt 8 ]; do
        echo "Please enter password with more than 8 characters."
    done

    read -p 'Please enter the name (SSID) of the new network you want to create:' NEW_SSID
    while read -p "Please enter the password of the wifi network: " NEW_PASS && [ ${#NEW_PASS} -lt 8 ]; do
        echo "Please enter password with more than 8 characters."
    done
}

generate_wpa2_psk() {
    wpa_passphrase $1 $2 |grep -E 'psk' | grep -v "#psk" | cut -d '=' -f 2
}

validate_configurations() {
    echo
    echo
    echo
    echo "Current configurations: "
    echo
    echo "WLAN0: $WLAN0"
    echo "WLAN1: $WLAN1"
    echo "ORIGINAL_SSID: $ORIGINAL_SSID"
    echo "ORIGINAL_PASS: $ORIGINAL_PASS"
    echo "NEW_SSID: $NEW_SSID"
    echo "NEW_PASS: $NEW_PASS"

    while true; do
        read -p "Do you want to continue? " yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit 0;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}


check_interfaces() {
    echo "Checking interfaces..."
    output=$(/sbin/iw dev)
    if [[ $output =~ $WLAN0 && $output =~ $WLAN1 ]]; then
        echo "found interfaces... continue..."
    else
        echo "Not found interfaces. check them with iwconfig"
        exit 1
    fi
}

setup_systemd_networkd() {
    systemctl mask networking.service dhcpcd.service
    mv /etc/network/{interfaces,interfaces~} # Backup file
    cp /etc/{resolv.conf,resolv.conf~}
    sed -i '1i resolvconf=NO' /etc/resolvconf.conf
    systemctl enable systemd-networkd.service systemd-resolved.service
    ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
}


config_wpsup() {
    {
        echo "country=US"
        echo "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev"
        echo "update_config=1"
        echo "network={"
        echo '  ssid="'${NEW_SSID}'"'
        echo "  mode=2"
        echo "  key_mgmt=WPA-PSK"
        echo "  proto=RSN"
        echo "  pairwise=CCMP"
        echo "  group=CCMP"
        echo '  psk='`generate_wpa2_psk $NEW_SSID $NEW_PASS`
        echo "  frequency=2412"
        echo "}"
    } > $wp0conf
    chmod 600 $wp0conf
    # Restart wpa_supplicant service
    systemctl disable wpa_supplicant.service
    systemctl enable wpa_supplicant@wlan0.service
}



setup_wlan1_client() {
    {
        echo "country=US"
        echo "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev"
        echo "update_config=1"
        echo "network={"
        echo '  ssid="'$ORIGINAL_SSID'"'
        echo '  psk='`generate_wpa2_psk $ORIGINAL_SSID $ORIGINAL_PASS`
        echo "}"
    } > $ws_wlan1

    chmod 600 $ws_wlan1
    systemctl disable wpa_supplicant.service
    systemctl enable wpa_supplicant@wlan1.service
}



configure_interfaces() {
    {
        echo "[Match]"
        echo "Name=$WLAN0"
        echo "[Network]"
        echo "Address=10.0.0.1/24"
        echo "IPMasquerade=yes"
        echo "IPForward=yes"
        echo "DHCPServer=yes"
        echo "[DHCPServer]"
        echo "DNS=1.1.1.1"
    } > $wlan0_network


    {
        echo "[Match]"
        echo "Name=$WLAN1"
        echo "[Network]"
        echo "DHCP=yes"
    } > $wlan1_network
}



install() {
    echo "Installing..."
    interactive_configurations
    validate_configurations
    check_interfaces
    echo "setup_systemd_networkd..."
    setup_systemd_networkd
    echo "config_wpsup"
    config_wpsup
    echo "setup_wlan1_client..."
    setup_wlan1_client
    echo "configure_interfaces"
    configure_interfaces
    echo "done. rebooting..."
    sleep 2
    /sbin/reboot
}

uninstall() {
    echo "Uninstalling..."
    rm -rf $wp0conf $ws_wlan1 $wlan0_network $wlan1_network
    systemctl unmask networking.service dhcpcd.service
    mv /etc/network/{interfaces~,interfaces} # restore file
    systemctl disable systemd-networkd.service systemd-resolved.service wpa_supplicant@wlan0.service wpa_supplicant@wlan1.service
    systemctl enable wpa_supplicant.service
    rm -rf /etc/resolv.conf
    cp /etc/{resolv.conf~,resolv.conf}
    echo "done. rebooting..."
    sleep 2
    /sbin/reboot
}



# Starting point
echo "Welcome!"
echo "This script will turn your Raspberry pi into wifi extender! (repeater)"
echo "Please choose your plan"
echo "1. Install / reinstall"
echo "2. Uninstall"
echo "3. cancel"
while true; do
    read -p "Please choose: " answer
    case $answer in
        [1]* ) install; break;;
        [2]* ) uninstall; break;;
        [3]* ) exit 0;;
        * ) echo "Please answer the correct number";;
    esac
done

#!/usr/bin/env bash
#####################################################
#
# Quickstart script to configure basic wireless
# parameters for wireless console mode
#
# Note: the script assumes we are using wlan0
#
#####################################################
if [ $EUID -ne 0 ]; then
   echo "This script must be run as root (e.g. use 'sudo')" 
   exit 1
fi

set -e

SSID=""
PSK=""
CHANNEL=
INTERACE="wlan0"
CONFIG_FILE=/etc/wlanpi-wconsole/conf/hostapd.conf
STATUS_FILE="/etc/wlanpi-state"

# default values
SSID_DEFAULT=wifi_console
KEY_DEFAULT=wifipros
COUNTRYCODE_DEFAULT=US
CHANNEL_DEFAULT=6

# global vars
SSID=
KEY=
COUNTRYCODE=
CHANNEL=

get_ssid () {
    read -p "Please enter the network name of the wireless connection [$SSID_DEFAULT] : " SSID
    if [ "$SSID" == "" ]; then 
        SSID=$SSID_DEFAULT;
    fi
    return
}

get_psk () {
    # prompt for psk 
    read -p "Enter the network key [$KEY_DEFAULT]: " KEY
    if [ "$KEY" == "" ]; then 
        KEY=$KEY_DEFAULT;
    fi
    return
}

get_country () {
    # prompt for psk 
    read -p "Enter the two letter code for your country [$COUNTRYCODE_DEFAULT]: " COUNTRYCODE
    if [ "$COUNTRYCODE" == "" ]; then 
        COUNTRYCODE=$COUNTRYCODE_DEFAULT;
    fi
    return
}

get_channel () {
    # prompt for psk 
    read -p "Please enter the channel to use for the wireless connection (1-11) [$CHANNEL_DEFAULT] : " CHANNEL
    if [ "$CHANNEL" == "" ]; then 
        CHANNEL=$CHANNEL_DEFAULT;
    fi
    return
}

#####################################################

main () {

  # check that the WLAN Pi is in classic mode
  PI_STATUS=`cat $STATUS_FILE | grep 'classic'` || true
  if  [ -z "$PI_STATUS" ]; then
     cat <<FAIL
####################################################
Failed: WLAN Pi is not in classic mode.

Please switch to classic mode and re-run this script

(exiting...)
#################################################### 
FAIL
     exit 1
  fi

    # set up the wireless connection configuration
    clear
    cat <<INTRO
#####################################################

This script will configure the wireless link for 
the WLAN Pi wireless console feature.

You will need to provide a network name, shared key
and channel number. The network name will be the 
name advertised by the wireless console that you
will connect to. The key will be used to secure the 
wireless connection.

You will also need to provide a two letter country 
code for your geographic region to ensure compliance 
with local regulations (e.g. US, GB, DE, CA etc.)

Only the 2.4GHz band is currently available for the 
wireless connection, so you must choose a channel
between 1 - 11.

(Note: there is no validation of values entered, so
if you enter bad values, things will not work...)

##################################################### 
INTRO

    read -p "Do you wish to continue? (y/n) : " yn

    if [[ ! $yn =~ [yY] ]]; then
        echo "OK, exiting."
        exit 1
    fi

    # Select PSK or PEAP
    clear
    cat <<SEC
#####################################################

            Wireless Configuration

Please enter the network name, network key, country
code and channel number as prompted below (remember,
use appropriate, correct values if you want things 
to work)

(Default values are shown in square brackets and will
be used if no value is entered)

##################################################### 
SEC

    get_ssid
    get_psk
    get_country
    get_channel
    
    echo "Writing supplied configuration values..."

    sed -i "s/^ssid=.*$/ssid=$SSID/" $CONFIG_FILE
    sed -i "s/^wpa_passphrase=.*$/wpa_passphrase=$KEY/" $CONFIG_FILE
    sed -i "s/^country_code=.*$/country_code=$COUNTRYCODE/" $CONFIG_FILE
    sed -i "s/^channel=.*$/channel=$CHANNEL/" $CONFIG_FILE
    echo "Wireless link configured."
    sleep 1


    cat <<COMPLETE

#####################################################

 Quickstart script completed. If the script completed
 with no errors, you may now switch in to wireless
 console mode.

 Would you like me to switch your WLAN Pi in to
 wireless console mode (this will cause a reboot?

##################################################### 
COMPLETE
    
    read -p "Would to like switch to wireless console mode? (y/n) : " yn

    case $yn in
        y|Y ) echo "Switching...";;
        *   ) echo "OK, you can switch to wireless console mode later using the front panel buttons. We're all done. Bye!"; exit 0;
    esac

    echo "(After a reboot, the WAN Pi will come back up in wireless console mode.)"
    /usr/sbin/wconsole_switcher on

    return
}

########################
# main
########################
main
exit 0

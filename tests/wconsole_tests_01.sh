#!/bin/bash
#
# wconsole test suite - all tests to be peformed from the CLI 
# of the WLAN Pi while switched in to wconsole mode
#
#

##########################
# User configurable vars
##########################
MODULE=wconsole
VERSION=1.4.0
COMMENTS="wconsole test suite to verify files & processes"
SCRIPT_NAME=$(basename $0)

# Tests log file
LOG_FILE="${SCRIPT_NAME}_results.log"
# WLAN Pi status file (hostspot, wiperf etc...)
STATUS_FILE="/etc/wlanpi-state"


###########################
# script global vars
###########################
# initialize tests passed counter
tests_passed=0
# initialize tests failed counter
tests_failed=0

################
# root check
################
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

##############################################
# Helper functions - see docs at end of file
##############################################

summary () {
  tests_completed=$((tests_passed + tests_failed))
  echo ""
  echo "-----------------------------------"
  echo " Total tests: $tests_completed"
  echo " Number tests passed: $tests_passed"
  echo " Number tests failed:  $tests_failed"
  echo "-----------------------------------"
  echo ""
}

inc_passed ()     { tests_passed=$((tests_passed + 1));  }
inc_failed ()     { tests_failed=$((tests_failed + 1));  }

info ()    { echo -n "(info) Test: $1" | tee -a $LOG_FILE;  }
info_n ()  { echo "(info) Test: $1" | tee -a $LOG_FILE;  }
comment () { echo $1 | tee -a $LOG_FILE; }

pass ()    { inc_passed; echo " $1  (pass)" | tee -a $LOG_FILE; }
fail ()    { inc_failed; echo " $1  (fail) <--- !!!!!!" | tee -a $LOG_FILE; }

check ()     { if [[ $1 ]];   then pass; else fail; fi; }
check_not () { if [[ ! $1 ]]; then pass; else fail; fi; }

file_exists ()    { info "Checking file exists: $1"; if [[ -e $1 ]]; then pass; else fail; fi; }
dir_exists ()     { info "Checking directory exists: $1"; if [[ -d $1 ]]; then pass; else fail; fi; }
symlink_exists () { info "Checking symlink exists: $1"; if [[ -L $1 ]]; then pass; else fail; fi; }
symlink_not () { info "Checking file is not symlink: $1"; if [[ ! -L $1 ]]; then pass; else fail; fi;  }
check_process ()  { info "Checking process running: $1"; if [[ `pgrep $1` ]]; then pass; else fail; fi; }
check_systemctl () { info "Checking systemctl running: $1"; if [[ `systemctl status $1 | grep 'active (running)'` ]]; then pass; else fail; fi; }

########################################
# Test rig overview
########################################
echo "\

=======================================================
Test rig description:

  1. WLAN Pi running image to be tested
  2. Supported wireless NIC card is operational
  3. WLAN Pi is switched in to wconsole mode
  4. wconsole config files are default
  5. Run tests by joining SSID 'wifi_console' (key = 'wifipros' ) 
  6. SSH to the WLAN Pi and run this test script:
      /etc/wlanpi-wconsole/tests/wconsole_tests.01.sh

=======================================================" | tee $LOG_FILE

########################################
# Test suite
########################################

run_tests () {

  comment ""
  comment "###########################################"
  comment "  Running $MODULE test suite"
  comment "###########################################"
  comment ""

  # check what state the WLAN Pi is in
  info "Checking current mode is wconsole"
  check `cat $STATUS_FILE | grep 'wconsole'`

  # check we have directories expected
  dir_exists "/etc/wlanpi-wconsole"

  # check various files exist
  file_exists "/etc/wlanpi-wconsole/conf/hostapd.conf"
  file_exists "/etc/wlanpi-wconsole/conf/ser2net.conf"
  file_exists "/etc/wlanpi-wconsole/default/isc-dhcp-server"
  file_exists "/etc/wlanpi-wconsole/default/ufw"
  file_exists "/etc/wlanpi-wconsole/dhcp/dhcpd.conf"
  file_exists "/etc/wlanpi-wconsole/network/interfaces"
  file_exists "/etc/wlanpi-wconsole/sysctl/sysctl.conf"
  file_exists "/etc/wlanpi-wconsole/ufw/before.rules"
  file_exists "/usr/sbin/wconsole_switcher"

  # check file symbolic links exist
  symlink_exists "/etc/network/interfaces"
  symlink_exists "/etc/default/isc-dhcp-server"
  symlink_exists "/etc/dhcp/dhcpd.conf"
  symlink_exists "/etc/network/interfaces"
  symlink_exists "/etc/ser2net.conf"
  symlink_exists "/etc/hostapd.conf"
  symlink_exists "/etc/sysctl.conf"
  symlink_exists "/etc/default/ufw"
  symlink_exists "/etc/ufw/before.rules"


  # check hostapd running 
  check_process "hostapd"

  # check ser2net running
  check_process "ser2net"

  # check dhcpd running
  check_process "dhcpd"

  # check wlan port is in correct state (type AP)
  info "Checking wlan adapter in type AP"
  check `iw dev wlan0 info | grep "type AP"`

  # check wlan0 up and running with correct IP address
  wlan0_ip=172.16.43.1
  info "Checking wlan0 has correct IP (${wlan0_ip})"
  check `ifconfig wlan0 | grep $wlan0_ip`

  # check expected ports open
  info_n "Checking selection of expected network ports open"
  port_array=(:9600 :9601 :9602 :9603 :9604 :9605 :9606 :9607 :9608)
  for port in "${port_array[@]}"; do
    if [[ `netstat -a | grep $port` ]]; then pass $port; else fail $port; fi
  done

  # check ufw port ranges are configured
  info_n "Checking expected ufw port ranges are open"
  range_array=(2400:2408/tcp 4800:4808/tcp 9600:9608/tcp 19200:19208/tcp 11520:11528/tcp 2000:2008/tcp)
  for range in "${range_array[@]}"; do
    if [[ `ufw status | grep $range` ]]; then pass $range; else fail $range; fi
  done

  # Print test run results summary
  summary

  comment ""
  comment "###########################################"
  comment "  End of $MODULE test suite"
  comment "###########################################"
  comment ""

}

########################################
# main
########################################

case "$1" in
  -v)
        echo ""
        echo "Test script version: $VERSION"
        echo $COMMENTS
        echo ""
        exit 0
        ;;
  -h)
        echo "Usage: $SCRIPT_NAME [ -h | -v ]"
        echo ""
        echo "  $SCRIPT_NAME -v : script version"
        echo "  $SCRIPT_NAME -h : script help"
        echo "  $SCRIPT_NAME    : run test suite"
        echo ""
        exit 0
        ;;
  *)
        run_tests
        exit $tests_failed
        ;;
esac

# should never reach here, but just in case....
exit 1

<< 'HOWTO'

#################################################################################################################

Test Utility Documentation
--------------------------

 This script uses a set of useful utilities to simplify running a series of 
 tests from this bash script. The syntax of the utilities is shown below:

 inc_passed: increment the test-passed counter (global var 'tests_passed')
 inc_failed: increment the test-failed counter (global var 'tests_failed')
 info: pre-prend the text in $1 with "info" and send to stdout & the log file (no CR)
 info_n: pre-prend the text in $1 with "info" and send to stdout & the log file (inc CR after msg)
 pass: write a "pass" msg to stdout & the log file, with optional additional msg in $1 (var passed to function)
 fail: write a "fail" msg to stdout & the log file, with optional additional msg in $1 (var passed to function)
 comment: output raw text supplied in $1 to std & log file

 check: call pass() if condition passed is true (can inc option msg via $1), otherwise fail()
 check_not: call pass() if condition passed is false (can inc option msg via $1), otherwise fail()

 file_exists: call pass() if file name passed via $1 exists, else call fail()
 dir_exists: call pass() if dir name passed via $1 exists, else call fail()
 symlink_exists: call pass() if file name passed via $1 is a symlink, else call fail()
 symlink_not: call pass() if file name passed via $1 is not symlink, else call fail()
 check_process: call pass() if process name passed via $1 is running, else call fail()
 check_systemctl: call pass() if service name passed via $1 is running, else call fail()

#################################################################################################################
HOWTO

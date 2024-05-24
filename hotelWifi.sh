#!/bin/bash

# Check if macchanger is installed
if ! command -v macchanger >/dev/null 2>&1 ; then
    echo "macchanger not found!"
    exit 1
else
    echo "macchanger found!"
fi
echo ''

# Check if airodump-ng is installed
if ! command -v airodump-ng >/dev/null 2>&1 ; then
    echo "airodump-ng not found!"
    exit 1
else
    echo "airodump-ng found!"
fi
echo ''

# Display network interfaces
sudo ip link show

# Prompt the user to enter a network interface name
read -p 'Enter Network interface name: ' NIC

# Check if the entered interface exists
if ! ip link show "$NIC" >/dev/null 2>&1; then
    echo "Interface $NIC does not exist!"
    exit 1
fi

# Set the specified interface down
echo "Setting $NIC interface down..."
sudo ifconfig "$NIC" down

# Set the interface to monitor mode
echo "Setting $NIC interface to monitor mode..."
sudo iwconfig "$NIC" mode monitor

# Bring the interface up
echo "Bringing $NIC interface up..."
sudo ifconfig "$NIC" up

# Display the current configuration of the interface
echo "Current configuration of $NIC interface:"
sudo iwconfig "$NIC"

# Run airodump-ng to capture network data for 2 minutes
echo "Running airodump-ng to capture network data..."
sudo timeout 2m airodump-ng -w output --output --format csv "$NIC" &

# Sleep for a moment to ensure airodump-ng starts capturing
sleep 5

# Run arp-scan to find MAC addresses on the network
echo "Scanning for MAC addresses on the network..."
sudo arp-scan --interface="$NIC" --localnet

# Monitor bandwidth usage with iftop
echo "Monitoring bandwidth usage on $NIC interface..."
sudo iftop -i "$NIC"

# Prompt the user to enter a MAC address to change
read -p 'Enter MAC address you want to use (Format "xx:xx:xx:xx:xx:xx"): ' MAC

# Change the MAC address of the interface
echo "Changing MAC address of $NIC interface to $MAC..."
sudo macchanger -m "$MAC" "$NIC"

# Set the interface back to managed mode
echo "Setting $NIC interface back to managed mode..."
sudo iwconfig "$NIC" mode managed

# Bring the interface up again
echo "Bringing $NIC interface up again..."
sudo ifconfig "$NIC" up

# Display the updated configuration
echo "Updated configuration of $NIC interface:"
iwconfig "$NIC"
ifconfig "$NIC"


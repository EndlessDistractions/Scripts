#!/bin/bash

sudo ip link show

read -p 'Enter Network interface name. >>> ' NIC

sudo ifconfig $NIC down

sudo iwconfig $NIC mode monitor

sudo ifconfig $NIC up

sudo iwconfig $NIC

sudo timeout 2m airodump-ng $NIC

sudo ifconfig $NIC down

read -p 'Enter MAC address you want to use. Format "xx:xx:xx:xx:xx:xx">>> ' MAC

sudo macchanger -m $MAC $NIC

sudo iwconfig $NIC mode managed

sudo ifconfig $NIC up

iwconfig $NIC
ifconfig $NIC

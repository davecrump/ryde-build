#!/bin/bash

reset

printf "Ryde System Information\n"
printf "=======================\n"

printf "\nIP Address: "
ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'

printf "\nSD Card Type: "
cat /sys/block/mmcblk0/device/name

printf "\nSD Card Serial: "
cat /sys/block/mmcblk0/device/cid

printf "\nCurrent Installed Ryde Version: "
cat /home/pi/ryde-build/installed_version.txt

printf "\nCurrent CPU "
vcgencmd measure_temp

printf "\nCurrent Voltage and Temp Status (Should be \"throttled=0x0\"): "
vcgencmd get_throttled


printf "\n\nPress any key to return to the main menu\n"
read -n 1
exit

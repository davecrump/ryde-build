#!/bin/bash

reset

printf "Ryde System Information\n"
printf "=======================\n\n"

printf "\nIP Address: "
ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'

printf "\nSD Card Type: "
cat /sys/block/mmcblk0/device/name

printf "\nCurrent Installed Ryde Version: "
cat /home/pi/ryde-build/installed_version.txt

printf "\nCurrent CPU "
vcgencmd measure_temp


printf "\n\nPress any key to return to the main menu\n"
read -n 1
exit

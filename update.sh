#!/bin/bash

# Created by davecrump 20200714 for Ryde on Buster Raspios
# Updated for version 202012250

echo
echo "----------------------------------------"
echo "----- Updating Ryde Receiver System-----"
echo "----------------------------------------"
echo

# Stop the receiver to allow the update
sudo killall python3 >/dev/null 2>/dev/null
sleep 0.3
if pgrep -x "python3" >/dev/null
then
  sudo killall -9 python3 >/dev/null 2>/dev/null
fi

## Check which update to load
GIT_SRC_FILE=".ryde_gitsrc"
if [ -e ${GIT_SRC_FILE} ]; then
  GIT_SRC=$(</home/pi/${GIT_SRC_FILE})
else
  GIT_SRC="BritishAmateurTelevisionClub"
fi

## If previous version was Dev (davecrump), load production by default
if [ "$GIT_SRC" == "davecrump" ]; then
  GIT_SRC="BritishAmateurTelevisionClub"
fi

if [ "$1" == "-d" ]; then
  echo "Overriding to update to latest development version"
  GIT_SRC="davecrump"
fi

if [ "$GIT_SRC" == "BritishAmateurTelevisionClub" ]; then
  echo "Updating to the latest Production Ryde build";
elif [ "$GIT_SRC" == "davecrump" ]; then
  echo "Updating to the latest development Ryde build";
else
  echo "Updating to the latest ${GIT_SRC} development Ryde build";
fi

cd /home/pi

PATHUBACKUP="/home/pi/user_backups"
mkdir "$PATHUBACKUP" >/dev/null 2>/dev/null  

# Note previous version number
cp -f -r /home/pi/ryde-build/installed_version.txt "$PATHUBACKUP"/prev_installed_version.txt

# Make a safe copy of the Config file in "$PATHUBACKUP" to restore at the end

cp -f -r /home/pi/ryde/config.yaml "$PATHUBACKUP"/config.yaml >/dev/null 2>/dev/null

# And capture the RC protocol in the rx.sh file:
cp -f -r /home/pi/ryde-build/rx.sh "$PATHUBACKUP"/rx.sh

echo
echo "-------------------------------------------------"
echo "----- Updating the System Software Packages -----"
echo "-------------------------------------------------"
echo

sudo dpkg --configure -a     # Make sure that all the packages are properly configured
sudo apt-get clean           # Clean up the old archived packages
sudo apt-get update          # Update the package list

# --------- Update Packages ------

sudo apt-get -y dist-upgrade # Upgrade all the installed packages to their latest version

# --------- Install new packages as Required ---------

sudo apt-get -y install python3-gpiozero  # for GPIOs

# --------- Overwrite and compile all the software components -----

# Download the previously selected version of Ryde Build
echo
echo "----------------------------------------"
echo "----- Updating Ryde Build Utilities-----"
echo "----------------------------------------"
echo
rm -rf /home/pi/ryde-build
wget https://github.com/${GIT_SRC}/ryde-build/archive/master.zip
unzip -o master.zip
mv ryde-build-master ryde-build
rm master.zip
cd /home/pi

# Build the LongMynd version packaged with ryde-build
echo
echo "------------------------------------------"
echo "----- Updating the LongMynd Receiver -----"
echo "------------------------------------------"
echo
rm -rf /home/pi/longmynd
cp -r ryde-build/longmynd/ longmynd/
cd longmynd
make
cd /home/pi

# Download and compile pyDispmanx
echo
echo "--------------------------------"
echo "----- Updating pyDispmanx -----"
echo "--------------------------------"
echo
wget https://github.com/eclispe/pyDispmanx/archive/master.zip
unzip -o master.zip
rm -rf pydispmanx
mv pyDispmanx-master pydispmanx
rm master.zip
cd pydispmanx
python3 setup.py build_ext --inplace

cd /home/pi

# Download the previously selected version of Ryde Player
echo
echo "--------------------------------"
echo "----- Updating Ryde Player -----"
echo "--------------------------------"
echo
rm -rf /home/pi/ryde
wget https://github.com/${GIT_SRC}/rydeplayer/archive/master.zip
unzip -o master.zip
mv rydeplayer-master ryde
rm master.zip
cd /home/pi/ryde

cp /home/pi/pydispmanx/pydispmanx.cpython-37m-arm-linux-gnueabihf.so pydispmanx.cpython-37m-arm-linux-gnueabihf.so

cd /home/pi

# Download and overwrite the latest remote control definitions and images
echo
echo "----------------------------------------------"
echo "----- Downloading Remote Control Configs -----"
echo "----------------------------------------------"
echo

rm -rf /home/pi/RydeHandsets/definitions
rm -rf /home/pi/RydeHandsets/images

git clone -b definitions https://github.com/${GIT_SRC}/RydeHandsets.git RydeHandsets/definitions
git clone -b images https://github.com/${GIT_SRC}/RydeHandsets.git RydeHandsets/images

# Check that Operating System Changes have been applied
echo
echo "--------------------------------------------"
echo "----- Configuring the Operating System -----"
echo "--------------------------------------------"
echo

# Check that the RPi Audio Jack volume is being set
grep -q "amixer set Headphone" ~/.bashrc
if [ $? -ne 0 ]; then  #  Not being set, so enter the code
  echo  >> ~/.bashrc
  echo "# Set RPi Audio Jack volume" >> ~/.bashrc
  echo  "amixer set Headphone 0db >/dev/null 2>/dev/null" >> ~/.bashrc
fi

# If not already done, increase GPU memory so that it copes with 4k displays
# First check if "#gpu_mem=128" is in  /boot/config.txt
grep -q "#gpu_mem=128" /boot/config.txt
if [ $? -ne 0 ]; then  #  "#gpu_mem=128" is not there, so check if "gpu_mem=128" is there
  grep -q "gpu_mem=128" /boot/config.txt
  if [ $? -ne 0 ]; then  # "gpu_mem=128" is not there, so append the commented statement
    sudo bash -c 'echo " " >> /boot/config.txt '
    sudo bash -c 'echo "# Increase GPU memory for 4k displays" >> /boot/config.txt '
    sudo bash -c 'echo "gpu_mem=128" >> /boot/config.txt '
    sudo bash -c 'echo " " >> /boot/config.txt '
  fi
else  ## "#gpu_mem=128" is there, so amend it to read "gpu_mem=128"
  sudo sed -i 's/^#gpu_mem=128/gpu_mem=128/' /boot/config.txt 
fi

#echo
#echo "---------------------------------------------"
#echo "----- Restoring the User's Config Files -----"
#echo "---------------------------------------------"
#echo

grep -q "FREQ: null" "$PATHUBACKUP"/config.yaml
if [ $? == 0 ]; then # User's config file is latest version, so simply copy back
  cp -f -r "$PATHUBACKUP"/config.yaml /home/pi/ryde/config.yaml >/dev/null 2>/dev/null
else # User's config file needs updating, so copy master and reset remote control

  cp /home/pi/ryde-build/config.yaml /home/pi/ryde/config.yaml

  # Check for previous remote type
  grep -q "virgin" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "virgin" 1
    sed -i "/handsets:/{n;s/.*/        - virgin/}" /home/pi/ryde/config.yaml
  fi
  grep -q "nebula_usb" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "nebula_usb" 2
    sed -i "/handsets:/{n;s/.*/        - nebula_usb/}" /home/pi/ryde/config.yaml
  fi
  grep -q "hd-dvb-t2-s2-rx" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "hd-dvb-t2-s2-rx" 3
    sed -i "/handsets:/{n;s/.*/        - hd-dvb-t2-s2-rx/}" /home/pi/ryde/config.yaml
  fi
  grep -q "lg_tv_42" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "lg_tv_42" 4
    sed -i "/handsets:/{n;s/.*/        - lg_tv_42/}" /home/pi/ryde/config.yaml
  fi
  grep -q "lg_bluray-BP530" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "lg_bluray-BP530" 5
    sed -i "/handsets:/{n;s/.*/        - lg_bluray-BP530/}" /home/pi/ryde/config.yaml
  fi
  grep -q "lg_bluray-BP620" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "lg_bluray-BP620" 6
    sed -i "/handsets:/{n;s/.*/        - lg_bluray-BP620/}" /home/pi/ryde/config.yaml
  fi
  grep -q "samsung_32" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "samsung_32" 7
    sed -i "/handsets:/{n;s/.*/        - samsung_32/}" /home/pi/ryde/config.yaml
  fi
  grep -q "elekta_tv" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "elekta_tv" 8
    sed -i "/handsets:/{n;s/.*/        - elekta_tv/}" /home/pi/ryde/config.yaml
  fi
  grep -q "wdtv_live" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "wdtv_live" 9
    sed -i "/handsets:/{n;s/.*/        - wdtv_live/}" /home/pi/ryde/config.yaml
  fi
  grep -q "hauppauge_mvp" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "hauppauge_mvp" 10
    sed -i "/handsets:/{n;s/.*/        - hauppauge_mvp/}" /home/pi/ryde/config.yaml
  fi
  grep -q "hauppauge_usb" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "hauppauge_usb" 11
    sed -i "/handsets:/{n;s/.*/        - hauppauge_usb/}" /home/pi/ryde/config.yaml
  fi
  grep -q "ts1_sat" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "ts1_sat" 12
    sed -i "/handsets:/{n;s/.*/        - ts1_sat/}" /home/pi/ryde/config.yaml
  fi
  grep -q "ts3500_sat" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "ts3500_sat" 13
    sed -i "/handsets:/{n;s/.*/        - ts3500_sat/}" /home/pi/ryde/config.yaml
  fi
  grep -q "f2100_uni" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "f2100_uni" 14
    sed -i "/handsets:/{n;s/.*/        - f2100_uni/}" /home/pi/ryde/config.yaml
  fi
  grep -q "sf8008" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "sf8008" 15
    sed -i "/handsets:/{n;s/.*/        - sf8008/}" /home/pi/ryde/config.yaml
  fi
  grep -q "freesat_v7" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "freesat_v7" 16
    sed -i "/handsets:/{n;s/.*/        - freesat_v7/}" /home/pi/ryde/config.yaml
  fi
  grep -q "rtl0" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "rtl0" 17
    sed -i "/handsets:/{n;s/.*/        - rtl0/}" /home/pi/ryde/config.yaml
  fi
  grep -q "avermediacard" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "avermediacard" 18
    sed -i "/handsets:/{n;s/.*/        - avermediacard/}" /home/pi/ryde/config.yaml
  fi
  grep -q "aeg_dvd" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "aeg_dvd" 19
    sed -i "/handsets:/{n;s/.*/        - aeg_dvd/}" /home/pi/ryde/config.yaml
  fi
  grep -q "g_rcu_023" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "g_rcu_023" 20
    sed -i "/handsets:/{n;s/.*/        - g_rcu_023/}" /home/pi/ryde/config.yaml
  fi
  grep -q "pheonix" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "pheonix" 21
    sed -i "/handsets:/{n;s/.*/        - pheonix/}" /home/pi/ryde/config.yaml
  fi
  grep -q "classic" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "classic" 22
    sed -i "/handsets:/{n;s/.*/        - classic/}" /home/pi/ryde/config.yaml
  fi
  grep -q "tesco_tv" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "tesco_tv" 23
    sed -i "/handsets:/{n;s/.*/        - tesco_tv/}" /home/pi/ryde/config.yaml
  fi
  grep -q "led_tv" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "led_tv" 24
    sed -i "/handsets:/{n;s/.*/        - led_tv/}" /home/pi/ryde/config.yaml
  fi
  grep -q "fortecstar" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "fortecstar" 25
    sed -i "/handsets:/{n;s/.*/        - fortecstar/}" /home/pi/ryde/config.yaml
  fi
  grep -q "cmtronic" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "cmtronic" 26
    sed -i "/handsets:/{n;s/.*/        - cmtronic/}" /home/pi/ryde/config.yaml
  fi
  grep -q "technotrendttc" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "technotrendttc" 27
    sed -i "/handsets:/{n;s/.*/        - technotrendttc/}" /home/pi/ryde/config.yaml
  fi
  grep -q "philipsrc4492" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "philipsrc4492" 28
    sed -i "/handsets:/{n;s/.*/        - philipsrc4492/}" /home/pi/ryde/config.yaml
  fi
  grep -q "mp3_player" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "mp3_player" 29
    sed -i "/handsets:/{n;s/.*/        - mp3_player/}" /home/pi/ryde/config.yaml
  fi
  grep -q "dreamboxurc39931" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "dreamboxurc39931" 30
    sed -i "/handsets:/{n;s/.*/        - dreamboxurc39931/}" /home/pi/ryde/config.yaml
  fi
  grep -q "humaxrmf04" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "humaxrmf04" 31
    sed -i "/handsets:/{n;s/.*/        - humaxrmf04/}" /home/pi/ryde/config.yaml
  fi
  grep -q "xtrendkt1252" "$PATHUBACKUP"/config.yaml
  if  [ $? == 0 ]; then   ## Amend new file for "xtrendkt1252" 32
    sed -i "/handsets:/{n;s/.*/        - xtrendkt1252/}" /home/pi/ryde/config.yaml
  fi
fi

# Record the version numbers

cp /home/pi/ryde-build/latest_version.txt /home/pi/ryde-build/installed_version.txt
cp -f -r "$PATHUBACKUP"/prev_installed_version.txt /home/pi/ryde-build/prev_installed_version.txt
rm -rf "$PATHUBACKUP"

# Save (overwrite) the git source used
echo "${GIT_SRC}" > /home/pi/${GIT_SRC_FILE}

echo
echo "--------------------------"
echo "----- Rebooting Ryde -----"
echo "--------------------------"
echo

sudo shutdown -r now

exit





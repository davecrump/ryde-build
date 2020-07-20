#!/bin/bash

# Ryde installer by davecrump on 20200714

# Check current user
whoami | grep -q pi
if [ $? != 0 ]; then
  echo "Install must be performed as user pi"
  exit
fi


# Check which source needs to be loaded
GIT_SRC="BritishAmateurTelevisionClub"
GIT_SRC_FILE=".ryde_gitsrc"

if [ "$1" == "-d" ]; then
  GIT_SRC="davecrump";
  echo
  echo "-------------------------------------------------------------"
  echo "----- Installing Ryde development version from davecrump-----"
  echo "-------------------------------------------------------------"
  echo
elif [ "$1" == "-u" -a ! -z "$2" ]; then
  GIT_SRC="$2"
  echo
  echo "WARNING: Installing ${GIT_SRC} development version, press enter to continue or 'q' to quit."
  read -n1 -r -s key;
  if [[ $key == q ]]; then
    exit 1;
  fi
  echo "ok!";
else
  echo
  echo "-------------------------------------------"
  echo "----- Installing BATC Production Ryde -----"
  echo "-------------------------------------------"
  echo
fi

# Update the package manager
echo
echo "------------------------------------"
echo "----- Updating Package Manager -----"
echo "------------------------------------"
echo
sudo dpkg --configure -a
sudo apt-get update

# Uninstall the apt-listchanges package to allow silent install of ca certificates (201704030)
# http://unix.stackexchange.com/questions/124468/how-do-i-resolve-an-apparent-hanging-update-process
sudo apt-get -y remove apt-listchanges

# Upgrade the distribution
echo
echo "-----------------------------------"
echo "----- Performing dist-upgrade -----"
echo "-----------------------------------"
echo
sudo apt-get -y dist-upgrade

# Install the packages that we need

echo
echo "------------------------------------------------"
echo "----- Installing Packages Required by Ryde -----"
echo "------------------------------------------------"
echo

sudo apt-get -y install git cmake libusb-1.0-0-dev
sudo apt-get -y install vlc
sudo apt-get -y install libasound2-dev
sudo apt-get -y install ir-keytable
sudo apt-get -y install python3-dev
sudo apt-get -y install python3-pip
sudo apt-get -y install python3-yaml
sudo apt-get -y install python3-pygame
sudo apt-get -y install python3-vlc
sudo apt-get -y install python3-evdev
sudo apt-get -y install python3-pil
sudo apt-get -y install python3-gpiozero

# Download the previously selected version of Ryde Build
echo
echo "------------------------------------------"
echo "----- Installing Ryde Build Utilities-----"
echo "------------------------------------------"
echo

# wget https://github.com/davecrump/ryde-build/archive/master.zip
wget https://github.com/${GIT_SRC}/ryde-build/archive/master.zip
unzip -o master.zip
mv ryde-build-master ryde-build
rm master.zip


# Download the previously selected version of LongMynd
echo
echo "--------------------------------------------"
echo "----- Installing the LongMynd Receiver -----"
echo "--------------------------------------------"
echo

wget https://github.com/eclispe/longmynd/archive/master.zip
# wget https://github.com/${GIT_SRC}/longmynd/archive/master.zip
unzip -o master.zip
mv longmynd-master longmynd
rm master.zip
cd longmynd
make

cd /home/pi

# Download the previously selected version of pyDispmanx
echo
echo "---------------------------------"
echo "----- Installing pyDispmanx -----"
echo "---------------------------------"
echo

wget https://github.com/eclispe/pyDispmanx/archive/master.zip
# wget https://github.com/${GIT_SRC}/pyDispmanx/archive/master.zip
unzip -o master.zip
mv pyDispmanx-master pydispmanx
rm master.zip
cd pydispmanx
python3 setup.py build_ext --inplace

cd /home/pi

# Download the previously selected version of Rydeplayer
echo
echo "---------------------------------"
echo "----- Installing Rydeplayer -----"
echo "---------------------------------"
echo

# wget https://github.com/davecrump/rydeplayer/archive/master.zip
wget https://github.com/${GIT_SRC}/rydeplayer/archive/master.zip
unzip -o master.zip
mv rydeplayer-master ryde
rm master.zip

cp /home/pi/pydispmanx/pydispmanx.cpython-37m-arm-linux-gnueabihf.so \
   /home/pi/ryde/pydispmanx.cpython-37m-arm-linux-gnueabihf.so

cd /home/pi


# Download the latest remote control definitions and images
echo
echo "----------------------------------------------"
echo "----- Downloading Remote Control Configs -----"
echo "----------------------------------------------"
echo
git clone -b definitions https://github.com/${GIT_SRC}/RydeHandsets.git RydeHandsets/definitions
git clone -b images https://github.com/${GIT_SRC}/RydeHandsets.git RydeHandsets/images

# Set up the Config for this build
cp /home/pi/ryde-build/config.yaml /home/pi/ryde/config.yaml

# Set up the operating system for Ryde
echo
echo "----------------------------------------------------"
echo "----- Setting up the Operating System for Ryde -----"
echo "----------------------------------------------------"
echo

# Set auto login to command line.
sudo raspi-config nonint do_boot_behaviour B2

# Enable IR Control
# uncomment line 51 of /boot/config.txt dtoverlay=gpio-ir,gpio_pin=17
sudo sed -i '/#dtoverlay=gpio-ir,gpio_pin=17/c\dtoverlay=gpio-ir,gpio_pin=17' /boot/config.txt  >/dev/null 2>/dev/null

# Increase GPU memory so that it copes with 4k displays
sudo bash -c 'echo " " >> /boot/config.txt '
sudo bash -c 'echo "# Increase GPU memory for 4k displays" >> /boot/config.txt '
sudo bash -c 'echo "gpu_mem=128" >> /boot/config.txt '
sudo bash -c 'echo " " >> /boot/config.txt '

# Modify .bashrc for autostart and set RPi Jack audio volume
echo  >> ~/.bashrc
echo "# Autostart Ryde on Boot" >> ~/.bashrc
echo if test -z \"\$SSH_CLIENT\" >> ~/.bashrc 
echo then >> ~/.bashrc
echo "  # Set RPi Audio Jack volume" >> ~/.bashrc
echo "  amixer set Headphone 0db >/dev/null 2>/dev/null" >> ~/.bashrc
echo  >> ~/.bashrc
echo "  # Start Ryde" >> ~/.bashrc
echo "  /home/pi/ryde-build/rx.sh" >> ~/.bashrc
echo fi >> ~/.bashrc
echo  >> ~/.bashrc


#echo
#echo "-----------------------------------------"
#echo "----- Compiling Ancilliary programs -----"
#echo "-----------------------------------------"
#echo

# None yet!

echo
echo "--------------------------------------"
echo "----- Configure the Menu Aliases -----"
echo "--------------------------------------"
echo

# Install the menu aliases
echo "alias ryde='/home/pi/ryde-build/rx.sh'" >> /home/pi/.bash_aliases
echo "alias menu='/home/pi/ryde-build/menu.sh'"  >> /home/pi/.bash_aliases
echo "alias stop='/home/pi/ryde-build/stop.sh'"  >> /home/pi/.bash_aliases


# Record Version Number
cd /home/pi/ryde-build/
cp latest_version.txt installed_version.txt
cd /home/pi

# Save git source used
echo "${GIT_SRC}" > /home/pi/${GIT_SRC_FILE}

# Reboot
echo
echo "--------------------------------"
echo "----- Complete.  Rebooting -----"
echo "--------------------------------"
echo
echo "After reboot, log in again."
echo "type menu, and then select your remote control type"
echo
sleep 1

sudo reboot now
exit



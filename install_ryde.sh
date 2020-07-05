#!/bin/bash

# Ryde installer by davecrump on 20200703

# Check current user
whoami | grep -q pi
if [ $? != 0 ]; then
  echo "Install must be performed as user pi"
  exit
fi


# Check which source needs to be loaded
GIT_SRC="BritishAmateurTelevisionClub"
GIT_SRC_FILE=".portsdown_gitsrc"

if [ "$1" == "-d" ]; then
  GIT_SRC="davecrump";
  echo
  echo "-------------------------------------------------------------"
  echo "----- Installing Ryde development version from davecrump-----"
  echo "-------------------------------------------------------------"
elif [ "$1" == "-t" ]; then
  GIT_SRC="eclispe";
  echo
  echo "-------------------------------------------------------------"
  echo "----- Installing Ryde development version from eclispe-----"
  echo "-------------------------------------------------------------"
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
fi

# Update the package manager
echo
echo "------------------------------------"
echo "----- Updating Package Manager -----"
echo "------------------------------------"
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
sudo apt-get -y dist-upgrade

# Install the packages that we need

# Already installed by Langstone
#sudo apt-get -y install git cmake libusb-1.0-0-dev wiringpi libfftw3-dev libxcb-shape0 

# Required in addition for Portsdown
#sudo apt-get -y install libx11-dev buffer libjpeg-dev indent 
#sudo apt-get -y install ttf-dejavu-core bc usbmount libvncserver-dev
#sudo apt-get -y install fbi netcat imagemagick omxplayer
#sudo apt-get -y install libvdpau-dev libva-dev  # For latest ffmpeg build
#sudo apt-get -y install libsqlite3-dev libi2c-dev # 201811300 Lime
#sudo apt-get -y install sshpass  # 201905090 For Jetson Nano
#sudo apt-get -y install libbsd-dev # 201910100 for raspi2raspi
#sudo apt-get -y install libasound2-dev sox # 201910230 for LongMynd tone and avc2ts audio
#sudo apt-get -y install libavcodec-dev libavformat-dev libswscale-dev libavdevice-dev # Required for ffmpegsrc.cpp
#sudo apt-get -y install mplayer vlc # 202004300 Used for video monitor and LongMynd (not libpng12-dev)
#sudo apt-get -y install autoconf libtool # for fdk aac

# Freqshow install no longer required:
#sudo apt-get -y install python-pip pandoc python-numpy pandoc python-pygame gdebi-core # 20180101 FreqShow
#sudo pip install pyrtlsdr  #20180101 FreqShow

echo
echo "------------------------------------------------"
echo "----- Installing Packages Required by Ryde -----"
echo "------------------------------------------------"

sudo apt-get -y install git cmake libusb-1.0-0-dev
sudo apt-get -y install vlc
sudo apt-get -y install libasound2-dev
sudo apt-get -y install ir-keytable
sudo apt-get -y install python3-dev
sudo apt-get -y install python3-pip
sudo apt-get -y install python3-yaml
sudo apt-get -y install python3-pygame
sudo pip3 install evdev
sudo pip3 install python-vlc
sudo pip3 install Pillow

# Download the previously selected version of Ryde Build
echo
echo "------------------------------------------"
echo "----- Installing Ryde Build Utilities-----"
echo "------------------------------------------"
#wget https://github.com/davecrump/ryde-build/archive/master.zip
# wget https://github.com/${GIT_SRC}/ryde-build/archive/master.zip
#unzip -o master.zip
#mv ryde-build--master ryde-build
#rm master.zip


# Download the previously selected version of LongMynd
echo
echo "--------------------------------------------"
echo "----- Installing the LongMynd Receiver -----"
echo "--------------------------------------------"
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

wget https://github.com/eclispe/pyDispmanx/archive/master.zip
# wget https://github.com/${GIT_SRC}/pyDispmanx/archive/master.zip
unzip -o master.zip
mv pyDispmanx-master pydispmanx
rm master.zip
cd pydispmanx
python3 setup.py build_ext --inplace

cd /home/pi

# Download the previously selected version of Ryde
echo
echo "---------------------------"
echo "----- Installing Ryde -----"
echo "---------------------------"

cd /home/pi
mkdir ryde
cd ryde
unzip -o ../ryde-alpha.zip

cp /home/pi/pydispmanx/pydispmanx.cpython-37m-arm-linux-gnueabihf.so pydispmanx.cpython-37m-arm-linux-gnueabihf.so


cd /home/pi

# Set up the operating system for Ryde Ryde
echo
echo "----------------------------------------------------"
echo "----- Setting up the Operating System for Ryde -----"
echo "----------------------------------------------------"

# Set auto login to command line.
sudo raspi-config nonint do_boot_behaviour B2

# Enable IR Control
# uncomment line 51 of /boot/config.txt dtoverlay=gpio-ir,gpio_pin=17

sudo sed -i '/#dtoverlay=gpio-ir,gpio_pin=17/c\dtoverlay=gpio-ir,gpio_pin=17' /boot/config.txt  >/dev/null 2>/dev/null

#Modify .bashrc for autostart

#if !(grep Ryde ~/.bashrc) then
#  echo if test -z \"\$SSH_CLIENT\" >> ~/.bashrc 
#  echo then >> ~/.bashrc
#  echo /home/pi/Ryde/run >> ~/.bashrc
#  echo fi >> ~/.bashrc
#fi


#echo
#echo "-----------------------------------------"
#echo "----- Compiling Ancilliary programs -----"
#echo "-----------------------------------------"



#echo
#echo "--------------------------------------"
#echo "----- Configure the Video Output -----"
#echo "--------------------------------------"

# Enable the Video output in PAL mode (201707120)
#cd /boot
#sudo sed -i 's/^#sdtv_mode=2/sdtv_mode=2/' config.txt
#cd /home/pi

# Download and compile the components for Comp Vid output whilst using 7 inch screen
#wget https://github.com/AndrewFromMelbourne/raspi2raspi/archive/master.zip
#unzip master.zip
#mv raspi2raspi-master raspi2raspi
#rm master.zip
#cd raspi2raspi/
#mkdir build
#cd build
#cmake ..
#make
#sudo make install
#cd /home/pi

# Download and compile the components for Screen Capture
#wget https://github.com/AndrewFromMelbourne/raspi2png/archive/master.zip
#unzip master.zip
#mv raspi2png-master raspi2png
#rm master.zip
#cd raspi2png
#make
#sudo make install
#cd /home/pi

echo
echo "--------------------------------------"
echo "----- Configure the Menu Aliases -----"
echo "--------------------------------------"

# Install the menu aliases
#echo "alias menu='/home/pi/rpidatv/scripts/menu.sh menu'" >> /home/pi/.bash_aliases
#echo "alias gui='/home/pi/rpidatv/scripts/utils/guir.sh'"  >> /home/pi/.bash_aliases
#echo "alias ugui='/home/pi/rpidatv/scripts/utils/uguir.sh'"  >> /home/pi/.bash_aliases
#echo "alias stopl='/home/pi/Langstone/stop'"  >> /home/pi/.bash_aliases
#echo "alias runl='/home/pi/Langstone/run'"  >> /home/pi/.bash_aliases

# Modify .bashrc to run startup script on ssh logon
#cd /home/pi
#sed -i 's|/home/pi/Langstone/run|source /home/pi/rpidatv/scripts/startup.sh|' .bashrc

# Record Version Number
#cd /home/pi/ryde-build/
#cp latest_version.txt installed_version.txt
#cd /home/pi

# Save git source used
echo "${GIT_SRC}" > /home/pi/${GIT_SRC_FILE}

# Reboot
echo
echo "--------------------------------"
echo "----- Complete.  Rebooting -----"
echo "--------------------------------"
sleep 1

# sudo reboot now
exit



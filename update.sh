#!/bin/bash

# Created by davecrump 20200714 for Ryde on Buster Raspios

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
fi

# Restore the user's config, or use new if user's config.yaml is outdated
#echo
#echo "---------------------------------------------"
#echo "----- Restoring the User's Config Files -----"
#echo "---------------------------------------------"
#echo

grep -q "UP:     14" "$PATHUBACKUP"/config.yaml
if  [ $? == 0 ]; then   ## Latest version, so restore from backup
  cp "$PATHUBACKUP"/config.yaml /home/pi/ryde/config.yaml
else                    ## Old version, so write new one and warn user
  cp /home/pi/ryde-build/config.yaml /home/pi/ryde/config.yaml
  echo
  echo "Your old config file needed to be updated"
  echo "Please use the console menu to reselect"
  echo "your remote control after reboot"
  echo
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





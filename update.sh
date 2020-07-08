#!/bin/bash

# Created by davecrump 20200708 for Ryde on Buster Raspios


echo
echo "------------------------------------------"
echo "----- Updating Ryde Receiver Software-----"
echo "------------------------------------------"
echo

cd /home/pi

PATHUBACKUP="/home/pi/user_backups"
mkdir "$PATHUBACKUP" >/dev/null 2>/dev/null  

# Note previous version number
cp -f -r /home/pi/ryde-build/installed_version.txt "$PATHUBACKUP"/prev_installed_version.txt

# Make a safe copy of the Config files in "$PATHUBACKUP" to restore at the end

echo
echo "------------------------------------------"
echo "----- Updating the Software Packages -----"
echo "------------------------------------------"
echo

sudo dpkg --configure -a     # Make sure that all the packages are properly configured
sudo apt-get clean           # Clean up the old archived packages
sudo apt-get update          # Update the package list

# --------- Update Packages ------

sudo apt-get -y dist-upgrade # Upgrade all the installed packages to their latest version

# --------- Install new packages as Required ---------

# --------- Overwrite and compile all the software components -----

# Download the previously selected version of Ryde Build
echo
echo "----------------------------------------"
echo "----- Updating Ryde Build Utilities-----"
echo "----------------------------------------"
echo
rm -rf /home/pi/ryde-build
wget https://github.com/davecrump/ryde-build/archive/master.zip
# wget https://github.com/${GIT_SRC}/ryde-build/archive/master.zip
unzip -o master.zip
mv ryde-build--master ryde-build
rm master.zip


# Download the previously selected version of LongMynd
echo
echo "------------------------------------------"
echo "----- Updating the LongMynd Receiver -----"
echo "------------------------------------------"
echo
rm -rf /home/pi/longmynd
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
echo "--------------------------------"
echo "----- Updating pyDispmanx -----"
echo "--------------------------------"
echo
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
echo "-------------------------"
echo "----- Updating Ryde -----"
echo "-------------------------"
echo
rm -rf /home/pi/ryde
cd /home/pi
mkdir ryde
cd ryde
unzip -o ../ryde-alpha.zip

cp /home/pi/pydispmanx/pydispmanx.cpython-37m-arm-linux-gnueabihf.so pydispmanx.cpython-37m-arm-linux-gnueabihf.so

# Restore the user's original config files here

# Record the version numbers

cp /home/pi/ryde-build/latest_version.txt /home/pi/ryde-build/installed_version.txt
cp -f -r "$PATHUBACKUP"/prev_installed_version.txt /home/pi/ryde-build/prev_installed_version.txt
rm -rf "$PATHUBACKUP"

# Save (overwrite) the git source used
#echo "${GIT_SRC}" > /home/pi/${GIT_SRC_FILE}

echo
echo "--------------------------"
echo "----- Rebooting Ryde -----"
echo "--------------------------"
echo

sudo shutdown -r now

exit





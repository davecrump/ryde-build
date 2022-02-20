![ryde banner](/docs/Ryde_With_Menu_Small.jpg)
# The BATC Ryde DATV Receiver Build For the RPi 4

**The Ryde** is a DVB-S and DVB-S2 digital television receiver based on the Raspberry Pi 4.  The core of the system was written by Heather M0HMO and the control software is written by Tim MW0RUD.  Significant contributions have also been made by Phil M0DNY and Dave G8GKQ.   The project uses a Raspberry Pi 4, an HDMI Display, an IR Remote Control and a BATC MiniTiouner (Mk 2 - with Serit Tuner).  The intention is that the design should be reproducible by someone who has never used Linux before.  Detailed instructions on loading the software are listed below, and further details of the complete system design and build are on the BATC Wiki at https://wiki.batc.org.uk/Ryde_Introduction.  There is a Forum for discussion of the project here: https://forum.batc.org.uk/viewforum.php?f=130
This version is based on Raspios Buster and is only compatible with the Raspberry Pi 4.  

Our thanks to Heather, Tim, Phil and all the other contributors to this community project.  Where possible, the code within the project is GPL V3.

# Installation for BATC Ryde

The preferred installation method only needs a Windows PC connected to the same (internet-connected) network as your Raspberry Pi 4.  Do not connect a keyboard or mouse directly to your Raspberry Pi; you can connect the HDMI display.

- First download the 2022-01-28 release of Raspberry Pi OS Lite (Legacy) on to your Windows PC from here 
https://downloads.raspberrypi.org/raspios_oldstable_lite_armhf/images/raspios_oldstable_lite_armhf-2022-01-28/2022-01-28-raspios-buster-armhf-lite.zip

- Unzip the image and then transfer it to a Micro-SD Card using Win32diskimager https://sourceforge.net/projects/win32diskimager/

- Before you remove the card from your Windows PC, look at the card with windows explorer; the volume should be labeled "boot".  Create a new empty file called ssh in the top-level (root) directory by right-clicking, selecting New, Text Document, and then change the name to ssh (not ssh.txt).  You should get a window warning about changing the filename extension.  Click OK.  If you do not get this warning, you have created a file called ssh.txt and you need to rename it ssh.  IMPORTANT NOTE: by default, Windows (all versions) hides the .txt extension on the ssh file.  To change this, in Windows Explorer, select File, Options, click the View tab, and then untick "Hide extensions for known file types". Then click OK.

- Power up the RPi with the new card inserted, and a network connection.  Do not connect a keyboard or mouse to the Raspberry Pi. 

- Find the IP address of your Raspberry Pi using an IP Scanner (such as Advanced IP Scanner http://filehippo.com/download_advanced_ip_scanner/ for Windows, or Fing on an iPhone) to get the RPi's IP address.  You may also see it displayed on the HDMI screen.

- From your windows PC use Putty (http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html) to log in to the IP address that you noted earlier.  You will get a Security warning the first time you try; this is normal.

- Log in (user: pi, password: raspberry) then cut and paste the following code in, one line at a time:

```sh
wget https://raw.githubusercontent.com/BritishAmateurTelevisionClub/ryde-build/master/install_ryde.sh
chmod +x install_ryde.sh
./install_ryde.sh
```

The initial build can take between 10 and 15 minutes, however it does not need any user input, so go and make a cup of coffee and keep an eye on the screen.  When the build is finished the Pi will reboot and start-up with the Ryde software running.

# Post-install Set-up

After reboot, the Ryde software will start and attempt to receive a signal on 741.5 MHz, 1500 kS.  It will be configured to use a Virgin Media type remote control, and to output video on the primary HDMI port of the RPi.  To change the model of remote, or to select comp video output, log in by ssh and type menu.  There is a text menu to enable selection of other options.

# Advanced notes

- If your ISP is Virgin Media and you receive an error after entering the wget line: 'GnuTLS: A TLS fatal alert has been received.', it may be that your ISP is blocking access to GitHub.  If (only if) you get this error with Virgin Media, paste the following command in, and press return.
```sh
sudo sed -i 's/^#name_servers.*/name_servers=8.8.8.8/' /etc/resolvconf.conf
```
Then reboot, and try again.  The command asks your RPi to use Google's DNS, not your ISP's DNS.

- If your ISP is BT, you will need to make sure that "BT Web Protect" is disabled so that you are able to download the software.


- When it has finished, the installation will reboot.  Note that you do not need to load any drivers.


To load the development version, cut and paste in the following lines:

```sh
wget https://raw.githubusercontent.com/davecrump/ryde-build/master/install_ryde.sh
chmod +x install_ryde.sh
./install_ryde.sh -d
```


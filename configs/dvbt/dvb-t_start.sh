#!/bin/bash

# Script to run Combituner on the Ryde

CONFIGFILE="/home/pi/dvbt/dvb-t_config.txt"

############ FUNCTION TO READ CONFIG FILE #############################

get_config_var() {
lua - "$1" "$2" <<EOF
local key=assert(arg[1])
local fn=assert(arg[2])
local file=assert(io.open(fn))
for line in file:lines() do
local val = line:match("^#?%s*"..key.."=(.*)$")
if (val ~= nil) then
print(val)
break
end
end
EOF
}
######################################################################

cd /home/pi

# Read from receiver config file
BWKHZ=$(get_config_var bw $CONFIGFILE)
FREQ_KHZ=$(get_config_var freq $CONFIGFILE)
AUDIO_OUT=$(get_config_var audio $CONFIGFILE)
CHAN=$(get_config_var chan $CONFIGFILE)


# Send audio to the correct port
if [ "$AUDIO_OUT" == "rpi" ]; then
  # Check for latest Buster update
  aplay -l | grep -q 'bcm2835 Headphones'
  if [ $? == 0 ]; then
    AUDIO_DEVICE="hw:CARD=Headphones,DEV=0"
  else
    AUDIO_DEVICE="hw:CARD=ALSA,DEV=0"
  fi
else
 # AUDIO_DEVICE="hw:CARD=Device,DEV=0"
 AUDIO_DEVICE="hw:CARD=b1,DEV=0"
fi

PROG=" "
if [ "$CHAN" != "0" ] && [ "$CHAN" != "" ]; then
  PROG="--program "$CHAN
fi

# Create dummy marquee overlay file
sudo rm /home/pi/tmp/vlc_overlay.txt >/dev/null 2>/dev/null
echo " " > /home/pi/tmp/vlc_overlay.txt

sudo killall CombiTunerExpress >/dev/null 2>/dev/null
sudo killall vlc >/dev/null 2>/dev/null

# Play a very short dummy file to prime VLC
cvlc -I rc --rc-host 127.0.0.1:1111 --quiet --codec ffmpeg --video-title-timeout=10 \
  --sub-filter marq --marq-size 20 --marq-x 25 --marq-file "/home/pi/tmp/vlc_overlay.txt" \
  --gain 3 --alsa-audio-device $AUDIO_DEVICE \
   /home/pi/dvbt/blank.ts vlc:quit >/dev/null 2>/dev/null &
sleep 1
echo shutdown | nc 127.0.0.1 1111  >/dev/null 2>/dev/null

# Create the status fifo
sudo rm knucker_status_fifo >/dev/null 2>/dev/null
mkfifo knucker_status_fifo

# Start Combituner, and set buffer to output STDOUT one line at a time
stdbuf -oL  /home/pi/dvbt/CombiTunerExpress -m dvbt -f $FREQ_KHZ -b $BWKHZ >>knucker_status_fifo 2>/dev/null &
#/home/pi/dvbt/CombiTunerExpress -m dvbt -f $FREQ_KHZ -b $BWKHZ &

sleep 0.1

# Start VLC
cvlc -I rc --rc-host 127.0.0.1:1111 --quiet $PROG --codec ffmpeg --video-title-timeout=100 \
  --sub-filter marq --marq-size 20 --marq-x 25 --marq-file "/home/pi/tmp/vlc_overlay.txt" \
  --gain 3 --alsa-audio-device $AUDIO_DEVICE \
  udp://@127.0.0.1:1314 >/dev/null 2>/dev/null &

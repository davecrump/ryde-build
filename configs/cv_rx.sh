#!/bin/bash

CONFIGFILE="/home/pi/ryde-build/cv_config.txt"

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

#######################################################################

# Send audio to the correct port
# jack, hdmi or usb
AUDIO_OUT=$(get_config_var audio $CONFIGFILE)

# Set default as hdmi:
AUDIO_DEVICE="hw:CARD=b1,DEV=0"

if [ "$AUDIO_OUT" == "jack" ]; then
  AUDIO_DEVICE="hw:CARD=Headphones,DEV=0"
fi

if [ "$AUDIO_OUT" == "usb" ]; then
  AUDIO_DEVICE="hw:CARD=Device,DEV=0"
fi

# Set the correct format
FORMAT=$(get_config_var format $CONFIGFILE)

# Default 4:3
FORMAT_PARAMETER=" "

if [ "$FORMAT" == "16:9" ]; then
  FORMAT_PARAMETER="--aspect-ratio 16:9"
fi

# Read the Ident Caption
CAPTION=$(get_config_var caption $CONFIGFILE)

# Script to set the conditions for VLC Video Player and to launch it

#echo "Making Sure VLC is not already running"

sudo killall vlc >/dev/null 2>/dev/null

sleep 1

#echo "Restaring VLC"

# If a Fushicai EasyCap, adjust the contrast to prevent white crushing
# Default is 464 (scale 0 - 1023) which crushes whites
lsusb | grep -q '1b71:3002'
if [ $? == 0 ]; then   ## Fushicai USBTV007
  ECCONTRAST="contrast=380"
else
  ECCONTRAST=" "
fi

while true; do

  # If VLC is not running, start it
  pgrep vlc >/dev/null 2>/dev/null
  if [[ "$?" != "0" ]]; then
    v4l2-ctl -d /dev/video0 --set-standard=6 >/dev/null 2>/dev/null

    (cvlc -I rc --rc-host 127.0.0.1:1111 \
      v4l2:///dev/video0:width=720:height=576 :input-slave=alsa://plughw:CARD=usbtv,DEV=0 \
      --sub-filter marq --marq-x 30 --marq-y 30 --marq-size 20 --marq-marquee "$CAPTION" \
      $FORMAT_PARAMETER \
      --gain 3 --alsa-audio-device "$AUDIO_DEVICE" \
      >/dev/null 2>/dev/null) &

    sleep 0.7
    v4l2-ctl -d /dev/video0 --set-ctrl "$ECCONTRAST" >/dev/null 2>/dev/null

    # Give VLC 5 seconds to settle if just started
    sleep 5
  fi

  #Check again in 15 seconds
  sleep 15
done

exit

# Audio passthrough Tests:
# arecord -f S16_LE -c 2 -r 48000 -D hw:CARD=usbtv,DEV=0 | aplay -D hw:CARD=b1,DEV=0 # works with Fushicai
# arecord -f S16_LE -c 2 -r 48000 -D hw:CARD=USB20,DEV=0 | aplay -D hw:CARD=b1,DEV=0 # doesn't work with Macrosil

# VLC Options:
#      --aspect-ratio 16:9 \  # for Full width
#      --gain 3 --alsa-audio-device hw:CARD=b1,DEV=0 \  # Audio on HDMI
#      --gain 3 --alsa-audio-device hw:CARD=Headphones,DEV=0 \   # Audio on Jack



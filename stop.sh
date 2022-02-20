#!/bin/bash

# File to stop Ryde and Comp Vid

sudo killall python3 >/dev/null 2>/dev/null

sleep 1
if pgrep -x "python3" >/dev/null
then
  sudo killall -9 python3 >/dev/null 2>/dev/null
fi

sudo killall longmynd >/dev/null 2>/dev/null

sudo pkill rx.sh >/dev/null 2>/dev/null
pgrep vlc >/dev/null 2>/dev/null
if [[ "$?" == "0" ]]; then
  sleep 1
  sudo killall vlc >/dev/null 2>/dev/null
fi

exit

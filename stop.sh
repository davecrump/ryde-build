#!/bin/bash

# File to stop Ryde

sudo killall python3 >/dev/null 2>/dev/null

sleep 1
if pgrep -x "python3" >/dev/null
then
  sudo killall -9 python3 >/dev/null 2>/dev/null
fi

exit

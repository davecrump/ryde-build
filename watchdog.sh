#!/bin/bash

# Watchdog script for Ryde with Longmynd

# Initialise
RESTART_REQUIRED=NO

# Do not start script until Ryde has had time to startup
sleep 15

while true
  do
    # Check Ryde is running
    pgrep -f rydeplayer >/dev/null 2>/dev/null
    RESULT="$?"
    if [ "$RESULT" -ne 0 ]; then
      RESTART_REQUIRED=YES
    fi

    # Check the Ryde watchdog file if it exists
    if test -f "/home/pi/tmp/rydePlayer.pid"; then
      # Check that the Ryde Watchdog file has been updated in the last 10 seconds
      CURRENT_SECONDS=`date +%s`
      LAST_MODIFIED_SECONDS=`stat -c "%Y" /home/pi/tmp/rydePlayer.pid`
      if [ $(($CURRENT_SECONDS-$LAST_MODIFIED_SECONDS)) -gt 10 ]; then 
        RESTART_REQUIRED=YES
      fi
    fi

    # Check if restart required and action
    if [ "$RESTART_REQUIRED" = "YES" ]; then
      
      # Kill existing python3 and longmynd processes
      sudo killall python3
      sudo killall longmynd
      sleep 5

      # Restart rydeplayer
      /home/pi/ryde-build/rx.sh &
      
      # Wait 10 seconds for restart
      sleep 10

      # Reinitialise
      RESTART_REQUIRED=NO
    fi

    # Wait 5 seconds before next check
    sleep 5
  done
exit



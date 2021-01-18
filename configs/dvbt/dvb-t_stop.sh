#!/bin/bash

# Script to stop Combituner on the Ryde

pidof CombiTunerExpress | xargs kill >/dev/null 2>/dev/null
echo shutdown | nc 127.0.0.1 1111
sleep 1
sudo killall vlc >/dev/null 2>/dev/null
#pidof CombiTunerExpress | xargs kill -9 >/dev/null 2>/dev/null 

sudo killall play_dvbt




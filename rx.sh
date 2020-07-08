#!/bin/bash

# File to set conditions for Ryde and start it.

sudo ir-keytable -p nec >/dev/null 2>/dev/null

cd /home/pi/ryde
python3 -m rydeplayer /home/pi/ryde/config.yaml >/dev/null 2>/dev/null &

exit

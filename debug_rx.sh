#!/bin/bash

# Script to set the conditions for RydePlayer and to launch it
# It supports up to 3 RC handsets defined in /home/pi/ryde/config.yaml

##########################YAML PARSER ####################
function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|,$s\]$s\$|]|" \
        -e ":1;s|^\($s\)\($w\)$s:$s\[$s\(.*\)$s,$s\(.*\)$s\]|\1\2: [\3]\n\1  - \4|;t1" \
        -e "s|^\($s\)\($w\)$s:$s\[$s\(.*\)$s\]|\1\2:\n\1  - \3|;p" $1 | \
   sed -ne "s|,$s}$s\$|}|" \
        -e ":1;s|^\($s\)-$s{$s\(.*\)$s,$s\($w\)$s:$s\(.*\)$s}|\1- {\2}\n\1  \3: \4|;t1" \
        -e    "s|^\($s\)-$s{$s\(.*\)$s}|\1-\n\1  \2|;p" | \
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)-$s[\"']\(.*\)[\"']$s\$|\1$fs$fs\2|p" \
        -e "s|^\($s\)-$s\(.*\)$s\$|\1$fs$fs\2|p" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" | \
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]; idx[i]=0}}
      if(length($2)== 0){  vname[indent]= ++idx[indent] };
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) { vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, vname[indent], $3);
      }
   }'
}
#########################################################

# Read and trim the IR Library path
LIBRARY_PATH_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'ir__libraryPath=')"
LIBRARY_PATH="$(echo "$LIBRARY_PATH_LINE" | sed 's/ir__libraryPath=\"//' | sed 's/\"//')"

# Read and Trim handset 1
HANDSET1="$(parse_yaml /home/pi/ryde/config.yaml | grep 'ir__handsets__1')" 
SHORTHANDSET1="$(echo "$HANDSET1" | sed 's/ir__handsets__1=\"//' | sed 's/\"//')"

# Look up and trim the protocol for handset 1
PROTOCOL1_LINE="$(parse_yaml ${LIBRARY_PATH}/${SHORTHANDSET1}.yaml | grep 'driver="' )"
PROTOCOL1="$(echo "$PROTOCOL1_LINE" | sed 's/driver=\"//' | sed 's/\"//')"

# Check for another 2 handsets

PROTOCOL2=""
PROTOCOL3=""

# Check for handset 2 and look up protocol
HANDSET2="$(parse_yaml /home/pi/ryde/config.yaml | grep 'ir__handsets__2')"
if [ "$HANDSET2" != "" ]; then
  SHORTHANDSET2="$(echo "$HANDSET2" | sed 's/ir__handsets__2=\"//' | sed 's/\"//')"

  PROTOCOL2_LINE="$(parse_yaml ${LIBRARY_PATH}/${SHORTHANDSET2}.yaml | grep 'driver="' )"
  PROTOCOL2="$(echo "$PROTOCOL2_LINE" | sed 's/driver=\"//' | sed 's/\"//')"
  PROTOCOL2="-p ${PROTOCOL2}"

  # Check for handset 3 and look up protocol
  HANDSET3="$(parse_yaml /home/pi/ryde/config.yaml | grep 'ir__handsets__3')"
  if [ "$HANDSET3" != "" ]; then
    SHORTHANDSET3="$(echo "$HANDSET3" | sed 's/ir__handsets__3=\"//' | sed 's/\"//')"

    PROTOCOL3_LINE="$(parse_yaml ${LIBRARY_PATH}/${SHORTHANDSET3}.yaml | grep 'driver="' )"
    PROTOCOL3="$(echo "$PROTOCOL3_LINE" | sed 's/driver=\"//' | sed 's/\"//')"
    PROTOCOL3="-p ${PROTOCOL3}"
  fi
fi

# echo $PROTOCOL1 $PROTOCOL2 $PROTOCOL3

# Set the IR Protocol(s)
sudo ir-keytable -p $PROTOCOL1 $PROTOCOL2 $PROTOCOL3 >/dev/null 2>/dev/null

# Start Ryde Player
cd /home/pi/ryde
python3 -m rydeplayer /home/pi/ryde/config.yaml


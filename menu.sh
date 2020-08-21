#!/bin/bash

# Ryde Menu Application

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


do_update()
{
  /home/pi/ryde-build/check_for_update.sh
}

do_info()
{
  /home/pi/ryde-build/display_info.sh
}


do_Set_RC_Type()
{
  RC_FILE=""

  menuchoice=$(whiptail --title "Set Remote Control Model" --menu "Select Choice" 30 78 20 \
    "1 Virgin" "Virgin Media"  \
    "2 Nebula" "Nebula DigiTV DVB-T USB Receiver" \
    "3 DVB-T2-S2" "eBay DVB-T2-S2 Combo with 12v in " \
    "4 LG TV " "LG 42 inch TV " \
    "5 LG Blu-Ray 1" "LG Blu-Ray Disc Player BP-530R " \
    "6 LG Blu-Ray 2" "LG Blu-Ray Disc Player BP-620R " \
    "7 Samsung TV" "Samsung 32 inch TV" \
    "8 Elekta TV" "Elekta Bravo 19 inch TV" \
    "9 WDTV Live" "WDTV Live Media Player" \
    "10 Hauppauge 1" "Hauppauge MediaMVP Network Media Player" \
    "11 Hauppauge 2" "Hauppauge USB PVR Ex-digilite" \
    "12 TS-1 Sat" "Technosat TS-1 Satellite Receiver" \
    "13 TS-3500" "Technosat TS-3500 Satellite Receiver" \
    "14 F-2100 Uni" "Digi-Wav 2 Pound F2100 Universal Remote" \
    "15 SF8008" "Octagon SF8008 Sat RX Remote" \
    "16 Freesat V7" "Freesat V7 Combo - Some keys changed" \
    "17 RTL-SDR" "RTL-SDR Basic Remote" \
    "18 Avermedia" "AverMedia PC Card Tuner" \
    "19 Exit" "Exit without changing remote control model" \
      3>&2 2>&1 1>&3)
    case "$menuchoice" in
        1\ *) RC_FILE="virgin" ;;
        2\ *) RC_FILE="nebula_usb" ;;
        3\ *) RC_FILE="hd-dvb-t2-s2-rx" ;;
        4\ *) RC_FILE="lg_tv_42" ;;
        5\ *) RC_FILE="lg_bluray-BP530" ;;
        6\ *) RC_FILE="lg_bluray-BP620" ;;
        7\ *) RC_FILE="samsung_32" ;;
        8\ *) RC_FILE="elekta_tv" ;;
        9\ *) RC_FILE="wdtv_live" ;;
        10\ *) RC_FILE="hauppauge_mvp" ;;
        11\ *) RC_FILE="hauppauge_usb" ;;
        12\ *) RC_FILE="ts1_sat" ;;
        13\ *) RC_FILE="ts3500_sat" ;;
        14\ *) RC_FILE="f2100_uni" ;;
        15\ *) RC_FILE="sf8008" ;;
        16\ *) RC_FILE="freesat_v7" ;;
        17\ *) RC_FILE="rtl0" ;;
        18\ *) RC_FILE="avermediacard" ;;
        19\ *) RC_FILE="exit" ;;
    esac

  if [ "$RC_FILE" != "exit" ]; then # Amend the config file

    RC_FILE="        - ${RC_FILE}"
    sed -i "/handsets:/{n;s/.*/$RC_FILE/}" /home/pi/ryde/config.yaml

    # Load the requested file
    #cp /home/pi/RydeHandsets/definitions/"$RC_FILE" /home/pi/ryde/handset.yaml

    # Set the requested protocol setting
    #sudo ir-keytable -p $PROTOCOL >/dev/null 2>/dev/null

    # And change it for the future
    #sed -i "/ir-keytable/c\sudo ir-keytable -p $PROTOCOL >/dev/null 2>/dev/null" /home/pi/ryde-build/rx.sh
  fi
}

do_Set_Freq()
{
  DEFAULT_FREQ=0
  SCAN_FREQ_1=0
  SCAN_FREQ_2=0
  SCAN_FREQ_3=0
  SCAN_FREQ_4=0

  # Read and trim the default FREQ Values
  DEFAULT_FREQ_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'default__freq=')"
  if [ "$DEFAULT_FREQ_LINE" != "" ]; then
    DEFAULT_FREQ="$(echo "$DEFAULT_FREQ_LINE" | sed 's/default__freq=\"//' | sed 's/\"//')"
    SCAN_FREQ_VALUES=0
  else
    SCAN_FREQ_1_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'default__freq__1=')"
    if [ "$SCAN_FREQ_1_LINE" != "" ]; then
      SCAN_FREQ_1="$(echo "$SCAN_FREQ_1_LINE" | sed 's/default__freq__1=\"//' | sed 's/\"//')"
      SCAN_FREQ_VALUES=1
      SCAN_FREQ_2_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'default__freq__2=')"
      if [ "$SCAN_FREQ_2_LINE" != "" ]; then
        SCAN_FREQ_2="$(echo "$SCAN_FREQ_2_LINE" | sed 's/default__freq__2=\"//' | sed 's/\"//')"
        SCAN_FREQ_VALUES=2
        SCAN_FREQ_3_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'default__freq__3=')"
        if [ "$SCAN_FREQ_3_LINE" != "" ]; then
          SCAN_FREQ_3="$(echo "$SCAN_FREQ_3_LINE" | sed 's/default__freq__3=\"//' | sed 's/\"//')"
          SCAN_FREQ_VALUES=3
          SCAN_FREQ_4_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'default__freq__4=')"
          if [ "$SCAN_FREQ_4_LINE" != "" ]; then
            SCAN_FREQ_4="$(echo "$SCAN_FREQ_4_LINE" | sed 's/default__freq__4=\"//' | sed 's/\"//')"
            SCAN_FREQ_VALUES=4
          fi
        fi
      fi
    fi
  fi

  if [ "$SCAN_FREQ_VALUES" != "0" ]; then  # In scanning FREQ mode, so convert back to single FREQ
    
    # Set the default FREQ to the first scanning FREQ
    DEFAULT_FREQ=$SCAN_FREQ_1

    # Delete the scanning FREQ lines
    if [ "$SCAN_FREQ_VALUES" == "4" ]; then  # delete row 2
      sed -i "/^    freq:/!b;n;d" /home/pi/ryde/config.yaml
      SCAN_FREQ_VALUES=3  # and decrement the number of rows
    fi
    if [ "$SCAN_FREQ_VALUES" == "3" ]; then  # delete row 2
      sed -i "/^    freq:/!b;n;d" /home/pi/ryde/config.yaml
      SCAN_FREQ_VALUES=2  # and decrement the number of rows
    fi
    if [ "$SCAN_FREQ_VALUES" == "2" ]; then  # delete row 2
      sed -i "/^    freq:/!b;n;d" /home/pi/ryde/config.yaml
      SCAN_FREQ_VALUES=1  # and decrement the number of rows
    fi
    if [ "$SCAN_FREQ_VALUES" == "1" ]; then  # delete row 2
      sed -i "/^    freq:/!b;n;d" /home/pi/ryde/config.yaml
      SCAN_FREQ_VALUES=0  # and decrement the number of rows
    fi

    # Write the default FREQ to the FREQ line
    sed -i "/^    freq:/c\    freq: $DEFAULT_FREQ"  /home/pi/ryde/config.yaml

  fi

  DEFAULT_FREQ=$(whiptail --inputbox "Enter the new Start-up frequency in kHz" 8 78 $DEFAULT_FREQ --title "Frequency Entry Menu" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    sed -i "/    freq:/c\    freq: $DEFAULT_FREQ" /home/pi/ryde/config.yaml
  fi
}

do_Set_Scan_Freq()
{
  DEFAULT_FREQ=0
  SCAN_FREQ_1=0
  SCAN_FREQ_2=0
  SCAN_FREQ_3=0
  SCAN_FREQ_4=0

  # Read and trim the default FREQ Values
  DEFAULT_FREQ_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'default__freq=')"
  if [ "$DEFAULT_FREQ_LINE" != "" ]; then
    DEFAULT_FREQ="$(echo "$DEFAULT_FREQ_LINE" | sed 's/default__freq=\"//' | sed 's/\"//')"
    SCAN_FREQ_VALUES=0
  else
    SCAN_FREQ_1_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'default__freq__1=')"
    if [ "$SCAN_FREQ_1_LINE" != "" ]; then
      SCAN_FREQ_1="$(echo "$SCAN_FREQ_1_LINE" | sed 's/default__freq__1=\"//' | sed 's/\"//')"
      SCAN_FREQ_VALUES=1
      SCAN_FREQ_2_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'default__freq__2=')"
      if [ "$SCAN_FREQ_2_LINE" != "" ]; then
        SCAN_FREQ_2="$(echo "$SCAN_FREQ_2_LINE" | sed 's/default__freq__2=\"//' | sed 's/\"//')"
        SCAN_FREQ_VALUES=2
        SCAN_FREQ_3_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'default__freq__3=')"
        if [ "$SCAN_FREQ_3_LINE" != "" ]; then
          SCAN_FREQ_3="$(echo "$SCAN_FREQ_3_LINE" | sed 's/default__freq__3=\"//' | sed 's/\"//')"
          SCAN_FREQ_VALUES=3
          SCAN_FREQ_4_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'default__freq__4=')"
          if [ "$SCAN_FREQ_4_LINE" != "" ]; then
            SCAN_FREQ_4="$(echo "$SCAN_FREQ_4_LINE" | sed 's/default__freq__4=\"//' | sed 's/\"//')"
            SCAN_FREQ_VALUES=4
          fi
        fi
      fi
    fi
  fi

  # Convert to multi-FREQ format if in the old format
  if [ "$SCAN_FREQ_VALUES" == 0 ]; then
    # Clear FREQ value off of first line
    sed -i "/^    freq:/c\    freq:"  /home/pi/ryde/config.yaml
    # Create the blank second line
    sed -i '/^    freq:/!{p;d;};a \        -' /home/pi/ryde/config.yaml
    # Put it on the second line
    sed -i "/^    freq:/!b;n;c\        - $DEFAULT_FREQ" /home/pi/ryde/config.yaml
    # So now the file is as if it was set up for multiples, but with one value
    SCAN_FREQ_VALUES=1
    SCAN_FREQ_1=$DEFAULT_FREQ
  fi

  # Amend FREQ 1

  SCAN_FREQ_1=$(whiptail --inputbox "Enter the first frequency in kHz" 8 78 $SCAN_FREQ_1 --title "Frequency 1 Entry Menu" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    # Put it on the second line
    sed -i "/^    freq:/!b;n;c\        - $SCAN_FREQ_1" /home/pi/ryde/config.yaml
  fi

  # At this stage FREQ1 has been entered, so ask for FREQ 2

  SCAN_FREQ_2=$(whiptail --inputbox "Enter the second frequency in kHz (enter 0 for no more freqs)" 8 78 $SCAN_FREQ_2 --title "Frequency 2 Entry Menu" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then  # value has been changed
    if [ "$SCAN_FREQ_VALUES" == "1" ] ; then  # Previously only a single FREQ
      if [ "$SCAN_FREQ_2" != "0" ]; then      # new valid FREQ entered (else do nothing)
        # row 3 does not exist, so create it
        sed -i '/^    freq:/!{p;d;};n;a \        -' /home/pi/ryde/config.yaml
        # replace new row 3 with $SCAN_FREQ_2
        sed -i "/^    freq:/!b;n;n;c\        - $SCAN_FREQ_2" /home/pi/ryde/config.yaml
        # and set the FREQ scan values to 2
        SCAN_FREQ_VALUES=2
      fi
    else                                    # Previously multiple FREQs
      if [ "$SCAN_FREQ_2" != "0" ]; then      # new valid FREQ entered
        # so replace row 3 with new $SCAN_FREQ_2
        sed -i "/^    freq:/!b;n;n;c\        - $SCAN_FREQ_2" /home/pi/ryde/config.yaml
      else                                  # no more scanning FREQs, so delete lines
        if [ "$SCAN_FREQ_VALUES" == "4" ]; then  # delete row 3
          sed -i "/^    freq:/!b;n;n;d" /home/pi/ryde/config.yaml
          SCAN_FREQ_VALUES=3  # and decrement the number of rows
        fi
        if [ "$SCAN_FREQ_VALUES" == "3" ]; then  # delete row 3
          sed -i "/^    freq:/!b;n;n;d" /home/pi/ryde/config.yaml
          SCAN_FREQ_VALUES=2  # and decrement the number of rows
        fi
        if [ "$SCAN_FREQ_VALUES" == "2" ]; then  # delete row 3
          sed -i "/^    freq:/!b;n;n;d" /home/pi/ryde/config.yaml
          SCAN_FREQ_VALUES=1  # and decrement the number of rows
        fi
      fi
    fi
  fi

  # At this stage FREQ2 has been entered, or SCAN_FREQ_VALUES=1 and we will do nothing more

  if [ "$SCAN_FREQ_VALUES" != "1" ]; then
    SCAN_FREQ_3=$(whiptail --inputbox "Enter the third frequency in kHz (enter 0 for no more freqs)" 8 78 $SCAN_FREQ_3 --title "Frequency 3 Entry Menu" 3>&1 1>&2 2>&3)
    if [ $? -eq 0 ]; then  # value has been changed
      if [ "$SCAN_FREQ_VALUES" == "2" ] ; then  # Previously only 2 FREQs
        if [ "$SCAN_FREQ_3" != "0" ]; then      # new valid FREQ entered (else do nothing)
          # row 4 does not exist, so create it
          sed -i '/^    freq:/!{p;d;};n;n;a \        -' /home/pi/ryde/config.yaml
          # replace new row 4 with $SCAN_FREQ_3
          sed -i "/^    freq:/!b;n;n;n;c\        - $SCAN_FREQ_3" /home/pi/ryde/config.yaml
          # and set the FREQ scan values to 3
          SCAN_FREQ_VALUES=3
        fi
      else                                    # Previously multiple FREQs
        if [ "$SCAN_FREQ_3" != "0" ]; then      # new valid FREQ entered
          # so replace row 4 with new $SCAN_FREQ_3
          sed -i "/^    freq:/!b;n;n;n;c\        - $SCAN_FREQ_3" /home/pi/ryde/config.yaml
        else                                  # no more scanning FREQs, so delete lines
          if [ "$SCAN_FREQ_VALUES" == "4" ]; then  # delete row 4
            sed -i "/^    freq:/!b;n;n;n;d" /home/pi/ryde/config.yaml
            SCAN_FREQ_VALUES=3  # and decrement the number of rows
          fi
          if [ "$SCAN_FREQ_VALUES" == "3" ]; then  # delete row 4
            sed -i "/^    freq:/!b;n;n;n;d" /home/pi/ryde/config.yaml
            SCAN_FREQ_VALUES=2  # and decrement the number of rows
          fi
        fi
      fi
    fi
    # At this stage FREQ3 has been entered, or SCAN_FREQ_VALUES=2 and we will do nothing more

    if [ "$SCAN_FREQ_VALUES" != "2" ]; then
      SCAN_FREQ_4=$(whiptail --inputbox "Enter the fourth frequency in kHz (enter 0 for no more freqs)" 8 78 $SCAN_FREQ_4 --title "Frequency 4 Entry Menu" 3>&1 1>&2 2>&3)
      if [ $? -eq 0 ]; then  # value has been changed
        if [ "$SCAN_FREQ_VALUES" == "3" ] ; then  # Previously only 3 FREQs
          if [ "$SCAN_FREQ_4" != "0" ]; then      # new valid FREQ entered (else do nothing)
            # row 5 does not exist, so create it
            sed -i '/^    freq:/!{p;d;};n;n;n;a \        -' /home/pi/ryde/config.yaml
            # replace new row 5 with $SCAN_FREQ_4
            sed -i "/^    freq:/!b;n;n;n;n;c\        - $SCAN_FREQ_4" /home/pi/ryde/config.yaml
            # and set the FREQ scan values to 4
            SCAN_FREQ_VALUES=4
          fi
        else                                    # Previously 4 FREQs
          if [ "$SCAN_FREQ_3" != "0" ]; then      # new valid FREQ entered
            # so replace row 5 with new $SCAN_FREQ_4
            sed -i "/^    freq:/!b;n;n;n;n;c\        - $SCAN_FREQ_4" /home/pi/ryde/config.yaml
          else                                  # no more scanning FREQs, so delete lines
            if [ "$SCAN_FREQ_VALUES" == "4" ]; then  # delete row 5
              sed -i "/^    freq:/!b;n;n;n;n;d" /home/pi/ryde/config.yaml
              SCAN_FREQ_VALUES=3  # and decrement the number of rows
            fi
          fi
        fi
      fi
    fi
  fi
}



do_Set_SR()
{
  DEFAULT_SR=0
  SCAN_SR_1=0
  SCAN_SR_2=0
  SCAN_SR_3=0
  SCAN_SR_4=0

  # Read and trim the default SR Values
  DEFAULT_SR_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'default__sr=')"
  if [ "$DEFAULT_SR_LINE" != "" ]; then
    DEFAULT_SR="$(echo "$DEFAULT_SR_LINE" | sed 's/default__sr=\"//' | sed 's/\"//')"
    SCAN_SR_VALUES=0
  else
    SCAN_SR_1_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'default__sr__1=')"
    if [ "$SCAN_SR_1_LINE" != "" ]; then
      SCAN_SR_1="$(echo "$SCAN_SR_1_LINE" | sed 's/default__sr__1=\"//' | sed 's/\"//')"
      SCAN_SR_VALUES=1
      SCAN_SR_2_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'default__sr__2=')"
      if [ "$SCAN_SR_2_LINE" != "" ]; then
        SCAN_SR_2="$(echo "$SCAN_SR_2_LINE" | sed 's/default__sr__2=\"//' | sed 's/\"//')"
        SCAN_SR_VALUES=2
        SCAN_SR_3_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'default__sr__3=')"
        if [ "$SCAN_SR_3_LINE" != "" ]; then
          SCAN_SR_3="$(echo "$SCAN_SR_3_LINE" | sed 's/default__sr__3=\"//' | sed 's/\"//')"
          SCAN_SR_VALUES=3
          SCAN_SR_4_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'default__sr__4=')"
          if [ "$SCAN_SR_4_LINE" != "" ]; then
            SCAN_SR_4="$(echo "$SCAN_SR_4_LINE" | sed 's/default__sr__4=\"//' | sed 's/\"//')"
            SCAN_SR_VALUES=4
          fi
        fi
      fi
    fi
  fi

  if [ "$SCAN_SR_VALUES" != "0" ]; then  # In scanning SR mode, so convert back to single SR
    
    # Set the default SR to the first scanning SR
    DEFAULT_SR=$SCAN_SR_1

    # Delete the scanning SR lines
    if [ "$SCAN_SR_VALUES" == "4" ]; then  # delete row 2
      sed -i "/^    sr:/!b;n;d" /home/pi/ryde/config.yaml
      SCAN_SR_VALUES=3  # and decrement the number of rows
    fi
    if [ "$SCAN_SR_VALUES" == "3" ]; then  # delete row 2
      sed -i "/^    sr:/!b;n;d" /home/pi/ryde/config.yaml
      SCAN_SR_VALUES=2  # and decrement the number of rows
    fi
    if [ "$SCAN_SR_VALUES" == "2" ]; then  # delete row 2
      sed -i "/^    sr:/!b;n;d" /home/pi/ryde/config.yaml
      SCAN_SR_VALUES=1  # and decrement the number of rows
    fi
    if [ "$SCAN_SR_VALUES" == "1" ]; then  # delete row 2
      sed -i "/^    sr:/!b;n;d" /home/pi/ryde/config.yaml
      SCAN_SR_VALUES=0  # and decrement the number of rows
    fi

    # Write the default SR to the SR line
    sed -i "/^    sr:/c\    sr:   $DEFAULT_SR"  /home/pi/ryde/config.yaml

  fi

  DEFAULT_SR=$(whiptail --inputbox "Enter the SR in kS" 8 78 $DEFAULT_SR --title "Symbol Rate Entry Menu" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    sed -i "/^    sr:/c\    sr:   $DEFAULT_SR"  /home/pi/ryde/config.yaml
  fi
}

do_Set_Scan_SR()
{
  DEFAULT_SR=0
  SCAN_SR_1=0
  SCAN_SR_2=0
  SCAN_SR_3=0
  SCAN_SR_4=0

  # Read and trim the default SR Values
  DEFAULT_SR_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'default__sr=')"
  if [ "$DEFAULT_SR_LINE" != "" ]; then
    DEFAULT_SR="$(echo "$DEFAULT_SR_LINE" | sed 's/default__sr=\"//' | sed 's/\"//')"
    SCAN_SR_VALUES=0
  else
    SCAN_SR_1_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'default__sr__1=')"
    if [ "$SCAN_SR_1_LINE" != "" ]; then
      SCAN_SR_1="$(echo "$SCAN_SR_1_LINE" | sed 's/default__sr__1=\"//' | sed 's/\"//')"
      SCAN_SR_VALUES=1
      SCAN_SR_2_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'default__sr__2=')"
      if [ "$SCAN_SR_2_LINE" != "" ]; then
        SCAN_SR_2="$(echo "$SCAN_SR_2_LINE" | sed 's/default__sr__2=\"//' | sed 's/\"//')"
        SCAN_SR_VALUES=2
        SCAN_SR_3_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'default__sr__3=')"
        if [ "$SCAN_SR_3_LINE" != "" ]; then
          SCAN_SR_3="$(echo "$SCAN_SR_3_LINE" | sed 's/default__sr__3=\"//' | sed 's/\"//')"
          SCAN_SR_VALUES=3
          SCAN_SR_4_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'default__sr__4=')"
          if [ "$SCAN_SR_4_LINE" != "" ]; then
            SCAN_SR_4="$(echo "$SCAN_SR_4_LINE" | sed 's/default__sr__4=\"//' | sed 's/\"//')"
            SCAN_SR_VALUES=4
          fi
        fi
      fi
    fi
  fi

  # Convert to multi-SR format if in the old format
  if [ "$SCAN_SR_VALUES" == 0 ]; then
    # Clear SR value off of first line
    sed -i "/^    sr:/c\    sr:"  /home/pi/ryde/config.yaml
    # Create the blank second line
    sed -i '/^    sr:/!{p;d;};a \        -' /home/pi/ryde/config.yaml
    # Put it on the second line
    sed -i "/^    sr:/!b;n;c\        - $DEFAULT_SR" /home/pi/ryde/config.yaml
    # So now the file is as if it was set up for multiples, but with one value
    SCAN_SR_VALUES=1
    SCAN_SR_1=$DEFAULT_SR
  fi

  # Amend SR 1

  SCAN_SR_1=$(whiptail --inputbox "Enter the first SR in kS" 8 78 $SCAN_SR_1 --title "Symbol Rate 1 Entry Menu" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    # Put it on the second line
    sed -i "/^    sr:/!b;n;c\        - $SCAN_SR_1" /home/pi/ryde/config.yaml
  fi

  # At this stage SR1 has been entered, so ask for SR 2

  SCAN_SR_2=$(whiptail --inputbox "Enter the second SR in kS (enter 0 for no more SRs)" 8 78 $SCAN_SR_2 --title "Symbol Rate 2 Entry Menu" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then  # value has been changed
    if [ "$SCAN_SR_VALUES" == "1" ] ; then  # Previously only a single SR
      if [ "$SCAN_SR_2" != "0" ]; then      # new valid SR entered (else do nothing)
        # row 3 does not exist, so create it
        sed -i '/^    sr:/!{p;d;};n;a \        -' /home/pi/ryde/config.yaml
        # replace new row 3 with $SCAN_SR_2
        sed -i "/^    sr:/!b;n;n;c\        - $SCAN_SR_2" /home/pi/ryde/config.yaml
        # and set the SR scan values to 2
        SCAN_SR_VALUES=2
      fi
    else                                    # Previously multiple SRs
      if [ "$SCAN_SR_2" != "0" ]; then      # new valid SR entered
        # so replace row 3 with new $SCAN_SR_2
        sed -i "/^    sr:/!b;n;n;c\        - $SCAN_SR_2" /home/pi/ryde/config.yaml
      else                                  # no more scanning SRs, so delete lines
        if [ "$SCAN_SR_VALUES" == "4" ]; then  # delete row 3
          sed -i "/^    sr:/!b;n;n;d" /home/pi/ryde/config.yaml
          SCAN_SR_VALUES=3  # and decrement the number of rows
        fi
        if [ "$SCAN_SR_VALUES" == "3" ]; then  # delete row 3
          sed -i "/^    sr:/!b;n;n;d" /home/pi/ryde/config.yaml
          SCAN_SR_VALUES=2  # and decrement the number of rows
        fi
        if [ "$SCAN_SR_VALUES" == "2" ]; then  # delete row 3
          sed -i "/^    sr:/!b;n;n;d" /home/pi/ryde/config.yaml
          SCAN_SR_VALUES=1  # and decrement the number of rows
        fi
      fi
    fi
  fi

  # At this stage SR2 has been entered, or SCAN_SR_VALUES=1 and we will do nothing more

  if [ "$SCAN_SR_VALUES" != "1" ]; then
    SCAN_SR_3=$(whiptail --inputbox "Enter the third SR in kS (enter 0 for no more SRs)" 8 78 $SCAN_SR_3 --title "Symbol Rate 3 Entry Menu" 3>&1 1>&2 2>&3)
    if [ $? -eq 0 ]; then  # value has been changed
      if [ "$SCAN_SR_VALUES" == "2" ] ; then  # Previously only 2 SRs
        if [ "$SCAN_SR_3" != "0" ]; then      # new valid SR entered (else do nothing)
          # row 4 does not exist, so create it
          sed -i '/^    sr:/!{p;d;};n;n;a \        -' /home/pi/ryde/config.yaml
          # replace new row 4 with $SCAN_SR_3
          sed -i "/^    sr:/!b;n;n;n;c\        - $SCAN_SR_3" /home/pi/ryde/config.yaml
          # and set the SR scan values to 3
          SCAN_SR_VALUES=3
        fi
      else                                    # Previously multiple SRs
        if [ "$SCAN_SR_3" != "0" ]; then      # new valid SR entered
          # so replace row 4 with new $SCAN_SR_3
          sed -i "/^    sr:/!b;n;n;n;c\        - $SCAN_SR_3" /home/pi/ryde/config.yaml
        else                                  # no more scanning SRs, so delete lines
          if [ "$SCAN_SR_VALUES" == "4" ]; then  # delete row 4
            sed -i "/^    sr:/!b;n;n;n;d" /home/pi/ryde/config.yaml
            SCAN_SR_VALUES=3  # and decrement the number of rows
          fi
          if [ "$SCAN_SR_VALUES" == "3" ]; then  # delete row 4
            sed -i "/^    sr:/!b;n;n;n;d" /home/pi/ryde/config.yaml
            SCAN_SR_VALUES=2  # and decrement the number of rows
          fi
        fi
      fi
    fi
    # At this stage SR3 has been entered, or SCAN_SR_VALUES=2 and we will do nothing more

    if [ "$SCAN_SR_VALUES" != "2" ]; then
      SCAN_SR_4=$(whiptail --inputbox "Enter the fourth SR in kS (enter 0 for no more SRs)" 8 78 $SCAN_SR_4 --title "Symbol Rate 4 Entry Menu" 3>&1 1>&2 2>&3)
      if [ $? -eq 0 ]; then  # value has been changed
        if [ "$SCAN_SR_VALUES" == "3" ] ; then  # Previously only 3 SRs
          if [ "$SCAN_SR_4" != "0" ]; then      # new valid SR entered (else do nothing)
            # row 5 does not exist, so create it
            sed -i '/^    sr:/!{p;d;};n;n;n;a \        -' /home/pi/ryde/config.yaml
            # replace new row 5 with $SCAN_SR_4
            sed -i "/^    sr:/!b;n;n;n;n;c\        - $SCAN_SR_4" /home/pi/ryde/config.yaml
            # and set the SR scan values to 4
            SCAN_SR_VALUES=4
          fi
        else                                    # Previously 4 SRs
          if [ "$SCAN_SR_3" != "0" ]; then      # new valid SR entered
            # so replace row 5 with new $SCAN_SR_4
            sed -i "/^    sr:/!b;n;n;n;n;c\        - $SCAN_SR_4" /home/pi/ryde/config.yaml
          else                                  # no more scanning SRs, so delete lines
            if [ "$SCAN_SR_VALUES" == "4" ]; then  # delete row 5
              sed -i "/^    sr:/!b;n;n;n;n;d" /home/pi/ryde/config.yaml
              SCAN_SR_VALUES=3  # and decrement the number of rows
            fi
          fi
        fi
      fi
    fi
  fi
}


do_Check_RC_Codes()
{
  sudo ir-keytable -p all >/dev/null 2>/dev/null
  reset
  echo "After CTRL-C, type menu to get back to the Menu System"
  echo
  ir-keytable -t
}

do_Set_TSTimeout()
{
  # Read and trim the current TS Timeout
  TS_TIMEOUT_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'longmynd__tstimeout=')"
  TS_TIMEOUT="$(echo "$TS_TIMEOUT_LINE" | sed 's/longmynd__tstimeout=\"//' | sed 's/\"//')"

  TS_TIMEOUT=$(whiptail --inputbox "Enter the new TS Timeout in mS (default 5000 - ie 5 seconds)" 8 78 $TS_TIMEOUT --title "TS TimeOut Entry Menu" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    sed -i "/    tstimeout:/c\    tstimeout: $TS_TIMEOUT" /home/pi/ryde/config.yaml
  fi
}

do_Restore_Factory()
{
  cp /home/pi/ryde-build/config.yaml /home/pi/ryde/config.yaml

  # Wait here until user presses a key
  whiptail --title "Factory Setting Restored" --msgbox "Touch any key to continue.  You will need to reselect your remote control type." 8 78
}


do_Settings()
{
  menuchoice=$(whiptail --title "Advanced Settings Menu" --menu "Select Choice" 16 78 10 \
    "1 Tuner Timeout" "Adjust the Tuner Reset Time when no valid TS " \
    "2 Restore Factory" "Reset all settings to default" \
      3>&2 2>&1 1>&3)
    case "$menuchoice" in
      1\ *) do_Set_TSTimeout ;;
      2\ *) do_Restore_Factory ;;
    esac
}


do_Set_Bands()
{
  menuchoice=$(whiptail --title "Select band for Amendment" --menu "Select Choice" 16 78 10 \
    "1 QO-100" "Set the LNB Offset frequency for QO-100" \
    "2 Direct" "Add an LNB Offset for the Direct Band" \
      3>&2 2>&1 1>&3)
    case "$menuchoice" in
      1\ *) AMEND_BAND="QO-100" ;;
      2\ *) AMEND_BAND="Direct"  ;;
    esac

  case "$AMEND_BAND" in
    "QO-100")
      # Read and trim the current LO frequency
      ## Note that band names with hyphens do not parse - so this is a bodge.
      LO_FREQ_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands____lofreq=')"
      LO_FREQ="$(echo "$LO_FREQ_LINE" | sed 's/bands____lofreq=\"//' | sed 's/\"//')"

      LO_FREQ=$(whiptail --inputbox "Enter the new QO-100 LO frequecy in kHz (for example 9750000)" 8 78 $LO_FREQ --title "LO Frequency Entry Menu" 3>&1 1>&2 2>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    QO-100:/!b;n;c\        lofreq: $LO_FREQ" /home/pi/ryde/config.yaml
      fi

      # Read and trim the current LO side
      ## Note that band names with hyphens do not parse - so this is a bodge.
      LO_SIDE_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands____loside=')"
      LO_SIDE="$(echo "$LO_SIDE_LINE" | sed 's/bands____loside=\"//' | sed 's/\"//')"

      if [ "$LO_FREQ" != "0" ]; then  # Set LO side

        Radio1=OFF
        Radio2=OFF

        case "$LO_SIDE" in
          "LOW")
            Radio1=ON
          ;;
          "HIGH")
            Radio2=ON
          ;;
          *)
            Radio1=ON
          ;;
        esac
  
        LO_SIDE=$(whiptail --title "Select the LO Side for the QO-100 Band" --radiolist \
          "Select Choice" 20 78 5 \
          "LOW" "LO frequency below signal frequency (normal for QO-100)" $Radio1 \
          "HIGH" "LO frequency below signal frequency" $Radio2 \
          3>&2 2>&1 1>&3)
        if [ $? -eq 0 ]; then
        sed -i "/    QO-100:/!b;n;n;c\        loside: $LO_SIDE" /home/pi/ryde/config.yaml
        fi
      fi
    ;;

    "Direct")
      # Read and trim the current LO frequency
      ## Note that band names with hyphens do not parse - so this is a bodge.
      LO_FREQ_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__Direct__lofreq=')"
      LO_FREQ="$(echo "$LO_FREQ_LINE" | sed 's/bands__Direct__lofreq=\"//' | sed 's/\"//')"

      LO_FREQ=$(whiptail --inputbox "Enter the new Direct LO frequecy in kHz (for example 0)" 8 78 $LO_FREQ --title "LO Frequency Entry Menu" 3>&1 1>&2 2>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    Direct:/!b;n;c\        lofreq: $LO_FREQ" /home/pi/ryde/config.yaml
      fi

      # Read and trim the current LO side
      ## Note that band names with hyphens do not parse - so this is a bodge.
      LO_SIDE_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__Direct__loside=')"
      LO_SIDE="$(echo "$LO_SIDE_LINE" | sed 's/bands__Direct__loside=\"//' | sed 's/\"//')"

      if [ "$LO_FREQ" != "0" ]; then  # Set LO side

        Radio1=OFF
        Radio2=OFF

        case "$LO_SIDE" in
          "LOW")
            Radio1=ON
          ;;
          "HIGH")
            Radio2=ON
          ;;
          *)
            Radio1=ON
          ;;
        esac
  
        LO_SIDE=$(whiptail --title "Select the LO Side for the Direct Band" --radiolist \
          "Select Choice" 20 78 5 \
          "LOW" "LO frequency below signal frequency" $Radio1 \
          "HIGH" "LO frequency below signal frequency" $Radio2 \
          3>&2 2>&1 1>&3)
        if [ $? -eq 0 ]; then
        sed -i "/    Direct:/!b;n;n;c\        loside: $LO_SIDE" /home/pi/ryde/config.yaml
        fi
      fi
    ;;
  esac
}

do_Set_Default_Band()
{
  # Read and trim the default port
  DEFAULT_BAND_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'default__band=')"
  DEFAULT_BAND="$(echo "$DEFAULT_BAND_LINE" | sed 's/default__band=\"//' | sed 's/\"//')"

  Radio1=OFF
  Radio2=OFF

  case "$DEFAULT_BAND" in
    "*bandqo100")
      Radio1=ON
      DEFAULT_BAND_LABEL="QO-100"
    ;;
    "*banddirect")
      Radio2=ON
      DEFAULT_BAND_LABEL="Direct"
    ;;
    *)
      Radio1=ON
      DEFAULT_BAND_LABEL="QO-100"
    ;;
  esac
  
  NEW_DEFAULT_BAND_LABEL=$(whiptail --title "Select the new Default Band" --radiolist \
    "Select Choice" 20 78 5 \
    "QO-100" "With LNB Offset" $Radio1 \
    "Direct" "Frequency in range 144 - 2450 MHz" $Radio2 \
    3>&2 2>&1 1>&3)
  if [ $? -eq 0 ]; then
    case "$NEW_DEFAULT_BAND_LABEL" in
      "QO-100")
        DEFAULT_BAND="*bandqo100"
      ;;
      "Direct")
        DEFAULT_BAND="*banddirect"
      ;;
      *)
        DEFAULT_BAND="*bandqo100"
      ;;
    esac
    sed -i "/    band:/c\    band: $DEFAULT_BAND" /home/pi/ryde/config.yaml
  fi
}

do_Set_Port()
{
  # Read and trim the default port
  DEFAULT_PORT_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'default__port=')"
  DEFAULT_PORT="$(echo "$DEFAULT_PORT_LINE" | sed 's/default__port=\"//' | sed 's/\"//')"

  Radio1=OFF
  Radio2=OFF

  case "$DEFAULT_PORT" in
    "TOP")
      Radio1=ON
    ;;
    "BOTTOM")
      Radio2=ON
    ;;
    *)
      Radio1=ON
    ;;
  esac
  
  NEW_DEFAULT_PORT=$(whiptail --title "Select the new Default Port" --radiolist \
    "Select Choice" 20 78 5 \
    "TOP" "Top LNB Port    (Socket A)" $Radio1 \
    "BOTTOM" "Bottom LNB Port (Socket B)" $Radio2 \
    3>&2 2>&1 1>&3)
  if [ $? -eq 0 ]; then
    sed -i "/port:/c\    port: $NEW_DEFAULT_PORT" /home/pi/ryde/config.yaml
  fi
}

do_Set_Polarity()
{
  # Read and trim the default polarity
  DEFAULT_POL_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'default__pol=')"
  DEFAULT_POL="$(echo "$DEFAULT_POL_LINE" | sed 's/default__pol=\"//' | sed 's/\"//')"

  Radio1=OFF
  Radio2=OFF
  Radio3=OFF

  case "$DEFAULT_POL" in
    "NONE")
      Radio1=ON
    ;;
    "VERTICAL")
      Radio2=ON
    ;;
    "HORIZONTAL")
      Radio3=ON
    ;;
    *)
      Radio1=ON
    ;;
  esac
  
  NEW_DEFAULT_POL=$(whiptail --title "Select the new Default Polarity" --radiolist \
    "Select Choice" 20 78 5 \
    "NONE" "No LNB Voltage" $Radio1 \
    "VERTICAL" "Vertical Polarity 13 Volts" $Radio2 \
    "HORIZONTAL" "Horizontal Polarity 18 Volts (QO-100)" $Radio3 \
    3>&2 2>&1 1>&3)
  if [ $? -eq 0 ]; then
    sed -i "/pol:/c\    pol:  $NEW_DEFAULT_POL" /home/pi/ryde/config.yaml
  fi
}


do_Set_Defaults()
{
  menuchoice=$(whiptail --title "Start-up Settings Menu" --menu "Select Choice" 16 78 10 \
    "1 Band" "Set the start-up Band" \
    "2 Freq" "Set a Single Start-up Receive Frequency" \
    "3 Scan Freqs" "Set Multiple Receive Frequencies for Scanning" \
    "4 SR" "Set a Single Start-up Receive Symbol Rate" \
    "5 Scan SRs" "Set Multiple Receive Symbol Rates for Scanning" \
    "6 Port" "Set which tuner socket is used" \
    "7 Polarity" "Switch LNB Bias Voltage" \
      3>&2 2>&1 1>&3)
    case "$menuchoice" in
      1\ *) do_Set_Default_Band ;;
      2\ *) do_Set_Freq ;;
      3\ *) do_Set_Scan_Freq ;;
      4\ *) do_Set_SR ;;
      5\ *) do_Set_Scan_SR ;;
      6\ *) do_Set_Port ;;
      7\ *) do_Set_Polarity ;;
    esac
}


do_Reboot()
{
  sudo reboot now
}

do_Nothing()
{
  :
}

do_Norm_HDMI()
{
  # change #enable_tvout=1 or enable_tvout=1 to #enable_tvout=1

  # first check if "#enable_tvout=1" is in /boot/config.txt
  grep -q "#enable_tvout=1" /boot/config.txt
  if [ $? -ne 0 ]; then  #  "#enable_tvout=1" is not there, so check if "enable_tvout=1" is there
    grep -q "enable_tvout=1" /boot/config.txt
    if [ $? -eq 0 ]; then  # "enable_tvout=1" is there, so replace it with "#enable_tvout=1"
      sudo sed -i '/enable_tvout=1/c\#enable_tvout=1' /boot/config.txt  >/dev/null 2>/dev/null
    else                   # not there, so append the commented statement
      sudo bash -c 'echo " " >> /boot/config.txt '
      sudo bash -c 'echo "# Uncomment to enable Comp Vid output" >> /boot/config.txt '
      sudo bash -c 'echo "#enable_tvout=1" >> /boot/config.txt '
      sudo bash -c 'echo " " >> /boot/config.txt '
    fi
  fi

  # change #hdmi_safe=1 or hdmi_safe=1 to #hdmi_safe=1

  # first check if "#hdmi_safe=1" is in /boot/config.txt
  grep -q "#hdmi_safe=1" /boot/config.txt
  if [ $? -ne 0 ]; then  #  "#hdmi_safe=1" is not there, so check if "hdmi_safe=1" is there
    grep -q "hdmi_safe=1" /boot/config.txt
    if [ $? -eq 0 ]; then  # "hdmi_safe=1" is there, so replace it with "#hdmi_safe=1"
      sudo sed -i '/hdmi_safe=1/c\#hdmi_safe=1' /boot/config.txt  >/dev/null 2>/dev/null
    else                   # not there, so append the commented statement
      sudo bash -c 'echo " " >> /boot/config.txt '
      sudo bash -c 'echo "# uncomment if you get no picture on HDMI for a default safe mode" >> /boot/config.txt '
      sudo bash -c 'echo "#hdmi_safe=1" >> /boot/config.txt '
      sudo bash -c 'echo " " >> /boot/config.txt '
    fi
  fi
}



do_Safe_HDMI()
{
  # change #enable_tvout=1 or enable_tvout=1 to #enable_tvout=1

  # first check if "#enable_tvout=1" is in /boot/config.txt
  grep -q "#enable_tvout=1" /boot/config.txt
  if [ $? -ne 0 ]; then  #  "#enable_tvout=1" is not there, so check if "enable_tvout=1" is there
    grep -q "enable_tvout=1" /boot/config.txt
    if [ $? -eq 0 ]; then  # "enable_tvout=1" is there, so replace it with "#enable_tvout=1"
      sudo sed -i '/enable_tvout=1/c\#enable_tvout=1' /boot/config.txt  >/dev/null 2>/dev/null
    else                   # not there, so append the commented statement
      sudo bash -c 'echo " " >> /boot/config.txt '
      sudo bash -c 'echo "# Uncomment to enable Comp Vid output" >> /boot/config.txt '
      sudo bash -c 'echo "#enable_tvout=1" >> /boot/config.txt '
      sudo bash -c 'echo " " >> /boot/config.txt '
    fi
  fi

  # change #hdmi_safe=1 or hdmi_safe=1 to hdmi_safe=1

  # first check if "#hdmi_safe=1" is in /boot/config.txt
  grep -q "#hdmi_safe=1" /boot/config.txt
  if [ $? -eq 0 ]; then  #  "#hdmi_safe=1" is there, so change it to "hdmi_safe=1"
    sudo sed -i '/#hdmi_safe=1/c\hdmi_safe=1' /boot/config.txt  >/dev/null 2>/dev/null
  else                   # "#hdmi_safe=1" is not there so check "hdmi_safe=1" is there
    grep -q "hdmi_safe=1" /boot/config.txt
    if [ $? -ne 0 ]; then  # "hdmi_safe=1" is not there, so add it (else do nothing)
      sudo bash -c 'echo " " >> /boot/config.txt '
      sudo bash -c 'echo "# uncomment if you get no picture on HDMI for a default safe mode" >> /boot/config.txt '
      sudo bash -c 'echo "hdmi_safe=1" >> /boot/config.txt '
      sudo bash -c 'echo " " >> /boot/config.txt '
    fi
  fi
}


do_Comp_Vid_PAL()
{
  # change #hdmi_safe=1 or hdmi_safe=1 to #hdmi_safe=1

  # first check if "#hdmi_safe=1" is in /boot/config.txt
  grep -q "#hdmi_safe=1" /boot/config.txt
  if [ $? -ne 0 ]; then  #  "#hdmi_safe=1" is not there, so check if "hdmi_safe=1" is there
    grep -q "hdmi_safe=1" /boot/config.txt
    if [ $? -eq 0 ]; then  # "hdmi_safe=1" is there, so replace it with "#hdmi_safe=1"
      sudo sed -i '/hdmi_safe=1/c\#hdmi_safe=1' /boot/config.txt  >/dev/null 2>/dev/null
    else                   # not there, so append the commented statement
      sudo bash -c 'echo " " >> /boot/config.txt '
      sudo bash -c 'echo "# uncomment if you get no picture on HDMI for a default safe mode" >> /boot/config.txt '
      sudo bash -c 'echo "#hdmi_safe=1" >> /boot/config.txt '
      sudo bash -c 'echo " " >> /boot/config.txt '
    fi
  fi

  #change #sdtv_mode=1/2 or sdtv_mode=1/2 to sdtv_mode=2

  # first check if "#sdtv_mode=2" is in /boot/config.txt
  grep -q "#sdtv_mode=2" /boot/config.txt
  if [ $? -eq 0 ]; then  #  "#sdtv_mode=2" is there, so change it to "sdtv_mode=2"
    sudo sed -i '/#sdtv_mode=2/c\sdtv_mode=2' /boot/config.txt  >/dev/null 2>/dev/null
  else                   # "#sdtv_mode=2" is not there so check if "#sdtv_mode=1" is there
    grep -q "#sdtv_mode=1" /boot/config.txt
    if [ $? -eq 0 ]; then  #  "#sdtv_mode=1" is there, so change it to "sdtv_mode=2"
      sudo sed -i '/#sdtv_mode=1/c\sdtv_mode=2' /boot/config.txt  >/dev/null 2>/dev/null
    else                   # neither "#sdtv_mode=2" nor "#sdtv_mode=1" are there
      grep -q "sdtv_mode=1" /boot/config.txt  # so check if "sdtv_mode=1" is there
      if [ $? -eq 0 ]; then  #  "sdtv_mode=1" is there, so change it to "sdtv_mode=2"
        sudo sed -i '/sdtv_mode=1/c\sdtv_mode=2' /boot/config.txt  >/dev/null 2>/dev/null
      else       # check if "sdtv_mode=2" is there and add it if not
        grep -q "sdtv_mode=2" /boot/config.txt  
        if [ $? -ne 0 ]; then  # "sdtv_mode=2" is not there, so add it at the end (else do nothing)
          sudo bash -c 'echo " " >> /boot/config.txt '
          sudo bash -c 'echo "# uncomment for composite PAL" >> /boot/config.txt '
          sudo bash -c 'echo "sdtv_mode=2" >> /boot/config.txt '
          sudo bash -c 'echo " " >> /boot/config.txt '
        fi
      fi
    fi
  fi

  # change #enable_tvout=1 or enable_tvout=1 to enable_tvout=1 (Add if not present)

  # first check if "#enable_tvout=1" is in /boot/config.txt
  grep -q "#enable_tvout=1" /boot/config.txt
  if [ $? -eq 0 ]; then  # "#enable_tvout=1" is there, so replace it with "enable_tvout=1"
    sudo sed -i '/#enable_tvout=1/c\enable_tvout=1' /boot/config.txt  >/dev/null 2>/dev/null
  else                   # "#enable_tvout=1" is not there, so check for "enable_tvout=1"
    grep -q "enable_tvout=1" /boot/config.txt
    if [ $? -ne 0 ]; then  #  "enable_tvout=1" is not there, so add it at the end (else do nothing)
      sudo bash -c 'echo " " >> /boot/config.txt '
      sudo bash -c 'echo "# Uncomment to enable Comp Vid output" >> /boot/config.txt '
      sudo bash -c 'echo "enable_tvout=1" >> /boot/config.txt '
      sudo bash -c 'echo " " >> /boot/config.txt '
    fi
  fi
}

do_Comp_Vid_NTSC()
{
  # change #hdmi_safe=1 or hdmi_safe=1 to #hdmi_safe=1

  # first check if "#hdmi_safe=1" is in /boot/config.txt
  grep -q "#hdmi_safe=1" /boot/config.txt
  if [ $? -ne 0 ]; then  #  "#hdmi_safe=1" is not there, so check if "hdmi_safe=1" is there
    grep -q "hdmi_safe=1" /boot/config.txt
    if [ $? -eq 0 ]; then  # "hdmi_safe=1" is there, so replace it with "#hdmi_safe=1"
      sudo sed -i '/hdmi_safe=1/c\#hdmi_safe=1' /boot/config.txt  >/dev/null 2>/dev/null
    else                   # not there, so append the commented statement
      sudo bash -c 'echo " " >> /boot/config.txt '
      sudo bash -c 'echo "# uncomment if you get no picture on HDMI for a default safe mode" >> /boot/config.txt '
      sudo bash -c 'echo "#hdmi_safe=1" >> /boot/config.txt '
      sudo bash -c 'echo " " >> /boot/config.txt '
    fi
  fi

  #change #sdtv_mode=1/2 or sdtv_mode=1/2 to sdtv_mode=1

  # first check if "#sdtv_mode=1" is in /boot/config.txt
  grep -q "#sdtv_mode=1" /boot/config.txt
  if [ $? -eq 0 ]; then  #  "#sdtv_mode=1" is there, so change it to "sdtv_mode=1"
    sudo sed -i '/#sdtv_mode=1/c\sdtv_mode=1' /boot/config.txt  >/dev/null 2>/dev/null
  else                   # "#sdtv_mode=1" is not there so check if "#sdtv_mode=2" is there
    grep -q "#sdtv_mode=2" /boot/config.txt
    if [ $? -eq 0 ]; then  #  "#sdtv_mode=2" is there, so change it to "sdtv_mode=1"
      sudo sed -i '/#sdtv_mode=2/c\sdtv_mode=1' /boot/config.txt  >/dev/null 2>/dev/null
    else                   # neither "#sdtv_mode=1" nor "#sdtv_mode=2" are there
      grep -q "sdtv_mode=2" /boot/config.txt  # so check if "sdtv_mode=2" is there
      if [ $? -eq 0 ]; then  #  "sdtv_mode=2" is there, so change it to "sdtv_mode=1"
        sudo sed -i '/sdtv_mode=2/c\sdtv_mode=1' /boot/config.txt  >/dev/null 2>/dev/null
      else       # check if "sdtv_mode=1" is there and add it if not
        grep -q "sdtv_mode=1" /boot/config.txt  
        if [ $? -ne 0 ]; then  # "sdtv_mode=1" is not there, so add it at the end (else do nothing)
          sudo bash -c 'echo " " >> /boot/config.txt '
          sudo bash -c 'echo "# uncomment for composite PAL" >> /boot/config.txt '
          sudo bash -c 'echo "sdtv_mode=1" >> /boot/config.txt '
          sudo bash -c 'echo " " >> /boot/config.txt '
        fi
      fi
    fi
  fi

  # change #enable_tvout=1 or enable_tvout=1 to enable_tvout=1 (Add if not present)

  # first check if "#enable_tvout=1" is in /boot/config.txt
  grep -q "#enable_tvout=1" /boot/config.txt
  if [ $? -eq 0 ]; then  # "#enable_tvout=1" is there, so replace it with "enable_tvout=1"
    sudo sed -i '/#enable_tvout=1/c\enable_tvout=1' /boot/config.txt  >/dev/null 2>/dev/null
  else                   # "#enable_tvout=1" is not there, so check for "enable_tvout=1"
    grep -q "enable_tvout=1" /boot/config.txt
    if [ $? -ne 0 ]; then  #  "enable_tvout=1" is not there, so add it at the end (else do nothing)
      sudo bash -c 'echo " " >> /boot/config.txt '
      sudo bash -c 'echo "# Uncomment to enable Comp Vid output" >> /boot/config.txt '
      sudo bash -c 'echo "enable_tvout=1" >> /boot/config.txt '
      sudo bash -c 'echo " " >> /boot/config.txt '
    fi
  fi
}


do_video_change()
{
  menuchoice=$(whiptail --title "Video Output Menu" --menu "Select Choice" 16 78 10 \
    "1 Normal HDMI" "Recommended Mode"  \
    "2 HDMI Safe Mode" "Use for HDMI Troubleshooting" \
    "3 PAL Composite Video" "Use the RPi Video Output Jack" \
    "4 NTSC Composite Video" "Use the RPi Video Output Jack" \
      3>&2 2>&1 1>&3)
    case "$menuchoice" in
        1\ *) do_Norm_HDMI ;;
        2\ *) do_Safe_HDMI ;;
        3\ *) do_Comp_Vid_PAL ;;
        4\ *) do_Comp_Vid_NTSC ;;
    esac

  menuchoice=$(whiptail --title "Reboot Now?" --menu "Reboot to Apply Changes?" 16 78 10 \
    "1 Yes" "Immediate Reboot"  \
    "2 No" "Apply changes at next Reboot" \
      3>&2 2>&1 1>&3)
    case "$menuchoice" in
        1\ *) do_Reboot ;;
        2\ *) do_Nothing ;;
    esac
}

do_Shutdown()
{
  sudo shutdown now
}

do_Exit()
{
  exit
}


do_shutdown_menu()
{
menuchoice=$(whiptail --title "Shutdown Menu" --menu "Select Choice" 16 78 10 \
    "1 Shutdown now" "Immediate Shutdown"  \
    "2 Reboot now" "Immediate reboot" \
    "3 Exit to Linux" "Exit menu to Command Prompt" \
      3>&2 2>&1 1>&3)
    case "$menuchoice" in
        1\ *) do_Shutdown ;;
        2\ *) do_Reboot ;;
        3\ *) do_Exit ;;
    esac
}

do_stop()
{
  sudo killall python3 >/dev/null 2>/dev/null
  
  sleep 0.3
  if pgrep -x "python3" >/dev/null 2>/dev/null
  then
    sudo killall -9 python3 >/dev/null 2>/dev/null
  fi
}

do_receive()
{
  /home/pi/ryde-build/rx.sh &

  # Wait here receiving until user presses a key
  whiptail --title "Receiving on on $FREQ_TEXT kHz at SR $SR_TEXT kS" --msgbox "Touch any key to stop receiving" 8 78
  do_stop
}


#********************************************* MAIN MENU *********************************
#************************* Execution of Console Menu starts here *************************

status=0

# Stop the Receiver
do_stop


# Loop round main menu
while [ "$status" -eq 0 ] 
  do

    # Look up the default frequency and SR

    # Read and trim the default frequency
    DEFAULT_FREQ_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'default__freq=')"
    DEFAULT_FREQ="$(echo "$DEFAULT_FREQ_LINE" | sed 's/default__freq=\"//' | sed 's/\"//')"

    # Read and trim the default SR
    DEFAULT_SR_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'default__sr=')"
    DEFAULT_SR="$(echo "$DEFAULT_SR_LINE" | sed 's/default__sr=\"//' | sed 's/\"//')"

    if [ "$DEFAULT_FREQ" == "" ]; then
      FREQ_TEXT="Scanning"
    else
      FREQ_TEXT=$DEFAULT_FREQ
    fi


    if [ "$DEFAULT_SR" == "" ]; then
      SR_TEXT="Scanning"
    else
      SR_TEXT=$DEFAULT_SR
    fi

    # Display main menu

    menuchoice=$(whiptail --title "BATC Ryde Receiver Main Menu" --menu "INFO" 18 78 11 \
	"0 Receive" "Start the Ryde Receiver on $FREQ_TEXT kHz at SR $SR_TEXT kS" \
        "1 Stop" "Stop the Ryde Receiver" \
        "2 Defaults" "Set the start-up frequency, SR etc" \
        "3 Bands" "Set the band details such as LNB Offset" \
	"4 Video" "Select the Video Output Mode" \
	"5 Remote" "Select the Remote Control Type" \
	"6 IR Check" "View the IR Codes From a new Remote" \
        "7 Settings" "Advanced Settings" \
	"8 Info" "Display System Info" \
	"9 Update" "Check for Update" \
	"10 Shutdown" "Reboot or Shutdown" \
 	3>&2 2>&1 1>&3)

        case "$menuchoice" in
	    0\ *) do_receive   ;;
            1\ *) do_stop   ;;
            2\ *) do_Set_Defaults ;;
            3\ *) do_Set_Bands ;;
	    4\ *) do_video_change ;;
   	    5\ *) do_Set_RC_Type ;;
   	    6\ *) do_Check_RC_Codes ;;
	    7\ *) do_Settings ;;
            8\ *) do_info ;;
	    9\ *) do_update ;;
	    10\ *) do_shutdown_menu ;;
               *)

        # Display exit message if user jumps out of menu
        whiptail --title "Exiting to Linux Prompt" --msgbox "To return to the menu system, type menu" 8 78

        # Set status to exit
        status=1

        # Sleep while user reads message, then exit
        sleep 1
      exit ;;
    esac
    exitstatus1=$status1
  done
exit
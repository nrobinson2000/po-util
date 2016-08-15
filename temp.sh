#!/bin/bash
CWD="$(pwd)"

blue_echo() {
  echo "$(tput setaf 6)$(tput bold)$MESSAGE$(tput sgr0)"
}

green_echo() {
  echo "$(tput setaf 2)$(tput bold)$MESSAGE$(tput sgr0)"
}

red_echo() {
  echo "$(tput setaf 1)$(tput bold)$MESSAGE$(tput sgr0)"
}

function find_objects() #Consolidated function
{
  if [ "$1" != "" ];
  then
    case "$1" in
      */)
       #"has slash"
       DEVICESFILE="${1%?}"
       FIRMWAREDIR="${1%?}"
       FIRMWAREBIN="${1%?}"
       DIRECTORY="${1%?}"
       ;;
     *)
       echo "doesn't have a slash" > /dev/null
     DEVICESFILE="$1"
     FIRMWAREDIR="$1"
     FIRMWAREBIN="$1"
       ;;
    esac
      if [ -f "$CWD/$DEVICESFILE/devices.txt" ] || [ -d "$CWD/$FIRMWAREDIR/firmware" ] || [ -f "$CWD/$FIRMWAREBIN/bin/firmware.bin" ];
      then
      DEVICESFILE="$CWD/$DEVICESFILE/devices.txt"
      FIRMWAREDIR="$CWD/$FIRMWAREDIR/firmware"
      FIRMWAREBIN="$CWD/$FIRMWAREBIN/bin/firmware.bin"
  else
        if [ -d "$DIRECTORY" ] && [ -d "$DIRECTORY/firmware" ];
        then
          DEVICESFILE="$DIRECTORY/devices.txt"
          FIRMWAREDIR="$DIRECTORY/firmware"
          FIRMWAREBIN="$DIRECTORY/bin/firmware.bin"
        else
          if [ -d "$CWD/$DIRECTORY" ];
          then
            DEVICESFILE="$CWD/$DIRECTORY/../devices.txt"
            FIRMWAREDIR="$CWD/$DIRECTORY"
            FIRMWAREBIN="$CWD/$DIRECTORY/../bin/firmware.bin"
          else
            if [ "$DIRECTORY" == "." ];
            then
              cd "$CWD/.."
              DEVICESFILE="$(pwd)/devices.txt"
              FIRMWAREDIR="$CWD"
              FIRMWAREBIN="$(pwd)/bin/firmware.bin"
            fi
          fi
        fi
  fi
else
  DEVICESFILE="$CWD/devices.txt"
  FIRMWAREDIR="$CWD/firmware"
  FIRMWAREBIN="$CWD/bin/firmware.bin"
fi

if [ -d "$FIRMWAREDIR" ];
  then
    FIRMWAREDIR="$FIRMWAREDIR"
  else
    if [ "$DIRWARNING" == "true" ];
    then
      echo
      MESSAGE="Firmware directory not found." ; red_echo
      MESSAGE="Please run \"po init\" to setup this repository or choose a valid directory." ; blue_echo
      echo
    fi
  FINDDIRFAIL="true"
fi

if [ -f "$DEVICESFILE" ];
  then
    DEVICES="$(cat $DEVICESFILE)"
  else
    if [ "$DEVICEWARNING" == "true" ];
    then
    MESSAGE="devices.txt not found." ; red_echo
    MESSAGE="You need to create a \"devices.txt\" file in your project directory with the names
of your devices on each line." ; blue_echo
    MESSAGE="Example:" ; green_echo
    echo "    product1
    product2
    product3
"
fi
FINDDEVICESFAIL="true"
fi

if [ -f "$FIRMWAREBIN" ];
  then
    FIRMWAREBIN="$FIRMWAREBIN"
  else
    if [ "$BINWARNING" == "true" ];
    then
      echo
      MESSAGE="Firmware Binary not found." ; red_echo
      MESSAGE="Perhaps you need to build your firmware?" ; blue_echo
      echo
    fi
  FINDBINFAIL="true"
fi
}

find_objects $1

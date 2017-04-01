#!/bin/bash
#                                            __      __  __
#                                           /  |    /  |/  |
#     ______    ______           __    __  _██ |_   ██/ ██ |
#    /      \  /      \  ______ /  |  /  |/ ██   |  /  |██ |
#   /██████  |/██████  |/      |██ |  ██ |██████/   ██ |██ |
#   ██ |  ██ |██ |  ██ |██████/ ██ |  ██ |  ██ | __ ██ |██ |
#   ██ |__██ |██ \__██ |        ██ \__██ |  ██ |/  |██ |██ |
#   ██    ██/ ██    ██/         ██    ██/   ██  ██/ ██ |██ |
#   ███████/   ██████/           ██████/     ████/  ██/ ██/
#   ██ |
#   ██ |
#   ██/                  https://nrobinson2000.github.io/po-util/
#

#  po-util - The Ultimate Local Particle Experience for Linux and macOS
# Copyright (C) 2017  Nathan Robinson
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Helper functions
function pause()
{
    read -rp "$*"
}

blue_echo()
{
    if [ -t 1 ];
    then
        echo "$(tput setaf 6)$(tput bold)$1$(tput sgr0)"
    else
        echo "$1"
    fi
}

green_echo()
{
    if [ -t 1 ];
    then
        echo "$(tput setaf 2)$(tput bold)$1$(tput sgr0)"
    else
        echo "$1"
    fi
}

red_echo()
{
    if [ -t 1 ];
    then
        echo "$(tput setaf 1)$(tput bold)$1$(tput sgr0)"
    else
        echo "$1"
    fi
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
                DIRECTORY="$1"
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
                if [ -d "$CWD/$DIRECTORY" ] && [ -d "$CWD/firmware" ];
                then
                    DEVICESFILE="$CWD/$DIRECTORY/../devices.txt"
                    FIRMWAREDIR="$CWD/$DIRECTORY"
                    FIRMWAREBIN="$CWD/$DIRECTORY/../bin/firmware.bin"
                else
                    if [ "$DIRECTORY" == "." ] && [ -f "$CWD/main.cpp" ];
                    then
                        cd "$CWD/.."
                        DEVICESFILE="$(pwd)/devices.txt"
                        FIRMWAREDIR="$CWD"
                        FIRMWAREBIN="$(pwd)/bin/firmware.bin"
                    else
                        echo
                        red_echo "Firmware not found!"
                        blue_echo "Please run \"po init DEVICE FOLDER\" to setup a project,
or choose a valid directory."
                        echo
                        exit
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
            red_echo "Firmware directory not found!"
            blue_echo "Please run \"po init DEVICE FOLDER\" to setup a project,
or choose a valid directory."
            echo
            exit
        fi
        FINDDIRFAIL="true"
    fi

    if [ -f "$DEVICESFILE" ];
    then
        DEVICES="$(cat $DEVICESFILE)"
    else
        if [ "$DEVICEWARNING" == "true" ];
        then
            echo
            red_echo "devices.txt not found!"
            blue_echo "You need to create a \"devices.txt\" file in your project directory with the names
of your devices on each line."
            green_echo "Example:"
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
            red_echo "Firmware Binary not found!"
            blue_echo "Perhaps you need to build your firmware?"
            echo
        fi
        FINDBINFAIL="true"
    fi
}

build_message()
{
    echo
    cd "$FIRMWAREDIR"/.. || exit
    BINARYDIR="$(pwd)/bin"
    green_echo "Binary saved to $BINARYDIR/firmware.bin"
    echo
    exit
}

dfu_open()
{
    if [ "$DEVICE_TYPE" == "duo" ];
    then
        if [ "$MODEM_DUO" != "" ];
        then
            MODEM="$MODEM_DUO"
        else
            echo
            red_echo "Device not found!"
            echo
            blue_echo "Your device must be connected by USB."
            echo
            exit
        fi
    else
        if [ "$MODEM" != "" ];
        then
            MODEM="$MODEM"
        else
            echo
            red_echo "Device not found!"
            echo
            blue_echo "Your device must be connected by USB."
            echo
            exit
        fi
    fi

    if [ "$MODEM" ];
    then
        stty -F "$MODEM" "$DFUBAUDRATE" > /dev/null
    fi
}

switch_branch()
{
    if [ "$1" != "" ];
    then
        if [ "$(git rev-parse --abbrev-ref HEAD)" != "$1" ];
        then
            git checkout "$1" > /dev/null
        fi
    else
        if [ "$(git rev-parse --abbrev-ref HEAD)" != "$BRANCH" ];
        then
            git checkout "$BRANCH" > /dev/null
        fi
    fi
}

common_commands() #List common commands
{
    echo
    blue_echo "Common commands include:
    build, flash, clean, ota, dfu, serial, init, config, setup, library"
    echo
}

build_firmware()
{

    #Temporary fix for http://community.particle.io/t/stm32-usb-otg-driver-error-on-v0-6-0/26814
    # STRING='CPPSRC += $(call target_files,$(BOOTLOADER_MODULE_PATH)/../hal/src/stm32/,newlib.cpp)'
    # echo "$STRING" >> "$FIRMWARE_PARTICLE/firmware/bootloader/src/electron/sources.mk"
    # sed "126s/.*/#define USB_OTG_MAX_TX_FIFOS (4*2)/" "$FIRMWARE_PARTICLE/firmware/platform/MCU/STM32F2xx/SPARK_Firmware_Driver/inc/platform_config.h" > temp.particle
    # sed "132s/.*/#define USB_OTG_MAX_TX_FIFOS (6*2)/" temp.particle > temp.particle.1
    # rm -f "$FIRMWARE_PARTICLE/firmware/platform/MCU/STM32F2xx/SPARK_Firmware_Driver/inc/platform_config.h"
    # mv temp.particle.1 "$FIRMWARE_PARTICLE/firmware/platform/MCU/STM32F2xx/SPARK_Firmware_Driver/inc/platform_config.h"
    # rm -f temp.particle
    # FIXED in release/v0.6.1-rc.1

    if [ "$DEVICE_TYPE" == "duo" ];
    then
        # RedBear DUO
        cd "$CWD" || exit
        sed "2s/.*/START_DFU_FLASHER_SERIAL_SPEED=$DFUBAUDRATE/" "$FIRMWARE_DUO/firmware/build/module-defaults.mk" > temp.particle
        rm -f "$FIRMWARE_DUO/firmware/build/module-defaults.mk"
        mv temp.particle "$FIRMWARE_DUO/firmware/build/module-defaults.mk"
    else
        cd "$CWD" || exit
        sed "2s/.*/START_DFU_FLASHER_SERIAL_SPEED=$DFUBAUDRATE/" "$FIRMWARE_PARTICLE/firmware/build/module-defaults.mk" > temp.particle
        rm -f "$FIRMWARE_PARTICLE/firmware/build/module-defaults.mk"
        mv temp.particle "$FIRMWARE_PARTICLE/firmware/build/module-defaults.mk"
    fi

    blue_echo "                                                     __      __  __
                                                    /  |    /  |/  |
              ______    ______           __    __  _██ |_   ██/ ██ |
             /      \  /      \  ______ /  |  /  |/ ██   |  /  |██ |
            /██████  |/██████  |/      |██ |  ██ |██████/   ██ |██ |
            ██ |  ██ |██ |  ██ |██████/ ██ |  ██ |  ██ | __ ██ |██ |
            ██ |__██ |██ \__██ |        ██ \__██ |  ██ |/  |██ |██ |
            ██    ██/ ██    ██/         ██    ██/   ██  ██/ ██ |██ |
            ███████/   ██████/           ██████/     ████/  ██/ ██/
            ██ |
            ██ |
            ██/         Building firmware for $DEVICE_TYPE...
    "

  if [ "$DEVICE_TYPE" == "duo" ];
  then
    make all -s -C "$FIRMWARE_DUO/firmware/main" APPDIR="$FIRMWAREDIR" TARGET_DIR="$FIRMWAREDIR/../bin" PLATFORM="$DEVICE_TYPE"
  else
    make all -s -C "$FIRMWARE_PARTICLE/firmware/main" APPDIR="$FIRMWAREDIR" TARGET_DIR="$FIRMWAREDIR/../bin" PLATFORM="$DEVICE_TYPE"
  fi
}

build_pi()
{
  if hash docker 2>/dev/null;
  then
    if docker run --rm -i -v $FIRMWARE_PARTICLE/firmware:/firmware -v $FIRMWAREDIR:/input -v $FIRMWAREDIR/../bin:/output particle/buildpack-raspberrypi 2> echo;
    then
      echo
      blue_echo "Successfully built firmware for Raspberry Pi"
    else
      echo
      red_echo "Build failed."
      echo
      exit 1
    fi
  else
    red_echo "Docker not found.  Please install docker to build firmware for Raspberry Pi"
    echo
    exit
  fi
}

ota() # device firmware
{
  find_objects "$2"
  DIRWARNING="true"
  BINWARNING="true"
  if [ "$FINDDIRFAIL" == "true" ] || [ "$FINDBINFAIL" == "true" ];
  then
    exit
  fi

  if [ "$1" == "" ];
  then
    echo
    red_echo "Please specify which device to flash ota."
    echo
    exit
  fi

  if [ "$1" == "--multi" ] || [ "$1" == "-m" ] || [ "$1" == "-ota" ];
  then
    DEVICEWARNING="true"
    if [ "$FINDDEVICESFAIL" == "true" ];
    then
      cd "$CWD"
      echo "" > devices.txt
      red_echo "Please list your devices in devices.txt"
      sleep 3
      exit
    fi
    for DEVICE in $DEVICES ; do
      echo
      blue_echo "Flashing to device $DEVICE..."
      particle flash "$DEVICE" "$FIRMWAREBIN" || ( red_echo "Your device must be online in order to flash firmware OTA." )
    done
    echo
    exit
  fi
  echo
  blue_echo "Flashing to device $1..."
  particle flash "$1" "$FIRMWAREBIN" || ( red_echo "Try using \"particle flash\" if you are having issues." )
  echo
  exit
}

config()
{
  SETTINGS=~/.po
  BASE_DIR=~/github
  FIRMWARE_PARTICLE=$BASE_DIR/particle
  FIRMWARE_DUO=$BASE_DIR/redbearduo
  BRANCH="release/stable"
  BRANCH_DUO="duo"
  ARM_PATH=$BINDIR/gcc-arm-embedded/$GCC_ARM_VER/bin/
  MODEM_DUO=$MODEM_DUO

  echo BASE_DIR="$BASE_DIR" >> $SETTINGS
  echo FIRMWARE_PARTICLE="$FIRMWARE_PARTICLE" >> $SETTINGS
  echo FIRMWARE_DUO="$FIRMWARE_DUO" >> $SETTINGS
  echo "export PARTICLE_DEVELOP=1" >> $SETTINGS
  echo BINDIR="$BINDIR" >> $SETTINGS

  # Particle
  echo
    blue_echo "Which branch of the Particle firmware would you like to use?
    You can find the branches at https://github.com/spark/firmware/branches
    If you are unsure, please enter \"release/stable\""
    read -rp "Branch: " branch_variable
    BRANCH="$branch_variable"
    echo BRANCH="$BRANCH" >> $SETTINGS
    echo

    # RedBear DUO
    blue_echo "Which branch of the RedBear DUO firmware would you like to use?
    You can find the branches at https://github.com/redbear/Duo/branches
    If you are unsure, please enter \"duo\""
    read -rp "Branch: " branch_variable
    BRANCH_DUO="$branch_variable"
    echo BRANCH_DUO="$BRANCH_DUO" >> $SETTINGS

    echo
    blue_echo "Which baud rate would you like to use to put devices into DFU mode?
    Enter \"default\" for the default Particle baud rate of 14400.
    Enter \"po\" to use the po-util recommended baud rate of 19200."
    read -rp "Baud Rate: " dfu_variable
    if [ "$dfu_variable" == "default" ];
    then
        DFUBAUDRATE=14400
    fi
    if [ "$dfu_variable" == "po" ];
    then
        DFUBAUDRATE=19200
    fi
    echo DFUBAUDRATE="$DFUBAUDRATE" >> $SETTINGS
    echo
    blue_echo "Shoud po-util automatically add and remove headers when using
    libraries?"
    read -rp "(yes/no): " response
    if [ "$response" == "yes" ] || [ "$response" == "y" ] || [ "$response" == "Y" ];
    then
        AUTO_HEADER="true"
    else
        AUTO_HEADER="false"
    fi
    echo AUTO_HEADER="$AUTO_HEADER" >> $SETTINGS
    echo
}

addLib()
{
    if [ -f "$FIRMWAREDIR/$LIB_NAME.cpp" ] || [ -f "$FIRMWAREDIR/$LIB_NAME.h" ] || [ -d "$FIRMWAREDIR/$LIB_NAME" ];
    then
        echo
        red_echo "Library $LIB_NAME is already added to this project..."
    else
        echo
        green_echo "Adding library $LIB_NAME to this project..."

        # Include library as a folder full of symlinks -- This is the new feature

        mkdir -p "$FIRMWAREDIR/$LIB_NAME"

        if [ -d "$LIBRARY/$LIB_NAME/firmware" ];
        then
            ln -s $LIBRARY/$LIB_NAME/firmware/*.h "$FIRMWAREDIR/$LIB_NAME"
            ln -s $LIBRARY/$LIB_NAME/firmware/*.cpp "$FIRMWAREDIR/$LIB_NAME"
        else
            if [ -d "$LIBRARY/$LIB_NAME/src" ];
            then
                ln -s $LIBRARY/$LIB_NAME/src/*.h "$FIRMWAREDIR/$LIB_NAME"
                ln -s $LIBRARY/$LIB_NAME/src/*.cpp "$FIRMWAREDIR/$LIB_NAME"
            else

                ln -s $LIBRARY/$LIB_NAME/*.h "$FIRMWAREDIR/$LIB_NAME"
                ln -s $LIBRARY/$LIB_NAME/*.cpp "$FIRMWAREDIR/$LIB_NAME"
            fi
        fi


    fi
}

getLib()
{
    if (ls -1 "$LIBRARY" | grep "$LIB_NAME") &> /dev/null ;
    then
        echo
        blue_echo "Library $LIB_NAME is already installed..."
    else
        echo
        blue_echo "Dowloading library $LIB_NAME..."
        echo
        git clone $i
    fi
}

addHeaders()
{
    [ "$1" != "" ] && HEADER="$1" || HEADER="$LIB_NAME"
    if [ "$AUTO_HEADER" == "true" ];
    then
        if (grep "#include \"$HEADER/$HEADER.h\"" "$FIRMWAREDIR/main.cpp") &> /dev/null ;
        then
            echo "Already imported" &> /dev/null
        else
            echo "#include \"$HEADER/$HEADER.h\"" > "$FIRMWAREDIR/main.cpp.temp"
            cat "$FIRMWAREDIR/main.cpp" >> "$FIRMWAREDIR/main.cpp.temp"
            rm "$FIRMWAREDIR/main.cpp"
            mv "$FIRMWAREDIR/main.cpp.temp" "$FIRMWAREDIR/main.cpp"
        fi
    fi
}

rmHeaders()
{
    if [ "$AUTO_HEADER" == "true" ];
    then
        if (grep "#include \"$1/$1.h\"" "$FIRMWAREDIR/main.cpp") &> /dev/null ;
        then
            grep -v "#include \"$1/$1.h\"" "$FIRMWAREDIR/main.cpp" > "$FIRMWAREDIR/main.cpp.temp"
            rm "$FIRMWAREDIR/main.cpp"
            mv "$FIRMWAREDIR/main.cpp.temp" "$FIRMWAREDIR/main.cpp"
        fi

        if (grep "#include \"$1.h\"" "$FIRMWAREDIR/main.cpp") &> /dev/null ; # Backwards support
        then
            grep -v "#include \"$1.h\"" "$FIRMWAREDIR/main.cpp" > "$FIRMWAREDIR/main.cpp.temp"
            rm "$FIRMWAREDIR/main.cpp"
            mv "$FIRMWAREDIR/main.cpp.temp" "$FIRMWAREDIR/main.cpp"
        fi

        if (grep "#include <$1.h>" "$FIRMWAREDIR/main.cpp") &> /dev/null ; # Other support
        then
            grep -v "#include <$1.h>" "$FIRMWAREDIR/main.cpp" > "$FIRMWAREDIR/main.cpp.temp"
            rm "$FIRMWAREDIR/main.cpp"
            mv "$FIRMWAREDIR/main.cpp.temp" "$FIRMWAREDIR/main.cpp"
        fi

    fi
}

# End of helper functions

if [ "$1" == "" ]; # Print help
then
    blue_echo "                                                     __      __  __
                                                    /  |    /  |/  |
              ______    ______           __    __  _██ |_   ██/ ██ |
             /      \  /      \  ______ /  |  /  |/ ██   |  /  |██ |
            /██████  |/██████  |/      |██ |  ██ |██████/   ██ |██ |
            ██ |  ██ |██ |  ██ |██████/ ██ |  ██ |  ██ | __ ██ |██ |
            ██ |__██ |██ \__██ |        ██ \__██ |  ██ |/  |██ |██ |
            ██    ██/ ██    ██/         ██    ██/   ██  ██/ ██ |██ |
            ███████/   ██████/           ██████/     ████/  ██/ ██/
            ██ |
            ██ |
            ██/               https://nrobinson2000.github.io/po-util/
    "

    echo "Copyright (GPL) 2017 Nathan D. Robinson

    Usage: po DEVICE_TYPE COMMAND DEVICE_NAME
           po DFU_COMMAND
           po install [full_install_path]
           po library LIBRARY_COMMAND

    Run \"man po\" for help.
    "
exit
fi

if [ "$1" == "setup-atom" ];
then
  echo
  blue_echo "Installing Atom packages to enhance po-util experience..."
  echo
  apm install build minimap file-icons language-particle
  echo
  exit
fi

# Configuration file is created at "~/.po"
SETTINGS=~/.po
BASE_DIR=~/github  # These
FIRMWARE_PARTICLE=$BASE_DIR/particle
FIRMWARE_DUO=$BASE_DIR/redbearduo
BRANCH="release/stable" # can
BRANCH_DUO="duo"
BINDIR=~/bin            # be
DFUBAUDRATE=19200       # changed in the "~/.po" file.
CWD="$(pwd)" # Global Current Working Directory variable
MODEM="$(ls -1 /dev/* | grep "ttyACM" | tail -1)"
MODEM_DUO="$(ls -1 /dev/* | grep "usbmodem" | tail -1)"
GCC_ARM_VER=gcc-arm-none-eabi-4_9-2015q3 # Updated to 4.9
GCC_ARM_PATH=$BINDIR/gcc-arm-embedded/$GCC_ARM_VER/bin/

if [ "$1" == "config" ];
then
  if [ -f "$SETTINGS" ];
  then
     rm "$SETTINGS"
  fi
  config
  exit
fi

# Check if we have a saved settings file.  If not, create it.
if [ ! -f $SETTINGS ]
then
  echo
  blue_echo "Your \"$SETTINGS\" configuration file is missing.  Let's create it!"
  config
fi

# Import our overrides from the ~/.po file.
source "$SETTINGS"

if [ "$1" == "info" ];
then
  echo
  echo "$(tput bold)$(tput setaf 3)$(date)$(tput sgr0)"
  echo
  echo "$(tput bold)Configured Settings:$(tput sgr0)"
  echo
  echo "$(tput bold)Firmware Branches:$(tput sgr0)"
  echo "$(tput bold)Particle: $(tput setaf 6)$BRANCH$(tput sgr0)"
  echo "$(tput bold)Duo: $(tput setaf 6)$BRANCH_DUO$(tput sgr0)"
  echo
  echo "$(tput bold)DFU Baud Rate: $(tput setaf 6)$DFUBAUDRATE$(tput sgr0)"
  echo "$(tput bold)Automatic Headers: $(tput setaf 6)$AUTO_HEADER$(tput sgr0)"
  echo
  exit
fi

#Import nvm if installed
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

if [ "$1" == "install" ]; # Install
then
  if [ "$(uname -s)" == "Darwin" ]; #Force homebrew version on macOS.
  then
    # Install via Homebrew
    echo
    blue_echo "You are on macOS.  po-util will be installed via Homebrew"

    if hash brew 2>/dev/null;
    then
      echo
      blue_echo "Homebrew is installed."
    else
      echo
      blue_echo "Installing Brew..."
      /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi

    echo
    blue_echo "Installing po-util with \"brew\""

    brew tap nrobinson2000/po
    brew install po
    po install
    exit

  fi

  if [ -f po-util.sh ];
  then
    if [ "$CWD" != "$HOME" ];
    then
      cp po-util.sh ~/po-util.sh #Replace ~/po-util.sh with one in current directory.
    fi
    chmod +x ~/po-util.sh
  else
    if [ -f ~/po-util.sh ];
    then
      chmod +x ~/po-util.sh
    else
    curl -fsSLo ~/po-util.sh https://raw.githubusercontent.com/nrobinson2000/po-util/master/po-util.sh
    chmod +x ~/po-util.sh
    fi
  fi

  # if [ -f ~/.bash_profile ]; #Create .bash_profile
  # then
  #   MESSAGE=".bash_profile present." ; green_echo
  # else
  #   MESSAGE="No .bash_profile present. Installing.." ; red_echo
  #   echo "
  #   if [ -f ~/.bashrc ]; then
  #       . ~/.bashrc
  #   fi" >> ~/.bash_profile
  # fi
  #
  # if [ -f ~/.bashrc ];  #Add po alias to .bashrc
  # then
  #   MESSAGE=".bashrc present." ; green_echo
  #   if grep "po-util.sh" ~/.bashrc ;
  #   then
  #     MESSAGE="po alias already in place." ; green_echo
  #   else
  #     MESSAGE="no po alias.  Installing..." ; red_echo
  #     echo 'alias po="~/po-util.sh"' >> ~/.bashrc
  #     echo 'alias p="particle"' >> ~/.bashrc  #Also add 'p' alias for 'particle'
  #   fi
  # else
  #   MESSAGE="No .bashrc present.  Installing..." ; red_echo
  #   echo 'alias po="~/po-util.sh"' >> ~/.bashrc
  # fi

  if [ -f /usr/local/bin/po ]
  then
    blue_echo "po already linked in /usr/local/bin."
  else
    blue_echo "Creating \"po\" link in /usr/local/bin..."
    sudo ln -s ~/po-util.sh /usr/local/bin/po
  fi

  # Download po-util-README.md
  curl -fsSLo ~/.po-util-README.md https://raw.githubusercontent.com/nrobinson2000/po-util/master/po-util-README.md

  # Check to see if we need to override the install directory.
  if [ "$2" ] && [ "$2" != $BASE_DIR ]
  then
    BASE_DIR="$2"
    echo BASE_DIR="$BASE_DIR" > $SETTINGS
  fi

  # create base dir
  [ -d "$BASE_DIR" ] || mkdir -p "$BASE_DIR"  # If BASE_DIR does not exist, create it

  # create Particle dir
  [ -d "$FIRMWARE_PARTICLE" ] || mkdir -p "$FIRMWARE_PARTICLE"  # If FIRMWARE_PARTICLE does not exist, create it
  # create redbearduo dir
  [ -d "$FIRMWARE_DUO" ] || mkdir -p "$FIRMWARE_DUO"  # If FIRMWARE_DUO does not exist, create it

  # clone Particle firmware repository
  cd "$FIRMWARE_PARTICLE" || exit

  if hash git 2>/dev/null;
  then
    NOGIT="false"
    echo
    blue_echo "Installing Particle firmware from Github..."
    git clone https://github.com/spark/firmware.git
  else
    NOGIT="true"
  fi

  # clone RedBear DUO firmware repository
  cd "$FIRMWARE_DUO" || exit

  if hash git 2>/dev/null;
  then
    NOGIT="false"
    echo
    blue_echo "Installing RedBear Duo firmware from Github..."
    git clone https://github.com/redbear/firmware.git
  else
    NOGIT="true"
  fi

    if hash apt-get 2>/dev/null; # Test if on a Debian-based system
    then
      DISTRO="deb" # Debian
      INSTALLER="apt-get install -y"
    else
      if hash yum 2>/dev/null;
      then
      DISTRO="rpm" # Fedora / Centos Linux
      INSTALLER="yum -y install"
    else
      if hash pacman 2>/dev/null; # Arch Linux
      then
        DISTRO="arch"
        INSTALLER="pacman -Syu"
      fi
    fi
  fi

    cd "$BASE_DIR" || exit

    echo

    # Install dependencies
    blue_echo "Installing ARM toolchain and dependencies locally in $BINDIR/gcc-arm-embedded/..."
    mkdir -p $BINDIR/gcc-arm-embedded && cd "$_" || exit

    if [ -d "$GCC_ARM_VER" ]; #
    then
        echo
        blue_echo "ARM toolchain version $GCC_ARM_VER is already downloaded... Continuing..."
    else
        curl -LO https://launchpad.net/gcc-arm-embedded/4.9/4.9-2015-q3-update/+download/gcc-arm-none-eabi-4_9-2015q3-20150921-linux.tar.bz2 #Update to v4.9
        tar xjf gcc-arm-none-eabi-*-linux.tar.bz2

        blue_echo "Creating links in /usr/local/bin..."
        sudo ln -s $GCC_ARM_PATH* /usr/local/bin # LINK gcc-arm-none-eabi
    fi

    if [ "$DISTRO" != "arch" ];
    then

    # Install Node.js
    curl -Ss https://nodejs.org/dist/ > node-result.txt
    grep "<a href=\"v" "node-result.txt" > node-new.txt
    tail -1 node-new.txt > node-oneline.txt
    sed -n 's/.*\"\(.*.\)\".*/\1/p' node-oneline.txt > node-version.txt
    NODEVERSION="$(cat node-version.txt)"
    NODEVERSION="${NODEVERSION%?}"
    INSTALLVERSION="node-$NODEVERSION"
    rm node-*.txt
    if [ "$(node -v)" == "$NODEVERSION" ];
    then
        blue_echo "Node.js version $NODEVERSION is already installed."
    else
        # MESSAGE="Installing Node.js version $NODEVERSION..." ; blue_echo
        curl -Ss https://api.github.com/repos/nodesource/distributions/contents/"$DISTRO" | grep "name"  | grep "setup_"| grep -v "setup_iojs"| grep -v "setup_dev" > node-files.txt
        tail -1 node-files.txt > node-oneline.txt
        sed -n 's/.*\"\(.*.\)\".*/\1/p' node-oneline.txt > node-version.txt
        # MESSAGE="Installing Node.js version $(cat node-version.txt)..." blue_echo
        # curl -sL https://"$DISTRO".nodesource.com/"$(cat node-version.txt)" | sudo -E bash -
        curl -sL https://"$DISTRO".nodesource.com/setup_6.x | sudo -E bash -
        rm -rf node-*.txt
    fi
fi

if [ "$DISTRO" == "deb" ];
then
    sudo $INSTALLER git nodejs python-software-properties python g++ make build-essential libusb-1.0-0-dev libarchive-zip-perl screen libc6-i386 autoconf automake
fi

if [ "$DISTRO" == "rpm" ];
then
    sudo $INSTALLER git nodejs python make automake gcc gcc-c++ kernel-devel libusb glibc.i686 vim-common perl-Archive-Zip-1.58-1.fc24.noarch screen autoconf
fi

if [ "$DISTRO" == "arch" ];
then
    sudo $INSTALLER git nodejs npm python gcc make automake libusb lib32-glibc vim yaourt screen autoconf
    yaourt -S perl-archive-zip
fi

# Install dfu-util
blue_echo "Installing dfu-util (requires sudo)..."
cd "$BASE_DIR" || exit
git clone git://git.code.sf.net/p/dfu-util/dfu-util
cd dfu-util || exit
git pull
./autogen.sh
./configure
make
sudo make install
cd ..

# Install particle-cli
blue_echo "Installing particle-cli..."
sudo npm install -g --unsafe-perm node-pre-gyp npm serialport particle-cli

# Install udev rules file
blue_echo "Installing udev rule (requires sudo) ..."
curl -fsSLO https://raw.githubusercontent.com/nrobinson2000/po-util/master/60-po-util.rules
sudo mv 60-po-util.rules /etc/udev/rules.d/60-po-util.rules

# Install manpage
blue_echo "Installing po manpage..."
curl -fsSLO https://raw.githubusercontent.com/nrobinson2000/homebrew-po/master/man/po.1
sudo mv po.1 /usr/local/share/man/man1/
sudo mandb &> /dev/null

blue_echo "Adding $USER to plugdev group..."
sudo usermod -a -G plugdev "$USER"

cd "$FIRMWARE_PARTICLE" || exit

if [ "$NOGIT" == "true" ];
then
    blue_echo "Installing Particle firmware from Github..."
    git clone https://github.com/spark/firmware.git
fi

cd "$FIRMWARE_DUO" || exit

if [ "$NOGIT" == "true" ];
then
    blue_echo "Installing RedBear DUO firmware from Github..."
    git clone https://github.com/redbear/firmware.git
fi

green_echo "
    Thank you for installing po-util. Be sure to check out
    https://nrobinson2000.github.io/po-util/ if you have any questions,
    suggestions, comments, or problems.  You can use the message button in the
    bottom right corner of the site to send me a private message. If need to
    update po-util just run \"po update\" to download the latest versions of
    po-util, Particle Firmware and particle-cli, or run \"po install\" to update
    all dependencies.
"
  exit
fi

# Create our project files
if [ "$1" == "init" ]; # Syntax: po init DEVICE dir
then

  if [ "$2" == "photon" ] || [ "$2" == "P1" ] || [ "$2" == "electron" ] || [ "$2" == "pi" ] || [ "$2" == "core" ] || [ "$2" == "duo" ];
  then
    DEVICE_TYPE="$2"
    FOLDER="$3"
  else
    blue_echo "
Please chose a device type next time :)"
  FOLDER="$2"
  fi

  if [[ "$FOLDER" == "/"* ]]; # Check for absolute or relative
  then
    FIRMWAREDIR="$FOLDER/firmware"
  else
    FIRMWAREDIR="$CWD/$FOLDER/firmware"
  fi

  if [ -d "$FIRMWAREDIR" ];
  then
    echo
    green_echo "Directory is already Initialized!"
    echo
    exit
  fi

  mkdir -p "$FIRMWAREDIR"
  echo "#include \"Particle.h\"

void setup() // Put setup code here to run once
{

}

void loop() // Put code here to loop forever
{

}" > "$FIRMWAREDIR/main.cpp"

        cp ~/.po-util-README.md "$FIRMWAREDIR/../README.md"

    if [ "$DEVICE_TYPE" != "" ];
    then
        echo "---
cmd: po $DEVICE_TYPE build

targets:
  Build:
    args:
      - $DEVICE_TYPE
      - build
    cmd: po
    keymap: ctrl-alt-1
    name: Build
  Flash:
    args:
      - $DEVICE_TYPE
      - flash
    cmd: po
    keymap: ctrl-alt-2
    name: Flash
  Clean:
    args:
      - $DEVICE_TYPE
      - clean
    cmd: po
    keymap: ctrl-alt-3
    name: Clean
  DFU:
    args:
      - $DEVICE_TYPE
      - dfu
    cmd: po
    keymap: ctrl-alt-4
    name: DFU
  OTA:
    args:
      - $DEVICE_TYPE
      - ota
      - --multi
    cmd: po
    keymap: ctrl-alt-5
    name: DFU
        " >> "$FIRMWAREDIR/../.atom-build.yml"

mkdir -p "$FIRMWAREDIR/../ci"

echo "dist: trusty
sudo: required
language: generic

script:
  - ci/travis.sh" > "$FIRMWAREDIR/../.travis.yml"

echo "#!/bin/bash
sudo apt install -y expect

curl -sLO https://raw.githubusercontent.com/nrobinson2000/po-util/master/po-util.sh

chmod +x po-util.sh

curl -sLO https://raw.githubusercontent.com/nrobinson2000/po-util/master/config-expect.sh

chmod +x config-expect.sh

./config-expect.sh

./po-util.sh install

po lib setup
po $DEVICE_TYPE build" > "$FIRMWAREDIR/../ci/travis.sh"

chmod +x "$FIRMWAREDIR/../ci/travis.sh"

    fi

    echo "bin/*" > "$FIRMWAREDIR/../.gitignore"
    cd "$FIRMWAREDIR/.."
    git init &> /dev/null

    echo
    green_echo "Directory initialized as a po-util project for $DEVICE_TYPE"
    echo
    exit
fi

# Open serial monitor for device
if [ "$1" == "serial" ];
then
if [ "$MODEM" == "" ]; # Don't run screen if device is not connected
then
red_echo "No device connected!"
exit
else
screen -S particle "$MODEM"
screen -S particle -X quit && exit || blue_echo "If \"po serial\" is putting device into DFU mode, power off device, removing battery for Electron, and run \"po serial\" several times.
This bug will hopefully be fixed in a later release."
fi
exit
fi

# Put device into DFU mode
if [ "$1" == "dfu-open" ];
then
dfu_open
exit
fi

# Get device out of DFU mode
if [ "$1" == "dfu-close" ];
then
dfu-util -d 2b04:D006 -a 0 -i 0 -s 0x080A0000:leave -D /dev/null &> /dev/null
exit
fi

# Update po-util
if [ "$1" == "update" ];
then

if [ "$2" == "duo" ]; # Update just duo firmware
then
echo
blue_echo "Updating RedBear DUO firmware..."
cd "$FIRMWARE_DUO"/firmware || exit
git stash
switch_branch "$BRANCH_DUO" &> /dev/null
git pull
echo
exit
fi

if [ "$2" == "firmware" ]; # update just particle firmware
then
echo
blue_echo "Updating Particle firmware..."
cd "$FIRMWARE_PARTICLE"/firmware || exit
git stash
switch_branch &> /dev/null
git pull
echo
exit
fi

#update both and everything else if not specified

echo

blue_echo "Updating RedBear DUO firmware..."
cd "$FIRMWARE_DUO"/firmware || exit
git stash
switch_branch "$BRANCH_DUO" &> /dev/null
git pull

echo

blue_echo "Updating Particle firmware..."
cd "$FIRMWARE_PARTICLE"/firmware || exit
git stash
switch_branch &> /dev/null
git pull

echo

blue_echo "Updating particle-cli..."
sudo npm update -g particle-cli
echo
blue_echo "Updating po-util.."
rm ~/po-util.sh
curl -fsSLo ~/po-util.sh https://raw.githubusercontent.com/nrobinson2000/po-util/master/po-util.sh
chmod +x ~/po-util.sh
rm ~/.po-util-README.md
curl -fsSLo ~/.po-util-README.md https://raw.githubusercontent.com/nrobinson2000/po-util/master/po-util-README.md
curl -fsSLO https://raw.githubusercontent.com/nrobinson2000/homebrew-po/master/man/po.1
sudo mv po.1 /usr/local/share/man/man1/
sudo mandb &> /dev/null
echo
exit
fi

#################### Library Manager

if [ "$1" == "library" ] || [ "$1" == "lib" ];
then

LIBRARY=~/.po-util/lib # Create library directory
if [ -d "$LIBRARY" ];    # if it is not found.
then
LIBRARY=~/.po-util/lib
else
mkdir -p "$LIBRARY"
fi

if [ "$2" == "clean" ]; # Prepare for release, remove all symlinks, keeping references in libs.txt
then
DIRWARNING="true"
find_objects "$3"

for file in $(ls -1 $FIRMWAREDIR);
do
    file_base="${file%.*}"
    if (ls -1 "$LIBRARY" | grep "$file_base") &> /dev/null ;
    then
        rm -rf "$FIRMWAREDIR/$file_base" &> /dev/null # Transition
        rm "$FIRMWAREDIR/$file_base.h" &> /dev/null   # to new
        rm "$FIRMWAREDIR/$file_base.cpp" &> /dev/null # system
        rmHeaders "$file_base"
    fi
done

echo
blue_echo "Removed all symlinks. This can be undone with \"po lib add\""
echo
exit
fi

if [ "$2" == "setup" ];
then
DIRWARNING="true"
find_objects "$3"
cd "$LIBRARY"

while read i ## Install and add required libs from libs.txt
do
    LIB_NAME="$(echo $i | awk '{ print $NF }' )"
    getLib
    addLib
    addHeaders "$LIB_NAME"
done < "$FIRMWAREDIR/../libs.txt"
echo
exit
fi

if [ "$2" == "get" ] || [ "$2" == "install" ]; # Download a library with git OR Install from libs.txt
then

cd "$LIBRARY"

if [ "$3" == "" ]; # Install from libs.txt
then
    DIRWARNING="true"
    find_objects

    while read i
    do
        LIB_NAME="$(echo $i | awk '{ print $NF }' )"
        getLib
    done < "$FIRMWAREDIR/../libs.txt"
    echo
    exit
fi

        if grep -q "://" <<<"$3";
        then
        echo "Valid URL" > /dev/null
        else
          echo
          blue_echo "Attempting to download $3 using Particle Libraries 2.0..."
          echo

          if [ -f "$LIBRARY/../project.properties" ];
          then
            echo "Exists!" > /dev/null
          else
          cd "$LIBRARY/.."
          mkdir src
          echo "name=particle-lib" > "project.properties"
          fi

          cd "$LIBRARY/.."
          particle library copy "$3" || ( echo && particle library search "$3" )
          echo
          exit
        fi

    if [ "$4" != "" ];  # Download a library with git
    then
      echo
      git clone "$3" "$4" || ( echo ; red_echo "Could not download Library.  Please supply a valid URL to a git repository." )
      echo
      exit
    else
      echo
      git clone "$3" || ( echo ; red_echo "Could not download Library.  Please supply a valid URL to a git repository." )
      echo
      exit
    fi
    exit
  fi


  if [ "$2" == "purge" ];  # Delete library from "$LIBRARY"
  then
    if  [ -d "$LIBRARY/$3" ];
    then
      echo
      read -rp "Are you sure you want to purge $3? (yes/no): " answer
      if [ "$answer" == "yes" ] || [ "$answer" == "y" ] || [ "$answer" == "Y" ];
      then
        echo
        blue_echo "Purging library $3..."
        rm -rf "${LIBRARY:?}/$3"
        echo
        green_echo "Library $3 has been purged."
        echo
      else
        echo
        blue_echo "Aborting..."
        echo
        exit
      fi
    else
      red_echo "Library not found."
      echo
    fi
    exit
  fi

  if [ "$2" == "create" ]; # Create a libraries in "$LIBRARY" from files in "$FIRMWAREDIR"  This for when multiple libraries are packaged together and they need to be separated.
  then
    DIRWARNING="true"
    find_objects "$3"

    for file in $(ls -1 $FIRMWAREDIR);
    do
    file_base="${file%.*}"
      if (ls -1 "$LIBRARY" | grep "$file_base") &> /dev/null ;
      then
      echo " " > /dev/null
      else
        if [ "$file_base" != "examples" ];
        then
          mkdir -p "$LIBRARY/$file_base"
          echo
          blue_echo "Creating library $file_base..."
          cp "$FIRMWAREDIR/$file_base.h" "$LIBRARY/$file_base"
          cp "$FIRMWAREDIR/$file_base.cpp" "$LIBRARY/$file_base" &> /dev/null
        fi
      fi
    done

    echo
    exit
  fi

  if [ "$2" == "add" ] || [ "$2" == "import" ]; # Import a library
  then
    DIRWARNING="true"
    find_objects "$4"

    if [ "$3" == "" ];
    then
      while read i ## Install and add required libs from libs.txt
      do
        LIB_NAME="$(echo $i | awk '{ print $NF }' )"
        addLib
        addHeaders "$LIB_NAME"
      done < "$FIRMWAREDIR/../libs.txt"
      echo
      exit
    fi

    if [ -d "$LIBRARY/$3" ];
    then
      echo "Found" > /dev/null
    else
      echo
      red_echo "Library $3 not found"
      echo
      exit
    fi

    if [ -f "$FIRMWAREDIR/$3.cpp" ] || [ -f "$FIRMWAREDIR/$3.h" ];
    then
      echo
      red_echo "Library $3 is already imported"
      echo
      exit
    else
      LIB_NAME="$3"
      addLib
      #Add entries to libs.txt file
      LIB_URL="$( cd $LIBRARY/$3 && git config --get remote.origin.url )"
      echo "$LIB_URL $3" >> "$FIRMWAREDIR/../libs.txt"
      addHeaders "$LIB_NAME"

    echo
    green_echo "Imported library $3"
    echo
    exit
    fi
    exit
  fi

  if [ "$2" == "remove" ] || [ "$2" == "rm" ]; # Remove / Unimport a library
  then
    DIRWARNING="true"
    find_objects "$4"

    if [ "$3" == "" ];
    then
      echo
      red_echo "Please choose a library to remove."
      exit
    fi

    if [ -f "$FIRMWAREDIR/$3.cpp" ] && [ -f "$FIRMWAREDIR/$3.h" ] || [ -d "$FIRMWAREDIR/$3" ];  # Improve this to only check for [ -d "$FIRMWAREDIR/$3" ] once new system is adopted
    then
      echo
      green_echo "Found library $3"
    else
      echo
      red_echo "Library $3 not found"
      echo
      exit
    fi

    if [ -d "$LIBRARY/$3" ];
    then
      echo
      blue_echo "Library $3 is backed up, removing from project..."

      rm "$FIRMWAREDIR/$3.cpp" &> /dev/null # Transition
      rm "$FIRMWAREDIR/$3.h" &> /dev/null   # to new
      rm -rf "$FIRMWAREDIR/$3" &> /dev/null # system

      grep -v "$3" "$FIRMWAREDIR/../libs.txt" > "$FIRMWAREDIR/../libs-temp.txt"
      rm "$FIRMWAREDIR/../libs.txt"
      mv "$FIRMWAREDIR/../libs-temp.txt" "$FIRMWAREDIR/../libs.txt"

      if [ -s "$FIRMWAREDIR/../libs.txt" ];
      then
         echo " " > /dev/null
      else
        rm "$FIRMWAREDIR/../libs.txt"
      fi
      echo
      rmHeaders "$3"
      exit
    else
      echo
      read -rp "Library $3 is not backed up.  Are you sure you want to remove it ? (yes/no): " answer
      if [ "$answer" == "yes" ] || [ "$answer" == "y" ] || [ "$answer" == "Y" ];
      then
        echo
        blue_echo "Removing library $3..."

        rm "$FIRMWAREDIR/$3.cpp" &> /dev/null # Transition
        rm "$FIRMWAREDIR/$3.h" &> /dev/null   # to new
        rm -rf "$FIRMWAREDIR/$3" &> /dev/null # system

        rmHeaders "$3"
        echo
        green_echo "Library $3 has been purged."
        exit
      else
        echo
        blue_echo "Aborting..."
        exit
      fi
    fi
    exit
  fi # Close remove

  if [ "$2" == "list" ] || [ "$2" == "ls" ];
  then
    echo
    blue_echo "The following Particle libraries have been downloaded:"
    echo
    ls -m "$LIBRARY"
    echo
    exit
  fi # Close list

  if [ "$2" == "package" ] || [ "$2" == "pack" ] || [ "$2" == "export" ];
  then
    DIRWARNING="true"
    find_objects "$3"
    PROJECTDIR="$(cd $FIRMWAREDIR/.. && pwd)"
    PROJECTDIR="${PROJECTDIR##*/}"
    if [ -d "$FIRMWAREDIR/../$PROJECTDIR-packaged" ];
    then
      rm -rf "$FIRMWAREDIR/../$PROJECTDIR-packaged"
      rm -rf "$FIRMWAREDIR/../$PROJECTDIR-packaged.tar.gz"
    fi

    cp -r "$FIRMWAREDIR" "$FIRMWAREDIR/../$PROJECTDIR-packaged"
    tar -cvzf "$FIRMWAREDIR/../$PROJECTDIR-packaged.tar.gz" "$FIRMWAREDIR/../$PROJECTDIR-packaged" &> /dev/null
    echo
    blue_echo "Firmware has been packaged as \"$PROJECTDIR-packaged\" and \"$PROJECTDIR-packaged.tar.gz\"
in \"$PROJECTDIR\". Feel free to use either when sharing your firmware."
    echo
  exit
  fi

  if [ "$2" == "help" ] || [ "$2" == "" ]; # SHOW HELP TEXT FOR "po library"
  then
  blue_echo "                                                     __      __  __
                                                    /  |    /  |/  |
              ______    ______           __    __  _██ |_   ██/ ██ |
             /      \  /      \  ______ /  |  /  |/ ██   |  /  |██ |
            /██████  |/██████  |/      |██ |  ██ |██████/   ██ |██ |
            ██ |  ██ |██ |  ██ |██████/ ██ |  ██ |  ██ | __ ██ |██ |
            ██ |__██ |██ \__██ |        ██ \__██ |  ██ |/  |██ |██ |
            ██    ██/ ██    ██/         ██    ██/   ██  ██/ ██ |██ |
            ███████/   ██████/           ██████/     ████/  ██/ ██/
            ██ |
            ██ |
            ██/               https://nrobinson2000.github.io/po-util/
"
        blue_echo

        echo "
\"po library\": The Particle Library manager for po-util.

For help, read the LIBRARY MANAGER section of \"man po\"
    "
  exit
fi # Close help

if [ "$2" == "update" ] || [ "$2" == "refresh" ]; # Update all libraries
then
  echo

  if [ "$(ls -1 $LIBRARY)" == "" ];
  then
    red_echo "No libraries installed.  Use \"po lib get\" to download some."
    exit
  fi

  green_echo "Checking for updates..."
  echo

  for OUTPUT in $(ls -1 "$LIBRARY")
  do
  	cd "$LIBRARY/$OUTPUT"

    if [ -d "$LIBRARY/$OUTPUT/.git" ]; # Only do git pull if it is a repository
    then
    blue_echo "Updating library $OUTPUT..."
    git pull
    echo
    fi
  done
  exit
fi # Close Update

if [ "$2" == "source" ] || [ "$2" == "src" ] ;
then
  echo
  blue_echo "Listing installed libraries that are cloneable..."
  echo
  for OUTPUT in $(ls -1 "$LIBRARY")
  do
  	cd "$LIBRARY/$OUTPUT"
    if [ -d "$LIBRARY/$OUTPUT/.git" ]; # Only if it is a repository
    then
      LIB_URL="$( cd $LIBRARY/$OUTPUT && git config --get remote.origin.url )"
      echo "$LIB_URL $OUTPUT"
      echo
    fi
  done
  exit
fi ### Close source


# commands for listing and loading examples in a lib

if [ "$2" == "examples" ] || [ "$2" == "ex" ];
then

  if [ "$3" == "" ];
  then
  # echo
  blue_echo "                                                     __      __  __
                                                    /  |    /  |/  |
              ______    ______           __    __  _██ |_   ██/ ██ |
             /      \  /      \  ______ /  |  /  |/ ██   |  /  |██ |
            /██████  |/██████  |/      |██ |  ██ |██████/   ██ |██ |
            ██ |  ██ |██ |  ██ |██████/ ██ |  ██ |  ██ | __ ██ |██ |
            ██ |__██ |██ \__██ |        ██ \__██ |  ██ |/  |██ |██ |
            ██    ██/ ██    ██/         ██    ██/   ██  ██/ ██ |██ |
            ███████/   ██████/           ██████/     ████/  ██/ ██/
            ██ |
            ██ |
            ██/               https://nrobinson2000.github.io/po-util/
  "

  echo "
  \"po lib ex\": Particle Library Example Manager

  ls - List the examples in a library

  load - Load an example from a library

  For help, read the LIBRARY EXAMPLE MANAGER section of \"man po\"
  "
  exit
  else

if [ -d "$LIBRARY/$4" ];
then
echo " " > /dev/null
else
echo
red_echo "Library $4 not found."
echo
exit
fi

if [ "$3" == "ls" ] || [ "$3" == "list" ]; #po lib ex ls
then

if [ "$4" == "" ];
then
echo
red_echo "Please choose a library."
echo
exit

fi

  if [ -d "$LIBRARY/$4/examples" ];
  then
    echo
    blue_echo "Found the following $4 examples:"
    echo
    ls -m "$LIBRARY/$4/examples"
    echo
    exit
  else
    echo
    red_echo "Could not find any $4 examples."
    echo
    exit
fi

fi

if [ "$3" == "load" ] || [ "$3" == "copy" ] && [ -d "$LIBRARY/$4/examples" ]; #po lib ex copy LIBNAME EXNAME
then
DATE=$(date +%Y-%m-%d)
TIME=$(date +"%H-%M")
find_objects "$CWD"

if [ -d "$LIBRARY/$4/examples/$5" ];
then
  echo " " > /dev/null
  if [ "$5" == "" ];
  then
    echo
    red_echo "Please choose a valid example.  Use \"po lib ex ls libraryName\" to find examples."
    echo
    exit
  fi
else
echo
red_echo "Please choose a valid example.  Use \"po lib ex ls libraryName\" to find examples."
echo
exit
fi

cp "$FIRMWAREDIR/main.cpp" "$FIRMWAREDIR/main.cpp.$DATE-$TIME.txt"
rm "$FIRMWAREDIR/main.cpp"

if [ -d "$LIBRARY/$4/examples/$5" ];
then
if [ -f "$LIBRARY/$4/examples/$5/$5.cpp" ];
then
cp "$LIBRARY/$4/examples/$5/$5.cpp" "$FIRMWAREDIR/main.cpp"
fi

if [ -f "$LIBRARY/$4/examples/$5/$5.ino" ];
then
cp "$LIBRARY/$4/examples/$5/$5.ino" "$FIRMWAREDIR/main.cpp"
fi

if [ -f "$FIRMWAREDIR/../libs.txt" ];
then

while read i ## Install and add required libs from libs.txt
do
  LIB_NAME="$(echo $i | awk '{ print $NF }' )"
  addLib
  rmHeaders "$LIB_NAME"
  addHeaders "$LIB_NAME"
done < "$FIRMWAREDIR/../libs.txt"

else # get dependencies

grep "#include" "$FIRMWAREDIR/main.cpp" | grep -v "Particle" | grep -v "application" > "$FIRMWAREDIR/../libs.temp.txt"

sed 's/^[^"]*"//; s/".*//' "$FIRMWAREDIR/../libs.temp.txt" > "$FIRMWAREDIR/../libs.temp1.txt"

while read i ## remove the < >
do
  crap="#include <"
  j=$i
  j="${i#${crap}}"
  j="${j%>}"
  grep -v "${crap}$j>" "$FIRMWAREDIR/main.cpp" > "$FIRMWAREDIR/main.cpp.temp"
  rm "$FIRMWAREDIR/main.cpp"
  mv "$FIRMWAREDIR/main.cpp.temp" "$FIRMWAREDIR/main.cpp"

  echo $j
echo "$j" >> "$FIRMWAREDIR/../libs.temp2.txt"
done < "$FIRMWAREDIR/../libs.temp1.txt"

rm "$FIRMWAREDIR/../libs.temp.txt"

while read i ## remove .h
do
echo "${i%.h}" >> "$FIRMWAREDIR/../libs.temp.txt"
done < "$FIRMWAREDIR/../libs.temp2.txt"

rm "$FIRMWAREDIR/../libs.temp1.txt"
rm "$FIRMWAREDIR/../libs.temp2.txt"

while read i ## create libs.txt
do
  LIB_NAME="$i"
  if (ls -1 "$LIBRARY" | grep "$LIB_NAME") &> /dev/null ;
  then


    if [ -d "$LIBRARY/$LIB_NAME/.git" ]; # Only if it is a repository
    then
      LIB_URL="$( cd $LIBRARY/$LIB_NAME && git config --get remote.origin.url )"
      LIB_STR="$LIB_URL $LIB_NAME"
      echo "$LIB_STR" >> "$FIRMWAREDIR/../libs.txt"
    fi

else
echo "$LIB_NAME" >> "$FIRMWAREDIR/../libs.txt"

  fi

done < "$FIRMWAREDIR/../libs.temp.txt"

rm "$FIRMWAREDIR/../libs.temp.txt"


while read i ## Install and add required libs from libs.txt
do
  LIB_NAME="$(echo $i | awk '{ print $NF }' )"
  addLib
  rmHeaders "$LIB_NAME"
  addHeaders "$LIB_NAME"
done < "$FIRMWAREDIR/../libs.txt"

fi

echo
blue_echo "Loaded example $5 from $4."
echo
green_echo "Original main.cpp has been backed up as main.cpp.$DATE-$TIME.txt"
echo

else

  echo
  red_echo"Example $5 not found."
  echo

fi

fi


fi

exit
fi

  echo
  red_echo"Please choose a valid command, or run \"po lib\" for help."
  echo
  exit
fi # Close Library
####################

# Make sure we are using photon, P1, electron, pi, core, or duo
if [ "$1" == "photon" ] || [ "$1" == "P1" ] || [ "$1" == "electron" ] || [ "$1" == "pi" ] || [ "$1" == "core" ] || [ "$1" == "duo" ];
then
  DEVICE_TYPE="$1"

  if [ "$DEVICE_TYPE" == "duo" ];
  then
    cd "$FIRMWARE_DUO"/firmware || exit
  else
    cd "$FIRMWARE_PARTICLE"/firmware || exit
  fi

  if [ "$DEVICE_TYPE" == "pi" ];
  then
    switch_branch "feature/raspberry-pi"  &> /dev/null
  elif [ "$DEVICE_TYPE" == "duo" ];
  then
    switch_branch $BRANCH_DUO &> /dev/null
  else
    switch_branch &> /dev/null
  fi
else
  echo
  if [ "$1" == "redbear" ] || [ "$1" == "bluz" ] || [ "$1" == "oak" ];
  then
    red_echo "This compound is not supported yet. Find out more here: https://git.io/vMTAw"
    echo
  fi
  red_echo "Please choose \"photon\", \"P1\", \"electron\", \"core\", \"pi\", or \"duo\",
or choose a proper command."
  common_commands
  exit
fi
if [ "$DEVICE_TYPE" == "photon" ];
then
  DFU_ADDRESS1="2b04:D006"
  DFU_ADDRESS2="0x080A0000"
fi
if [ "$DEVICE_TYPE" == "P1" ];
then
  DFU_ADDRESS1="2b04:D008"
  DFU_ADDRESS2="0x080A0000"
fi
if [ "$DEVICE_TYPE" == "electron" ];
then
  DFU_ADDRESS1="2b04:d00a"
  DFU_ADDRESS2="0x08080000"
fi
if [ "$DEVICE_TYPE" == "core" ];
then
  DFU_ADDRESS1="1d50:607f"
  DFU_ADDRESS2="0x08005000"
fi
if [ "$DEVICE_TYPE" == "duo" ];
then
  DFU_ADDRESS1="2b04:d058"
  DFU_ADDRESS2="0x80C0000"
fi

if [ "$2" == "setup" ];
then
  echo
  pause "Connect your device and put it into Listening mode. Press [ENTER] to continue..."
  particle serial identify
  if [ "$DEVICE_TYPE" != "electron" ];
  then
    echo
  pause "We will now connect your $DEVICE_TYPE to Wi-Fi. Press [ENTER] to continue..."
  echo
  particle serial wifi
fi
echo
blue_echo "You should now be able to claim your device.  Please run
\"particle device add Device_ID\", using the Device_ID we found above."
echo
exit
fi

# Flash already compiled binary
if [ "$2" == "dfu" ];
then
  BINWARNING="true"
  find_objects "$3"
  if [ "$FINDBINFAIL" == "true" ];
  then
    exit
  fi
  dfu_open
  sleep 1
  echo
  blue_echo "Flashing $FIRMWAREBIN with dfu-util..."
  echo
  dfu-util -d "$DFU_ADDRESS1" -a 0 -i 0 -s "$DFU_ADDRESS2":leave -D "$FIRMWAREBIN" || ( echo && red_echo "Device not found." && echo && exit )
  echo
  blue_echo "Firmware successfully flashed to $DEVICE_TYPE on $MODEM"
  echo
  exit
fi

#Upgrade our firmware on device
if [ "$2" == "upgrade" ] || [ "$2" == "patch" ] || [ "$2" == "update" ];
then

if [ "$DEVICE_TYPE" == "photon" ] || [ "$DEVICE_TYPE" == "P1" ] || [ "$DEVICE_TYPE" == "electron" ]
then

  pause "Connect your device and put into DFU mode. Press [ENTER] to continue..."
  cd "$CWD" || exit
  sed "2s/.*/START_DFU_FLASHER_SERIAL_SPEED=$DFUBAUDRATE/" "$FIRMWARE_PARTICLE/firmware/build/module-defaults.mk" > temp.particle
  rm -f "$FIRMWARE_PARTICLE/firmware/build/module-defaults.mk"
  mv temp.particle "$FIRMWARE_PARTICLE/firmware/build/module-defaults.mk"

  cd "$FIRMWARE_PARTICLE/firmware/modules" || exit
  make clean all PLATFORM="$DEVICE_TYPE" program-dfu

  cd "$FIRMWARE_PARTICLE/firmware" && git stash || exit
  sleep 1
  dfu-util -d $DFU_ADDRESS1 -a 0 -i 0 -s $DFU_ADDRESS2:leave -D /dev/null &> /dev/null
  exit

else
  echo
  red_echo "This command can only be used to update the system firmware for
photon, P1, electron, or duo."
echo

if [ "$DEVICE_TYPE" == "core" ];
then
blue_echo "On the Spark Core, firmware is monolithic, meaning that the system
firmware is packaged with the user firmware.  To use a core with po-util
just manually put it into DFU mode the first time you flash to it."

echo
fi

if [ "$DEVICE_TYPE" == "pi" ];
then
blue_echo "Raspberry Pi is still in beta and you must be registered in the beta
to use Particle on Raspberry Pi.

To update the \"system firmware\" on Raspberry Pi, simply re-install
particle-agent. https://git.io/vynBd"

echo
fi

exit
fi

fi

# Clean firmware directory
if [ "$2" == "clean" ];
then
  DIRWARNING="true"
  find_objects "$3"
  if [ "$FINDDIRFAIL" == "true" ];
  then
    exit
  fi
    git stash &> /dev/null
    echo
    blue_echo "Cleaning firmware..."
    echo
    if [ "$DEVICE_TYPE" == "pi" ];
    then
      make clean -s 2>&1 /dev/null
    else
      make clean -s PLATFORM="$DEVICE_TYPE"  2>&1 /dev/null
    fi

    if [ "$FIRMWAREDIR/../bin" != "$HOME/bin" ];
    then
      rm -rf "$FIRMWAREDIR/../bin"
    fi
    blue_echo "Sucessfully cleaned."
    echo
  exit
fi

# Flash binary over the air
# Use --multi to flash multiple devices at once.  This reads a file named devices.txt
if [ "$2" == "ota" ];
then
  ota "$3"
fi

if [ "$2" == "build" ];
then
  DIRWARNING="true"
  find_objects "$3"
  if [ "$FINDDIRFAIL" == "true" ];
  then
    exit
  fi
    echo
    if [ "$DEVICE_TYPE" == "pi" ];
    then
      build_pi
      echo
      exit
    fi
    build_firmware || exit
    build_message
fi

if [ "$2" == "debug-build" ];
then
  DIRWARNING="true"
  find_objects "$3"
  if [ "$FINDDIRFAIL" == "true" ];
  then
    exit
  fi
    echo
    #configure_makefile
    make all -C "$FIRMWARE_PARTICLE/"firmware APPDIR="$FIRMWAREDIR" TARGET_DIR="$FIRMWAREDIR/../bin" PLATFORM="$DEVICE_TYPE" DEBUG_BUILD="y" || exit
    build_message
fi

if [ "$2" == "flash" ];
then
  DIRWARNING="true"
  find_objects "$3"
  if [ "$FINDDIRFAIL" == "true" ];
  then
    exit
  fi
  if [ "$DEVICE_TYPE" == "pi" ];
  then
    build_pi
    ota "-m"
    exit
  fi
  dfu_open
  echo
  ( build_firmware && echo && green_echo "Building firmware was successful! Flashing with dfu-util..." && echo ) || ( echo && red_echo 'Building firmware failed! Closing DFU...' && echo && dfu-util -d "$DFU_ADDRESS1" -a 0 -i 0 -s "$DFU_ADDRESS2":leave -D /dev/null &> /dev/null && exit )
  dfu-util -d "$DFU_ADDRESS1" -a 0 -i 0 -s "$DFU_ADDRESS2":leave -D "$FIRMWAREDIR/../bin/firmware.bin" || exit #&> /dev/null
  echo
  blue_echo "Firmware successfully flashed to $DEVICE_TYPE on $MODEM"
  echo
  exit
fi

# If an improper command is chosen:
echo
red_echo "Please choose a proper command."
common_commands

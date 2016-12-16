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
# Particle Offline Utility: A handy script for installing and using the Particle
# Toolchain on Linux and OSX. This script downloads and installs:
# dfu-util, nodejs, gcc-arm-embedded, particle-cli, and the Particle Firmware
# source code.
# Read more at https://github.com/nrobinson2000/po-util
# ACII Art Generated from: http://www.patorjk.com/software/taag

# Helper functions
function pause()
{
  read -rp "$*"
}

blue_echo()
{
  echo "$(tput setaf 6)$(tput bold)$MESSAGE$(tput sgr0)"
}

green_echo()
{
  echo "$(tput setaf 2)$(tput bold)$MESSAGE$(tput sgr0)"
}

red_echo()
{
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
      MESSAGE="Firmware directory not found!" ; red_echo
      MESSAGE="Please run \"po init\" to setup this repository or choose a valid directory." ; blue_echo
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
    MESSAGE="devices.txt not found!" ; red_echo
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
      MESSAGE="Firmware Binary not found!" ; red_echo
      MESSAGE="Perhaps you need to build your firmware?" ; blue_echo
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
  MESSAGE="Binary saved to $BINARYDIR/firmware.bin" ; green_echo
  echo
  exit
}

dfu_open()
{
  if [ "$MODEM" != "" ];
  then
  MODEM="$MODEM"
  else
    echo
    MESSAGE="Device not found!" ; red_echo
    echo
    MESSAGE="Your device must be connected by USB."; blue_echo
    echo
    exit
  fi
  stty "$STTYF" "$MODEM" "$DFUBAUDRATE" > /dev/null
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
  MESSAGE="Common commands include:
build, flash, clean, ota, dfu, serial, init, config, setup, library"
  blue_echo
  echo
}


build_firmware()
{
#Temporary fix for http://community.particle.io/t/stm32-usb-otg-driver-error-on-v0-6-0/26814

STRING='CPPSRC += $(call target_files,$(BOOTLOADER_MODULE_PATH)/../hal/src/stm32/,newlib.cpp)'
echo "$STRING" >> "$BASE_FIRMWARE/firmware/bootloader/src/electron/sources.mk"
sed "126s/.*/#define USB_OTG_MAX_TX_FIFOS (4*2)/" "$BASE_FIRMWARE/firmware/platform/MCU/STM32F2xx/SPARK_Firmware_Driver/inc/platform_config.h" > temp.particle
sed "132s/.*/#define USB_OTG_MAX_TX_FIFOS (6*2)/" temp.particle > temp.particle.1
rm -f "$BASE_FIRMWARE/firmware/platform/MCU/STM32F2xx/SPARK_Firmware_Driver/inc/platform_config.h"
mv temp.particle.1 "$BASE_FIRMWARE/firmware/platform/MCU/STM32F2xx/SPARK_Firmware_Driver/inc/platform_config.h"
rm -f temp.particle

  MESSAGE="                                                 __      __  __
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
  blue_echo
  make all -s -C "$BASE_FIRMWARE/"firmware APPDIR="$FIRMWAREDIR" TARGET_DIR="$FIRMWAREDIR/../bin" PLATFORM="$DEVICE_TYPE"
}

build_pi()
{
  if hash docker 2>/dev/null;
  then
    if docker run --rm -i -v $BASE_FIRMWARE/firmware:/firmware -v $FIRMWAREDIR:/input -v $FIRMWAREDIR/../bin:/output particle/buildpack-raspberrypi 2> echo;
    then
      echo
      MESSAGE="Successfully built firmware for Raspberry Pi" ; blue_echo
    else
      echo
      MESSAGE="Build failed." ; red_echo
      echo
      exit 1
    fi
  else
    MESSAGE="Docker not found.  Please install docker to build firmware for Raspberry Pi" ; red_echo
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
    MESSAGE="Please specify which device to flash ota." ; red_echo ; echo ; exit
  fi

  if [ "$1" == "--multi" ] || [ "$1" == "-m" ] || [ "$1" == "-ota" ];
  then
    DEVICEWARNING="true"
    if [ "$FINDDEVICESFAIL" == "true" ];
    then
      cd "$CWD"
      echo "" > devices.txt
      MESSAGE="Please list your devices in devices.txt" ; red_echo
      sleep 3
      exit
    fi
    for DEVICE in $DEVICES ; do
      echo
      MESSAGE="Flashing to device $DEVICE..." ; blue_echo
      particle flash "$DEVICE" "$FIRMWAREBIN" || ( MESSAGE="Your device must be online in order to flash firmware OTA." ; red_echo )
    done
    echo
    exit
  fi
  echo
  MESSAGE="Flashing to device $1..." ; blue_echo
  particle flash "$1" "$FIRMWAREBIN" || ( MESSAGE="Try using \"particle flash\" if you are having issues." ; red_echo )
  echo
  exit
}

config()
{
  echo BASE_FIRMWARE="$BASE_FIRMWARE" >> $SETTINGS
  echo "export PARTICLE_DEVELOP=1" >> $SETTINGS
  echo BINDIR="$BINDIR" >> $SETTINGS
  echo
  MESSAGE="Which branch of the Particle firmware would you like to use?
You can find the branches at https://github.com/spark/firmware/branches
If you are unsure, please enter \"release/stable\"" ; blue_echo
  read -rp "Branch: " branch_variable
  BRANCH="$branch_variable"
  echo BRANCH="$BRANCH" >> $SETTINGS
  echo
  MESSAGE="Which baud rate would you like to use to put devices into DFU mode?
Enter \"default\" for the default Particle baud rate of 14400.
Enter \"po\" to use the po-util recommended baud rate of 19200." ; blue_echo
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
}
# End of helper functions



if [ "$1" == "" ]; # Print help
then
MESSAGE="                                                     __      __  __
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
echo "Copyright (GPL) 2016  Nathan Robinson

Usage: po DEVICE_TYPE COMMAND DEVICE_NAME
       po DFU_COMMAND
       po install [full_install_path]
       po library LIBRARY_COMMAND

Commands:
  install      Download all of the tools needed for development.
               Requires sudo. You can also re-install with this command.
               You can optionally install to an alternate location by
               specifying [full_install_path].
               Example:
                       po install ~/particle

               By default, Firmware is installed in ~/github.

  build        Compile code in \"firmware\" subdirectory.

  flash        Compile code and flash to device using dfu-util.

               NOTE: You can supply another argument to \"build\" and \"flash\"
               to specify which firmware directory to compile.
               Example:
                       po photon flash photon-firmware/

  clean        Refresh all code (Run after switching device or directory).

  init         Initialize a new po-util project.

  update       Update Particle firmware, particle-cli and po-util.

  upgrade      Upgrade system firmware on device.

  ota          Upload code Over The Air using particle-cli.

               NOTE: You can flash code to multiple devices at once by passing
               the -m or --multi argument to \"ota\".
               Example:
                       po photon ota -m product-firmware/

               NOTE: This is different from the product firmware update feature
               in the Particle Console because it updates the firmware of
               devices one at a time and only if the devices are online when
               the command is run.

  serial       Monitor a device's serial output (Close with CRTL-A +D)

  config       Select Particle firmware branch and DFU trigger baud rate.

  setup        Get a device's ID and connect it Wi-Fi. Manually claim it after.

  library      Library manager for po-util.  Run \"po lib\" for more info.
  lib

DFU Commands:
  dfu          Quickly flash pre-compiled code to your device.
               Example:
                       po photon dfu

  dfu-open     Put device into DFU mode.

  dfu-close    Get device out of DFU mode.

Atom Build Shortcuts:
  Build        CTRL-ALT-1   These shortcuts allow you     This requires the
  Flash        CTRL-ALT-2   to run common po-util         \"build\" package for
  Clean        CTRL-ALT-3   commands quickly while        Atom.  Get it with:
  DFU          CTRL-ALT-4   using Atom.                   \"apm install build\"
  OTA          CTRL-ALT-5
"
exit
fi

# Open info page in browser
if [ "$1" == "info" ];
then
  open "https://nrobinson2000.github.io/po-util/"
  exit
fi

# Configuration file is created at "~/.po"
SETTINGS=~/.po
BASE_FIRMWARE=~/github  # These
BRANCH="release/stable" # can
BINDIR=~/bin            # be
DFUBAUDRATE=19200       # changed in the "~/.po" file.

CWD="$(pwd)" # Global Current Working Directory variable

# Mac OSX uses lowercase f for stty command
if [ "$(uname -s)" == "Darwin" ];
  then
    OS="Darwin"
    STTYF="-f"
    MODEM="$(ls -1 /dev/cu.* | grep -vi bluetooth | tail -1)"
  else
    OS="Linux"
    STTYF="-F"
    MODEM="$(ls -1 /dev/* | grep "ttyACM" | tail -1)"

    #THIS COULD BE IMPROVED!
    GCC_ARM_VER=gcc-arm-none-eabi-4_9-2015q3 # Updated to 4.9
    GCC_ARM_PATH=$BINDIR/gcc-arm-embedded/$GCC_ARM_VER/bin/
fi


if [ "$1" == "config" ];
then
  rm "$SETTINGS"
  config
  exit
fi

# Check if we have a saved settings file.  If not, create it.
if [ ! -f $SETTINGS ]
then
  echo
  MESSAGE="Your \"$SETTINGS\" configuration file is missing.  Let's create it:" ; blue_echo
  config
fi

# Import our overrides from the ~/.po file.
source "$SETTINGS"

if [ "$1" == "install" ]; # Install
then

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

  if [ -f ~/.bash_profile ]; #Create .bash_profile
  then
    MESSAGE=".bash_profile present." ; green_echo
  else
    MESSAGE="No .bash_profile present. Installing.." ; red_echo
    echo "
    if [ -f ~/.bashrc ]; then
        . ~/.bashrc
    fi" >> ~/.bash_profile
  fi

  if [ -f ~/.bashrc ];  #Add po alias to .bashrc
  then
    MESSAGE=".bashrc present." ; green_echo
    if grep "po-util.sh" ~/.bashrc ;
    then
      MESSAGE="po alias already in place." ; green_echo
    else
      MESSAGE="no po alias.  Installing..." ; red_echo
      echo 'alias po="~/po-util.sh"' >> ~/.bashrc
      echo 'alias p="particle"' >> ~/.bashrc  #Also add 'p' alias for 'particle'
    fi
  else
    MESSAGE="No .bashrc present.  Installing..." ; red_echo
    echo 'alias po="~/po-util.sh"' >> ~/.bashrc
  fi

  # Download po-util-README.md
  curl -fsSLo ~/.po-util-README.md https://raw.githubusercontent.com/nrobinson2000/po-util/master/po-util-README.md

  # Check to see if we need to override the install directory.
  if [ "$2" ] && [ "$2" != $BASE_FIRMWARE ]
  then
    BASE_FIRMWARE="$2"
    echo BASE_FIRMWARE="$BASE_FIRMWARE" >  $SETTINGS
  fi

  [ -d "$BASE_FIRMWARE" ] || mkdir -p "$BASE_FIRMWARE"  # If BASE_FIRMWARE does not exist, create it

  # clone firmware repository
  cd "$BASE_FIRMWARE" || exit

  if hash git 2>/dev/null;
  then
    NOGIT="false"
    MESSAGE="Installing Particle firmware from Github..." ; blue_echo
    git clone https://github.com/spark/firmware.git
  else
    NOGIT="true"
  fi

  if [ "$OS" == "Linux" ]; # Linux installation steps
  then

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
    cd "$BASE_FIRMWARE" || exit
    # Install dependencies
    MESSAGE="Installing ARM toolchain and dependencies locally in $BINDIR/gcc-arm-embedded/..." ; blue_echo
    mkdir -p $BINDIR/gcc-arm-embedded && cd "$_" || exit

    if [ -d "$GCC_ARM_VER" ]; #
    then
        echo
        MESSAGE="ARM toolchain version $GCC_ARM_VER is already downloaded... Continuing..." ; blue_echo
    else
        curl -LO https://launchpad.net/gcc-arm-embedded/4.9/4.9-2015-q3-update/+download/gcc-arm-none-eabi-4_9-2015q3-20150921-linux.tar.bz2 #Update to v4.9
        tar xjf gcc-arm-none-eabi-*-linux.tar.bz2

        MESSAGE="Creating links in /usr/local/bin..." ; blue_echo
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
    MESSAGE="Node.js version $NODEVERSION is already installed."; blue_echo
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
    MESSAGE="Installing dfu-util (requires sudo)..." ; blue_echo
    cd "$BASE_FIRMWARE" || exit
    git clone git://git.code.sf.net/p/dfu-util/dfu-util
    cd dfu-util || exit
    git pull
    ./autogen.sh
    ./configure
    make
    sudo make install
    cd ..

    # Install particle-cli
    MESSAGE="Installing particle-cli..." ; blue_echo
    sudo npm install -g node-pre-gyp npm particle-cli

    # Install udev rules file
    MESSAGE="Installing udev rule (requires sudo) ..." ; blue_echo
    curl -fsSLO https://raw.githubusercontent.com/nrobinson2000/po-util/master/60-po-util.rules
    sudo mv 60-po-util.rules /etc/udev/rules.d/60-po-util.rules

    MESSAGE="Adding $USER to plugdev group..." ; blue_echo
    sudo usermod -a -G plugdev "$USER"

  fi # CLOSE: "$OS" == "Linux"

  if [ "$OS" == "Darwin" ]; # Mac installation steps
  then
    # Install Homebrew
    MESSAGE="Installing Brew..." ; blue_echo
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    brew tap PX4/homebrew-px4
    brew update

    # Install ARM toolchain
    MESSAGE="Installing ARM toolchain..." ; blue_echo
    brew install gcc-arm-none-eabi dfu-util gnu-sed

    # Install Node.js

    # curl -Ss https://nodejs.org/dist/ > node-result.txt
    # grep "<a href=\"v" "node-result.txt" > node-new.txt
    # tail -1 node-new.txt > node-oneline.txt
    # sed -n 's/.*\"\(.*.\)\".*/\1/p' node-oneline.txt > node-version.txt
    # NODEVERSION="$(cat node-version.txt)"
    # NODEVERSION="${NODEVERSION%?}"

    NODEVERSION="v6.9.1"
    INSTALLVERSION="node-$NODEVERSION"

    # rm node-*.txt

    if [ "$(node -v)" == "$NODEVERSION" ];
    then
    MESSAGE="Node.js version $NODEVERSION is already installed." ; blue_echo
    else
    MESSAGE="Installing Node.js version $NODEVERSION..." ; blue_echo
    curl -fsSLO "https://nodejs.org/dist/$NODEVERSION/$INSTALLVERSION.pkg"
    sudo installer -pkg node-*.pkg -target /
    rm -rf node-*.pkg
    rm -f node-*.txt
    fi

    # Install particle-cli
    MESSAGE="Installing particle-cli..." ; blue_echo
    sudo npm install -g node-pre-gyp npm serialport particle-cli
  fi # CLOSE: "$OS" == "Darwin"

  cd "$BASE_FIRMWARE" || exit

  if [ "$NOGIT" == "true" ];
  then
    MESSAGE="Installing Particle firmware from Github..." ; blue_echo
    git clone https://github.com/spark/firmware.git
  fi

  MESSAGE="
  Thank you for installing po-util. Be sure to check out https://po-util.com/
  if you have any questions, suggestions, comments, or problems.  You can use
  the Message button in the bottom right corner of the site to send me a
  private message. If need to update po-util just run \"po update\" to download
  the latest versions of po-util, Particle Firmware and particle-cli, or run
  \"po install\" to update all dependencies.
  " ; green_echo
  source ~/.bashrc
  exit
fi

# Create our project files
if [ "$1" == "init" ];
then
  if [ -d firmware ];
  then
    echo
    MESSAGE="Directory is already Initialized!" ; green_echo
    echo
    exit
  fi

if [ "$2" == "photon" ] || [ "$2" == "P1" ] || [ "$2" == "electron" ] || [ "$2" == "pi" ];
then
DEVICE_TYPE="$2"
else
echo
  MESSAGE="Please specify which device type you will be using.
Example:
  po init photon" ; blue_echo
echo
  exit
fi
  mkdir firmware/
  echo "#include \"Particle.h\"

void setup() // Put setup code here to run once
{

}

void loop() // Put code here to loop forever
{

}" > firmware/main.cpp

  cp ~/.po-util-README.md README.md

echo "---
cmd: ~/po-util.sh $DEVICE_TYPE build

targets:
  Build:
    args:
      - $DEVICE_TYPE
      - build
    cmd: ~/po-util.sh
    keymap: ctrl-alt-1
    name: Build
  Flash:
    args:
      - $DEVICE_TYPE
      - flash
    cmd: ~/po-util.sh
    keymap: ctrl-alt-2
    name: Flash
  Clean:
    args:
      - $DEVICE_TYPE
      - clean
    cmd: ~/po-util.sh
    keymap: ctrl-alt-3
    name: Clean
  DFU:
    args:
      - $DEVICE_TYPE
      - dfu
    cmd: ~/po-util.sh
    keymap: ctrl-alt-4
    name: DFU
  OTA:
    args:
      - $DEVICE_TYPE
      - ota
      - --multi
    cmd: ~/po-util.sh
    keymap: ctrl-alt-5
    name: DFU
" >> .atom-build.yml

echo
MESSAGE="Directory initialized as a po-util project for $DEVICE_TYPE" ; green_echo
echo
exit
fi

# Open serial monitor for device
if [ "$1" == "serial" ];
then
  if [ "$MODEM" == "" ]; # Don't run screen if device is not connected
  then
    MESSAGE="No device connected!" red_echo ; exit
  else
    screen -S particle "$MODEM"
    screen -S particle -X quit && exit || MESSAGE="If \"po serial\" is putting device into DFU mode, power off device, removing battery for Electron, and run \"po serial\" several times.
This bug will hopefully be fixed in a later release." && blue_echo
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
  MESSAGE="Updating firmware..." ; blue_echo
  cd "$BASE_FIRMWARE"/firmware || exit
  git stash
  #git checkout $BRANCH
  git pull
  MESSAGE="Updating particle-cli..." ; blue_echo
  sudo npm update -g particle-cli
  MESSAGE="Updating po-util.." ; blue_echo
  rm ~/po-util.sh
  curl -fsSLo ~/po-util.sh https://raw.githubusercontent.com/nrobinson2000/po-util/master/po-util.sh
  chmod +x ~/po-util.sh
  rm ~/.po-util-README.md
  curl -fsSLo ~/.po-util-README.md https://raw.githubusercontent.com/nrobinson2000/po-util/master/po-util-README.md
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
      rm "$FIRMWAREDIR/$file_base.h" &> /dev/null
      rm "$FIRMWAREDIR/$file_base.cpp" &> /dev/null
    fi
  done

  echo
  MESSAGE="Removed all symlinks. This can be undone with \"po lib setup\"" ; blue_echo
  echo
  exit
  fi

  if [ "$2" == "setup" ];
  then
    DIRWARNING="true"
    find_objects "$3"
    cd "$LIBRARY"

    cat $FIRMWAREDIR/../libs.txt | while read i  ## Install and add required libs from libs.txt
    do
      LIB_NAME="$(echo $i | awk '{ print $NF }' )"

         if (ls -1 "$LIBRARY" | grep "$LIB_NAME") &> /dev/null ;
         then
           echo
           MESSAGE="Library $LIB_NAME is already installed..." ; blue_echo
         else
           echo
           MESSAGE="Dowloading library $LIB_NAME..." ; blue_echo
           echo
           git clone $i
          fi


          if [ -f "$FIRMWAREDIR/$LIB_NAME.cpp" ] || [ -f "$FIRMWAREDIR/$LIB_NAME.h" ];
          then
            echo
            MESSAGE="Library $LIB_NAME is already added to this project..." ; red_echo
          else
            echo
            MESSAGE="Adding library $LIB_NAME to this project..." ; green_echo

            if [ -f "$LIBRARY/$LIB_NAME/$LIB_NAME.cpp" ] || [ -f "$LIBRARY/$LIB_NAME/$LIB_NAME.h" ];
            then
              ln -s "$LIBRARY/$LIB_NAME/$LIB_NAME.cpp" "$FIRMWAREDIR"
              ln -s "$LIBRARY/$LIB_NAME/$LIB_NAME.h" "$FIRMWAREDIR"
            else
              if [ -f "$LIBRARY/$LIB_NAME/firmware/$LIB_NAME.cpp" ] || [ -f "$LIBRARY/$LIB_NAME/firmware/$LIB_NAME.h" ];
              then
                ln -s "$LIBRARY/$LIB_NAME/firmware/$LIB_NAME.cpp" "$FIRMWAREDIR"
                ln -s "$LIBRARY/$LIB_NAME/firmware/$LIB_NAME.h" "$FIRMWAREDIR"
              fi

            fi

          fi

    done
    echo
    exit
  fi

  if [ "$2" == "get" ] || [ "$2" == "install" ]; # Download a library with git OR Install from libs.txt
  then
    DIRWARNING="true"
    find_objects "$4"

    cd "$LIBRARY"


        if [ "$3" == "" ]; # Install from libs.txt
        then

          cat $FIRMWAREDIR/../libs.txt | while read i
          do
            LIB_NAME="$(echo $i | awk '{ print $NF }' )"

               if (ls -1 "$LIBRARY" | grep "$LIB_NAME") &> /dev/null ;
               then
                 echo
                 MESSAGE="Library $LIB_NAME is already installed..." ; blue_echo
               else
                 echo
                 MESSAGE="Dowloading library $LIB_NAME..." ; blue_echo
                 echo
                 git clone $i
                fi

          done
          echo
          exit
        fi

    if [ "$4" != "" ];  # Download a library with git
    then
      git clone "$3" "$4" || ( echo ; MESSAGE="Could not download Library.  Please supply a valid URL to a git repository." ; red_echo )
      exit
    else
      git clone "$3" || ( echo ; MESSAGE="Could not download Library.  Please supply a valid URL to a git repository." ; red_echo )
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
      if [ "$answer" == "yes" ] || [ "$answer" == "y" ] || [ "$answer" == "y" ];
      then
        echo
        MESSAGE="Purging library $3..." ; blue_echo
        rm -rf "${LIBRARY:?}/$3"
        echo
        MESSAGE="Library $3 has been purged." ; green_echo
        echo
      else
        echo
        MESSAGE="Aborting..." ; blue_echo
        exit
      fi
    else
      MESSAGE="Library not found." ; red_echo
    fi
    exit
  fi

  if [ "$2" == "create" ]; # Create a libraries in "$LIBRARY" from files in "$FIRMWAREDIR"  This for when mutiple libraries are packaged together and they need to be separated.
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
          MESSAGE="Creating library $file_base..." ; blue_echo
          cp "$FIRMWAREDIR/$file_base.h" "$LIBRARY/$file_base"
          cp "$FIRMWAREDIR/$file_base.cpp" "$LIBRARY/$file_base"
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
      echo
      MESSAGE="Please choose a library to add." ; red_echo ; exit
    fi

    if [ -d "$LIBRARY/$3" ];
    then
      echo "Found" > /dev/null
    else
      echo
      MESSAGE="Library $3 not found" ; red_echo ; echo ; exit
    fi

    if [ -f "$FIRMWAREDIR/$3.cpp" ] || [ -f "$FIRMWAREDIR/$3.h" ];
    then
      echo
      MESSAGE="Library $3 is already imported" ; red_echo ; echo ; exit
    else

      if [ -f "$LIBRARY/$3/$3.cpp" ] || [ -f "$LIBRARY/$3/$3.h" ];
      then
        ln -s "$LIBRARY/$3/$3.cpp" "$FIRMWAREDIR"
        ln -s "$LIBRARY/$3/$3.h" "$FIRMWAREDIR"
      else
        if [ -f "$LIBRARY/$3/firmware/$3.cpp" ] || [ -f "$LIBRARY/$3/firmware/$3.h" ];
        then
          ln -s "$LIBRARY/$3/firmware/$3.cpp" "$FIRMWAREDIR"
          ln -s "$LIBRARY/$3/firmware/$3.h" "$FIRMWAREDIR"
        fi

      fi

      #Add entries to libs.txt file
      LIB_URL="$( cd $LIBRARY/$3 && git config --get remote.origin.url )"

      echo "$LIB_URL $3" >> "$FIRMWAREDIR/../libs.txt"

    echo
    MESSAGE="Imported library $3" ; green_echo
    echo
    MESSAGE="Add #include \"$3.h\" to your main.cpp to use the library" ; blue_echo
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
      MESSAGE="Please choose a library to remove." ; red_echo ; exit
    fi

    if [ -f "$FIRMWAREDIR/$3.cpp" ] && [ -f "$FIRMWAREDIR/$3.h" ];
    then
      echo
      MESSAGE="Found library $3" ; green_echo
    else
      echo
      MESSAGE="Library $3 not found" ; red_echo ; echo ; exit
    fi

    if [ -d "$LIBRARY/$3" ];
    then
      echo
      MESSAGE="Library $3 is backed up, removing from project..." ; blue_echo
      rm "$FIRMWAREDIR/$3.cpp"
      rm "$FIRMWAREDIR/$3.h"
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
      exit
    else
      echo
      read -rp "Library $3 is not backed up.  Are you sure you want to remove it ? (yes/no): " answer
      if [ "$answer" == "yes" ] || [ "$answer" == "y" ] || [ "$answer" == "y" ];
      then
        echo
        MESSAGE="Removing library $3..." ; blue_echo
        rm "$FIRMWAREDIR/$3.cpp"
        rm "$FIRMWAREDIR/$3.h"
        echo
        MESSAGE="Library $3 has been purged." ; green_echo
        exit
      else
        echo
        MESSAGE="Aborting..." ; blue_echo
        exit
      fi
    fi
    exit
  fi # Close remove

  if [ "$2" == "list" ] || [ "$2" == "ls" ];
  then
    echo
    MESSAGE="The following Particle libraries have been downloaded:" ; blue_echo
    echo
    ls -m "$LIBRARY"
    echo
    exit
  fi # Close list

    if [ "$2" == "package" ] || [ "$2" == "pack" ];
    then
      DIRWARNING="true"
      find_objects "$3"

      if [ -d "$FIRMWAREDIR/../packaged-firmware" ];
      then
        rm -rf "$FIRMWAREDIR/../packaged-firmware"
      fi

      mkdir "$FIRMWAREDIR/../packaged-firmware"
      cd "$FIRMWAREDIR"
      cp * "$FIRMWAREDIR/../packaged-firmware"
    exit
    fi

  if [ "$2" == "help" ] || [ "$2" == "" ]; # SHOW HELP TEXT FOR "po library"
  then

    echo "
\"po library\": The Particle Library manager for po-util.
                Libraries are kept in ~/.po-util/lib

Commands:
  get          Download a Particle Library from GitHub and optionally name it.
  install      If run with no arguments, libraries listed in a \"libs.txt\" are
               installed.

               Example of getting a library from Git:
                      po lib get https://github.com/user/libraryName libraryName

  add          Add a downloaded library to a po-util project.
  import       Libraries are added in the firmware directory as soft links.
               Additionally, the library information is added to \"libs.txt\"
               so that you can keep track of your libraries and restore them in
               the future.

               Example adding an installed library to a project:
                      po lib add libraryName

  remove       Remove a library from a po-util project.
  rm           Just the soft links are deleted.
               Example:
                      po lib rm libraryName

  create       Create other libraries from other C++ files in a library.
               Example:
                      cd ~/.po-util/lib/someLibWithOtherLibsInside
                      po lib create

  purge        Uninstall (delete) a library from ~/.po-util/lib
               Example:
                      po lib purge someLibrary

  list         Show all libraries in ~/.po-util/lib

  setup        A combination of \"po lib install\" and \"po lib add\".
               Libraries listed in \"libs.txt\" are installed and symlinks are
               created.

  clean        The automatic verision of \"po lib rm\".  All symlinks in the
               project are removed, but \"libs.txt\" is untouched.  This is
               ideal for releasing you project, not having to have the library
               source files in your \"firmware\" directory, but rather just a
               list that people can \"po lib setup\" to download your project's
               dependencies.

  update       Update all of your libraries.
  refresh

  help         Show this help documentation.
    "
  exit
fi # Close help

if [ "$2" == "update" ] || [ "$2" == "refresh" ]; # Update all libraries
then
  echo

  if [ "$(ls -1 $LIBRARY)" == "" ];
  then
    MESSAGE="No libraries installed.  Use \"po lib get\" to download some." ; red_echo
    exit
  fi

  for OUTPUT in $(ls -1 "$LIBRARY")
  do
  	cd "$LIBRARY/$OUTPUT"
    MESSAGE="Updating library $OUTPUT..." ; blue_echo
    echo
    git pull
    echo
  done
  exit
fi # Close Update

  echo
  MESSAGE="Please choose a valid command, or run \"po lib\" for help." ; red_echo
  echo
  exit
fi # Close Library
####################

cd "$BASE_FIRMWARE"/firmware || exit

# Make sure we are using photon, P1, electron or pi
if [ "$1" == "photon" ] || [ "$1" == "P1" ] || [ "$1" == "electron" ] || [ "$1" == "pi" ]; # || [ "$1" == "raspberry" ] || [ "$1" == "raspberrypi" ];
then
  DEVICE_TYPE="$1"

  if [ "$DEVICE_TYPE" == "pi" ];
  then
    switch_branch "feature/raspberry-pi"
  else
    switch_branch
  fi
else
  echo
  MESSAGE="Please choose \"photon\", \"P1\", \"electron\", or \"pi\", or choose a proper command." ; red_echo
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
MESSAGE="You should now be able to claim your device.  Please run
\"particle device add Device_ID\", using the Device_ID we found above." ; blue_echo
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
  MESSAGE="Flashing $FIRMWAREBIN with dfu-util..." ; blue_echo
  echo
  dfu-util -d "$DFU_ADDRESS1" -a 0 -i 0 -s "$DFU_ADDRESS2":leave -D "$FIRMWAREBIN" || ( MESSAGE="Device not found." ; red_echo )
  echo
  MESSAGE="Firmware successfully flashed to $DEVICE_TYPE on $MODEM" ; blue_echo
  echo
  exit
fi

#Upgrade our firmware on device
if [ "$2" == "upgrade" ] || [ "$2" == "patch" ] || [ "$2" == "update" ];
then
  pause "Connect your device and put into DFU mode. Press [ENTER] to continue..."
  cd "$CWD" || exit
  sed "2s/.*/START_DFU_FLASHER_SERIAL_SPEED=$DFUBAUDRATE/" "$BASE_FIRMWARE/firmware/build/module-defaults.mk" > temp.particle
  rm -f "$BASE_FIRMWARE/firmware/build/module-defaults.mk"
  mv temp.particle "$BASE_FIRMWARE/firmware/build/module-defaults.mk"

  cd "$BASE_FIRMWARE/firmware/modules/$DEVICE_TYPE/system-part1" || exit
  make clean all PLATFORM="$DEVICE_TYPE" program-dfu

  cd "$BASE_FIRMWARE/firmware/modules/$DEVICE_TYPE/system-part2" || exit
  make clean all PLATFORM="$DEVICE_TYPE" program-dfu
  cd "$BASE_FIRMWARE/firmware" && git stash || exit
  sleep 1
  dfu-util -d $DFU_ADDRESS1 -a 0 -i 0 -s $DFU_ADDRESS2:leave -D /dev/null &> /dev/null
  exit
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
    MESSAGE="Cleaning firmware..." ; blue_echo
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
    MESSAGE="Sucessfully cleaned." ; blue_echo
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
    make all -C "$BASE_FIRMWARE/"firmware APPDIR="$FIRMWAREDIR" TARGET_DIR="$FIRMWAREDIR/../bin" PLATFORM="$DEVICE_TYPE" DEBUG_BUILD="y" || exit
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
  build_firmware || (MESSAGE='Building firmware failed! Closing DFU...' && echo && red_echo && echo && dfu-util -d "$DFU_ADDRESS1" -a 0 -i 0 -s "$DFU_ADDRESS2":leave -D /dev/null &> /dev/null && exit)
  echo
  MESSAGE="Building firmware was successful! Flashing with dfu-util..."
  green_echo
  echo
  dfu-util -d "$DFU_ADDRESS1" -a 0 -i 0 -s "$DFU_ADDRESS2":leave -D "$FIRMWAREDIR/../bin/firmware.bin" || exit #&> /dev/null
  echo
  MESSAGE="Firmware successfully flashed to $DEVICE_TYPE on $MODEM" ; blue_echo
  echo
  exit
fi

# If an improper command is chosen:
echo
MESSAGE="Please choose a proper command." ; red_echo
common_commands

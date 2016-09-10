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
#   ██/                               https://po-util.com
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
    MESSAGE="Your device must be connected by USB."; blue_echo
    echo
    exit
  fi
  stty "$STTYF" "$MODEM" "$DFUBAUDRATE" > /dev/null
}

switch_branch()
{
  if [ "$(git rev-parse --abbrev-ref HEAD)" != "$BRANCH" ];
  then
    git checkout "$BRANCH" > /dev/null
  fi
}

common_commands() #List common commands
{
  echo
  MESSAGE="Common commands include:
build, flash, clean, ota, dfu, serial, init"
  blue_echo
  echo
}

build_firmware()
{
  make all -s -C "$BASE_FIRMWARE/"firmware APPDIR="$FIRMWAREDIR" TARGET_DIR="$FIRMWAREDIR/../bin" PLATFORM="$1" || exit
}


config()
{
  echo BASE_FIRMWARE="$BASE_FIRMWARE" >> $SETTINGS
  echo PARTICLE_DEVELOP="1" >> $SETTINGS
  echo BINDIR="$BINDIR" >> $SETTINGS
  echo
  MESSAGE="Which branch of the Particle firmware would you like to use?
You can find the branches at https://github.com/spark/firmware/branches
If you are unsure, please enter \"latest\"" ; blue_echo
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
            ██/                               https://po-util.com
"
blue_echo
echo "Copyright (GPL) 2016  Nathan Robinson

Usage: po DEVICE_TYPE COMMAND DEVICE_NAME
       po DFU_COMMAND
       po install [full_install_path]

Commands:
  install      Download all of the tools needed for development.
               Requires sudo. You can also re-install with this command.
               You can optionally install to an alternate location by
               specifying [full_install_path].
               Example:
                       po install ~/particle

               By default, Firmware is installed in ~/github.

  build        Compile code in \"firmware\" subdirectory
  flash        Compile code and flash to device using dfu-util

               NOTE: You can supply another argument to \"build\" and \"flash\"
               to specify which firmware directory to compile.
               Example:
                       po photon flash photon-firmware/

  clean        Refresh all code (Run after switching device or directory)
  init         Initialize a new po-util project
  update       Update Particle firmware, particle-cli and po-util
  upgrade      Upgrade system firmware on device
  ota          Upload code Over The Air using particle-cli

               NOTE: You can flash code to multiple devices at once by passing
               the -m or --multi argument to \"ota\".
               Example:
                       po photon ota -m product-firmware/

               NOTE: This is different from the product firmware update feature
               in the Particle Console because it updates the firmware of
               devices one at a time and only if the devices are online when
               the command is run.

  serial       Monitor a device's serial output (Close with CRTL-A +D)
  config       Select Particle firmware branch and DFU trigger baud rate

DFU Commands:
  dfu         Quickly flash pre-compiled code to your device.
              Example:
                      po photon dfu

  dfu-open    Put device into DFU mode
  dfu-close   Get device out of DFU mode
"
MESSAGE="If you like po-util, don't forget to share it on social media so that
more users will be able to discover it.  https://po-util.com/
" ; green_echo
exit
fi

# Open info page in browser
if [ "$1" == "info" ];
then
  open "https://po-util.com"
  exit
fi

# Configuration file is created at "~/.po"
SETTINGS=~/.po
BASE_FIRMWARE=~/github # These
BRANCH="latest"        # can
BINDIR=~/bin           # be
DFUBAUDRATE=19200      # changed in the "~/.po" file.

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
  config "$@"
  exit
fi

# Check if we have a saved settings file.  If not, create it.
if [ ! -f $SETTINGS ]
then
  echo
  MESSAGE="Your \"$SETTINGS\" configuration file is missing.  Let's create it:" ; blue_echo
  config "$@"
fi

# Import our overrides from the ~/.po file.
source "$SETTINGS"

if [ "$1" == "install" ]; # Install
then

  if [ "$CWD" != "$HOME" ];
  then
    cp po-util.sh ~/po-util.sh #Replace ~/po-util.sh with one in current directory.
    chmod +x ~/po-util.sh
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
  MESSAGE="Installing Particle firmware from Github..." ; blue_echo
  git clone https://github.com/spark/firmware.git

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
    fi

    MESSAGE="Creating links in /usr/local/bin..." ; blue_echo
    sudo ln -s $GCC_ARM_PATH* /usr/local/bin # LINK gcc-arm-none-eabi

    if [ "$DISTRO" != "arch" ];
    then

    # Install Node.js
    curl -Ss https://nodejs.org/dist/ > node-result.txt
    cat node-result.txt | grep "<a href=\"v" > node-new.txt
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
      MESSAGE="Installing Node.js version $NODEVERSION..." ; blue_echo
      curl -Ss https://api.github.com/repos/nodesource/distributions/contents/"$DISTRO" | grep "name"  | grep "setup_"| grep -v "setup_iojs"| grep -v "setup_dev" > node-files.txt
      tail -1 node-files.txt > node-oneline.txt
      sed -n 's/.*\"\(.*.\)\".*/\1/p' node-oneline.txt > node-version.txt
      MESSAGE="Installing Node.js version $(cat node-version.txt)..." blue_echo
      curl -sL https://"$DISTRO".nodesource.com/"$(cat node-version.txt)" | sudo -E bash -
      rm -rf node-*.txt
    fi
    fi

    #TODO: Work more on supporting other Linux Distributions.

    if [ "$DISTRO" == "deb" ];
    then
        sudo $INSTALLER nodejs python-software-properties python g++ make build-essential libusb-1.0-0-dev libarchive-zip-perl screen libc6-i386 
    fi

    if [ "$DISTRO" == "rpm" ];
    then
        sudo $INSTALLER nodejs python make automake gcc gcc-c++ kernel-devel libusb glibc.1686 vim-common perl-Archive-Zip-1.58-1.fc24.noarch screen
    fi

    if [ "$DISTRO" == "arch" ];
    then
        sudo $INSTALLER nodejs npm python gcc make automake libusb lib32-glibc vim yaourt screen
        yaourt perl-archive-zip
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
    sudo adduser "$USER" plugdev

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
    brew install gcc-arm-none-eabi dfu-util

    # Install Node.js
    curl -Ss https://nodejs.org/dist/ > node-result.txt
    cat node-result.txt | grep "<a href=\"v" > node-new.txt
    tail -1 node-new.txt > node-oneline.txt
    sed -n 's/.*\"\(.*.\)\".*/\1/p' node-oneline.txt > node-version.txt
    NODEVERSION="$(cat node-version.txt)"
    NODEVERSION="${NODEVERSION%?}"
    INSTALLVERSION="node-$NODEVERSION"
    rm node-*.txt
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
    MESSAGE="Directory is already Initialized!" ; green_echo
    exit
  fi

  mkdir firmware/
  echo "#include \"application.h\"

void setup() // Put setup code here to run once
{

}

void loop() // Put code here to loop forever
{

}" > firmware/main.cpp
  cp *.cpp firmware/
  cp *.h firmware/
  cp ~/.po-util-README.md README.md
  MESSAGE="Copied c++ files into firmware directory.  Setup complete." ; green_echo
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
  dfu-util -d 2b04:D006 -a 0 -i 0 -s 0x080A0000:leave -D /dev/null
  exit
fi

# Update po-util
if [ "$1" == "update" ];
then
  MESSAGE="Updating firmware..." ; blue_echo
  cd "$BASE_FIRMWARE"/firmware || exit
  git checkout $BRANCH
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

# Make sure we are using photon, P1, or electron
if [ "$1" == "photon" ] || [ "$1" == "P1" ] || [ "$1" == "electron" ];
then
  echo
  MESSAGE="$1 selected." ; blue_echo
else
  echo
  MESSAGE="Please choose \"photon\", \"P1\" or \"electron\", or choose a proper command." ; red_echo
  common_commands
  exit
fi

cd "$BASE_FIRMWARE"/firmware || exit

if [ "$1" == "photon" ];
then
  switch_branch
  DFU_ADDRESS1="2b04:D006"
  DFU_ADDRESS2="0x080A0000"
fi

if [ "$1" == "P1" ];
then
  switch_branch
  DFU_ADDRESS1="2b04:D008"
  DFU_ADDRESS2="0x080A0000"
fi

if [ "$1" == "electron" ];
then
  switch_branch
  DFU_ADDRESS1="2b04:d00a"
  DFU_ADDRESS2="0x08080000"
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
  dfu-util -d "$DFU_ADDRESS1" -a 0 -i 0 -s "$DFU_ADDRESS2":leave -D "$FIRMWAREBIN" || ( MESSAGE="Device not found." ; red_echo )
  exit
fi

#Upgrade our firmware on device
if [ "$2" == "upgrade" ] || [ "$2" == "patch" ] || [ "$2" == "update" ];
then
  pause "Connect your device and put into DFU mode. Press [ENTER] to continue..."
  cd "$CWD" || exit
  sed "2s/.*/START_DFU_FLASHER_SERIAL_SPEED=$DFUBAUDRATE/" "$BASE_FIRMWARE/"firmware/build/module-defaults.mk > temp.particle
  rm -f "$BASE_FIRMWARE"/firmware/build/module-defaults.mk
  mv temp.particle "$BASE_FIRMWARE"/firmware/build/module-defaults.mk

  cd "$BASE_FIRMWARE/firmware/modules/$1/system-part1" || exit
  make clean all PLATFORM="$1" program-dfu

  cd "$BASE_FIRMWARE/firmware/modules/$1/system-part2" || exit
  make clean all PLATFORM="$1" program-dfu
  cd "$BASE_FIRMWARE/firmware" && git stash || exit
  sleep 1
  dfu-util -d $DFU_ADDRESS1 -a 0 -i 0 -s $DFU_ADDRESS2:leave -D /dev/null
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

    make clean -s PLATFORM="$1" 2>&1 /dev/null
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
  DIRWARNING="true"
  BINWARNING="true"
  find_objects "$4"
  if [ "$FINDDIRFAIL" == "true" ] || [ "$FINDBINFAIL" == "true" ];
  then
    exit
  fi

  if [ "$3" == "" ];
  then
    MESSAGE="Please specify which device to flash ota." ; red_echo ; exit
  fi

  if [ "$3" == "--multi" ] || [ "$3" == "-m" ];
  then
    DEVICEWARNING="true"
    find_objects "$4"

    if [ "$FINDDEVICESFAIL" == "true" ];
    then
      exit
    fi

    for DEVICE in $DEVICES ; do
      echo
      MESSAGE="Flashing to device $DEVICE..." ; blue_echo
      particle flash "$DEVICE" "$FIRMWAREBIN" || ( MESSAGE="Your device must be online in order to flash firmware OTA." ; red_echo )
    done
    exit
  fi
  echo
  MESSAGE="Flashing to device $3..." ; blue_echo
  particle flash "$3" "$FIRMWAREBIN" || ( MESSAGE="Try using \"particle flash\" if you are having issues." ; red_echo )
  exit
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
    build_firmware "$1"
    build_message "$@"
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
    make all -C "$BASE_FIRMWARE/"firmware APPDIR="$FIRMWAREDIR" TARGET_DIR="$FIRMWAREDIR/../bin" PLATFORM="$1" DEBUG_BUILD="y" || exit
    build_message "$@"
fi

if [ "$2" == "flash" ];
then
  DIRWARNING="true"
  find_objects "$3"
  if [ "$FINDDIRFAIL" == "true" ];
  then
    exit
  fi
  dfu_open
  build_firmware "$1"
  dfu-util -d "$DFU_ADDRESS1" -a 0 -i 0 -s "$DFU_ADDRESS2":leave -D "$FIRMWAREDIR/../bin/firmware.bin"
  exit
fi

# If an improper command is chosen:
echo
MESSAGE="Please choose a proper command." ; red_echo
common_commands

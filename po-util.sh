#!/bin/bash
# Particle Offline Utility: A handy script for installing and using the Particle
# Toolchain on Ubuntu-based distros and OSX. This script downloads and installs:
# dfu-util, nodejs, gcc-arm-embedded, particle-cli, and the Particle Firmware
# source code.
# Read more at https://github.com/nrobinson2000/po-util
# ACII Art Generated from: http://www.patorjk.com/software/taag

function pause(){
   read -p "$*"
}

blue_echo() {
    echo "$(tput setaf 6)$(tput bold)$MESSAGE$(tput sgr0)"
}

green_echo() {
    echo "$(tput setaf 2)$(tput bold)$MESSAGE$(tput sgr0)"
}

red_echo() {
    echo "$(tput setaf 1)$(tput bold)$MESSAGE$(tput sgr0)"
}

if [ "$1" == "" ]; # Print help
then
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
        ██/                               http://po-util.com
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
               Ex.:
                   po install ~/particle

               By default, Firmware is installed in ~/github.

  build        Compile code in \"firmware\" subdirectory
  flash        Compile code and flash to device using dfu-util
  clean        Refresh all code (Run after switching device or directory)
  init         Initialize a new po-util project
  update       Update Particle firmware, particle-cli and po-util
  upgrade      Upgrade system firmware on device
  ota          Upload code Over The Air using particle-cli
  serial       Monitor a device's serial output (Close with CRTL-A +D)

DFU Commands:
  dfu         Quickly flash pre-compiled code
  dfu-open    Put device into DFU mode
  dfu-close   Get device out of DFU mode
" && exit
fi



# Holds any alternate paths.
SETTINGS=~/.po
BASE_FIRMWARE=~/github
BRANCH="latest"
BINDIR=~/bin

CWD="$(pwd)"

# Mac OSX uses lowercase f for stty command
if [ "$(uname -s)" == "Darwin" ];
  then
    # MESSAGE="OSX detected..." ; green_echo #FIXME: This is spammy
    OS="Darwin"
    STTYF="-f"
    MODEM="$(ls -1 /dev/cu.* | grep -vi bluetooth | tail -1)"
  else
    # MESSAGE="Linux detected..." ; green_echo #FIXME: This is spammy
    OS="Linux"
    STTYF="-F"
    MODEM="$(ls -1 /dev/* | grep "ttyACM" | tail -1)"

    # Runs script commands with our specific version of GCC from local.  May not need to be exported.
    # TODO: Change this to use regex, so we get this version or later - Futureproof
    GCC_ARM_VER=gcc-arm-none-eabi-4_8-2014q2
    # MESSAGE="Setting our paths for gcc-arm-none-eabi" ; green_echo #FIXME: This is spammy
    export GCC_ARM_PATH=$BINDIR/gcc-arm-embedded/$GCC_ARM_VER/bin/
    export PATH=$GCC_ARM_PATH:$PATH
    # echo `echo $PATH | grep $GCC_ARM_VER` && MESSAGE=" Path Set." ; green_echo #FIXME: This is spammy
    # Additional option which SHOULD take place for make.
    # alias arm-none-eabi-gcc=$BINDIR/gcc-arm-embedded/$GCC_ARM_VER/bin/arm-none-eabi-gcc  #FIXME: This does not work to fix Travis CI
fi

# Check if we have a saved settings file.  If not, create it.
if [ ! -f $SETTINGS ]
then
  echo BASE_FIRMWARE="$BASE_FIRMWARE" >> $SETTINGS
  echo BRANCH="latest" >> $SETTINGS
  echo PARTICLE_DEVELOP=1 >> $SETTINGS
  echo BINDIR="$BINDIR" >> $SETTINGS

  if [ $OS == "Linux" ];
    then
      echo export GCC_ARM_PATH=$GCC_ARM_PATH >> $SETTINGS
  fi
fi

# Import our overrides from the ~/.po file.
source $SETTINGS

# GCC path for linux make utility
if [ $GCC_ARM_PATH ]; then GCC_MAKE=GCC_ARM_PATH=$GCC_ARM_PATH ; fi

if [ "$1" == "install" ]; # Install
then

  rm ~/po-util.sh
  cp po-util.sh ~/po-util.sh #Replace ~/po-util.sh with one in current directory.

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
    fi
  else
    MESSAGE="No .bashrc present.  Installing..." ; red_echo
    echo 'alias po="~/po-util.sh"' >> ~/.bashrc
  fi

  # Check to see if we need to override the install directory.
  if [ "$2" ] && [ "$2" != $BASE_FIRMWARE ]
  then
    BASE_FIRMWARE="$2"
    echo BASE_FIRMWARE="$BASE_FIRMWARE" >  $SETTINGS
  fi

  [ -d "$BASE_FIRMWARE" ] || mkdir -p "$BASE_FIRMWARE"  # Allow creation of parents as needed.

  # clone firmware repository
  cd "$BASE_FIRMWARE" || exit
  MESSAGE="Installing Particle firmware from Github..." ; blue_echo
  git clone https://github.com/spark/firmware.git

  if [ "$OS" == "Linux" ]; # Linux installation steps
  then
    cd "$BASE_FIRMWARE" || exit
    # Install dependencies
    MESSAGE="Installing ARM toolchain and dependencies locally in $BINDIR/gcc-arm-embedded/..." ; blue_echo
    # For linux let's avoid the PPA and download instead - See https://community.particle.io/t/how-to-install-the-spark-toolchain-in-ubuntu-14-04/4139/7
    # sudo add-apt-repository -y ppa:team-gcc-arm-embedded/ppa #nrobinson2000: terry.guo ppa has been removed using this one instead
    # sudo apt-get remove -y node modemmanager gcc-arm-none-eabi
    mkdir -p $BINDIR/gcc-arm-embedded && cd "$_" || exit
    wget https://launchpad.net/gcc-arm-embedded/4.8/4.8-2014-q2-update/+download/gcc-arm-none-eabi-4_8-2014q2-20140609-linux.tar.bz2
    tar xjf gcc-arm-none-eabi-*-linux.tar.bz2

    curl -sL https://deb.nodesource.com/setup_5.x | sudo -E bash -
    sudo apt-get install -y nodejs python-software-properties python g++ make build-essential libusb-1.0-0-dev libarchive-zip-perl screen

    # Install dfu-util
    MESSAGE="Installing dfu-util (requires sudo)..." ; blue_echo
    curl -fsSLO "https://sourceforge.net/projects/dfu-util/files/dfu-util-0.9.tar.gz/download"
    tar -xzvf download
    rm download
    cd dfu-util-0.9 || exit
    ./configure
    make
    sudo make install
    cd ..
    rm -rf dfu-util-0.9

    # Install particle-cli
    MESSAGE="Installing particle-cli..." ; blue_echo
    sudo npm install -g node-pre-gyp npm particle-cli

    # Install udev rules file
    MESSAGE="Installing udev rule (requires sudo) ..." ; blue_echo
    # curl -fsSLO https://gist.githubusercontent.com/monkbroc/b283bb4da8c10228a61e/raw/e59c77021b460748a9c80ef6a3d62e17f5947be1/50-particle.rules
    # sudo mv 50-particle.rules /etc/udev/rules.d/50-particle.rules
    curl -fsSLO https://raw.githubusercontent.com/nrobinson2000/po-util/master/60-po-util.rules
    sudo mv 60-po-util.rules /etc/udev/rules.d/60-po-util.rules

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
    brew install gcc-arm-none-eabi-49 dfu-util

    # Install Nodejs version 5.8.0
    MESSAGE="Installing nodejs..." ; blue_echo
    curl -fsSLO https://nodejs.org/dist/v5.8.0/node-v5.8.0.pkg
    sudo installer -pkg node-*.pkg -target /
    rm -rf node-*.pkg

    # Install particle-cli
    MESSAGE="Installing particle-cli..." ; blue_echo
    sudo npm install -g node-pre-gyp npm
    sudo npm install -g particle-cli
  fi # CLOSE: "$OS" == "Darwin"

  cd "$CWD" && MESSAGE="Sucessfully Installed!" ; green_echo && exit
fi

# Create our project files
if [ "$1" == "init" ];
then
  mkdir firmware/
  cp *.cpp firmware/
  cp *.h firmware/
  ls firmware/ | grep -v "particle.include" | cat > firmware/particle.include
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
  stty "$STTYF" "$MODEM" 19200
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
  # curl -fsS https://raw.githubusercontent.com/nrobinson2000/po-util/po-util.com/update | bash ##nrobinson2000: People don't like piping curl to bash
  rm ~/po-util.sh
  curl -fsSLo ~/po-util.sh https://raw.githubusercontent.com/nrobinson2000/po-util/master/po-util.sh
  chmod +x ~/po-util.sh
  exit
fi

# Specific to our photon or electron
if [ "$1" == "photon" ] || [ "$1" == "electron" ];
then
  MESSAGE="$1 selected." ; blue_echo
else
  MESSAGE="Please choose \"photon\" or \"electron\", or chose a proper command." ; red_echo ; exit
fi

cd "$BASE_FIRMWARE"/firmware || exit

if [ "$1" == "photon" ];
then
  git checkout $BRANCH > /dev/null
  DFU_ADDRESS1="2b04:D006"
  DFU_ADDRESS2="0x080A0000"
fi

if [ "$1" == "electron" ];
then
  git checkout $BRANCH > /dev/null
  DFU_ADDRESS1="2b04:d00a"
  DFU_ADDRESS2="0x08080000"
fi

# Flash already compiled binary
if [ "$2" == "dfu" ];
then
  stty "$STTYF" "$MODEM" 19200
  sleep 1
  dfu-util -d "$DFU_ADDRESS1" -a 0 -i 0 -s "$DFU_ADDRESS2":leave -D "$CWD/bin/firmware.bin"
  exit
fi

#Upgrade our firmware on device
if [ "$2" == "upgrade" ] || [ "$2" == "patch" ];
then
  pause "Connect your device and put into DFU mode. Press [ENTER] to continue..."
  cd "$CWD" || exit
  sed '2s/.*/START_DFU_FLASHER_SERIAL_SPEED=19200/' "$BASE_FIRMWARE/"firmware/build/module-defaults.mk > temp.particle
  rm -f "$BASE_FIRMWARE"/firmware/build/module-defaults.mk
  mv temp.particle "$BASE_FIRMWARE"/firmware/build/module-defaults.mk

  cd "$BASE_FIRMWARE/"firmware/modules/"$1"/system-part1 || exit
  make clean all PLATFORM="$1" $GCC_MAKE program-dfu

  cd "$BASE_FIRMWARE/"firmware/modules/"$1"/system-part2 || exit
  make clean all PLATFORM="$1" $GCC_MAKE program-dfu
  cd "$BASE_FIRMWARE/"firmware && git stash || exit
  sleep 1
  sudo dfu-util -d $DFU_ADDRESS1 -a 0 -i 0 -s $DFU_ADDRESS2:leave -D /dev/null
  # TODO: Probably should check the status of the build/flash and  put an appropriate pass/fail message here
  exit
fi

# Clean firmware directory
if [ "$2" == "clean" ];
then
  make clean
  cd "$CWD" || exit
  if [ "$CWD" == "$HOME" ];
  then
  MESSAGE="Please do not use po-util in your home folder." ; blue_echo ; exit
  else
    rm -rf bin
  fi
  exit
fi

# Flash binary over the air
if [ "$2" == "ota" ];
then
  if [ "$3" == "" ];
  then
    MESSAGE="Please specify which device to flash ota." ; red_echo ; exit
  fi
  particle flash "$3" "$CWD/bin/firmware.bin"
  exit
fi

if [ "$2" == "build" ];
then
  cd "$CWD" || exit
  if [ -d firmware ];
  then
    echo > /dev/null
  else
    MESSAGE="Firmware directory not found.
    Please run \"po init\" to setup this repository or cd to a valid directrory" ; red_echo ; exit
  fi
    # echo `echo $PATH | grep $GCC_ARM_VER` && MESSAGE=" Path Set." ; green_echo
    # MESSAGE="Using gcc-arm from: `which arm-none-eabi-gcc`" ; blue_echo
    # MESSAGE="GCC_ARM_PATH=$GCC_ARM_PATH" ; blue_echo #FIXME: Spammy

    make all -s -C "$BASE_FIRMWARE/"firmware APPDIR="$CWD/firmware" TARGET_DIR="$CWD/bin" PLATFORM="$1" $GCC_MAKE  || exit
    MESSAGE="Binary saved to $CWD/bin/firmware.bin" ; green_echo
    exit
fi

if [ "$2" == "flash" ];
then
  cd "$CWD" || exit
  if [ -d firmware ];
  then
    echo > /dev/null
  else
    MESSAGE="Firmware directory not found.
    Please run with \"po init\" to setup this repository or cd to a valid directory" ; red_echo ; exit
  fi
    stty "$STTYF" "$MODEM" 19200
    make all -s -C "$BASE_FIRMWARE/"firmware APPDIR="$CWD/firmware" TARGET_DIR="$CWD/bin" PLATFORM="$1"  $GCC_MAKE  || exit
    dfu-util -d "$DFU_ADDRESS1" -a 0 -i 0 -s "$DFU_ADDRESS2":leave -D "$CWD/bin/firmware.bin"
    exit
fi

# If an improper command is chosen:
MESSAGE="Please choose a command." ; red_echo

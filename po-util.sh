#!/bin/bash
# Particle Offline Utility: A handy script for installing and using the Particle
# Toolchain on Ubuntu-based distros and OSX. This script downloads and installs:
# dfu-util, nodejs, gcc-arm-embedded, particle-cli, and the Particle Firmware
# source code.
# Read more at https://github.com/nrobinson2000/po-util

if [ "$1" == "" ];
then

echo "
po-util Copyright (GPL) 2016  Nathan Robinson
This program comes with ABSOLUTELY NO WARRANTY.
Read more at http://po-util.com

Usage: po DEVICE_TYPE COMMAND DEVICE_NAME
       po DFU_COMMAND
       po install [full_install_path]

Commands:
  install      Download all of the tools needed for development.
               Requires sudo. You can optionally install to an
               alternate location by specifying [full_install_path].
               Ex.:
                   po install ~/particle

               By default Firmware is installed in ~/github.

  build        Compile code in \"firmware\" subdirectory
  flash        Compile code and flash to device using dfu-util
  clean        Refresh all code
  init         Initialize a new po-util project
  patch        Apply system firmware patch to change baud rate
  update       Download latest firmware source code from Particle
  upgrade      Upgrade system firmware on device
  ota          Upload code Over The Air using particle-cli

DFU Commands:
  dfu         Quickly flash pre-compiled code
  dfu-open    Put device into DFU mode
  dfu-close   Get device out of DFU mode
" && exit
fi

blue_echo() {
    echo "$(tput setaf 6)$(tput bold) $MESSAGE $(tput sgr0)"
}

green_echo() {
    echo "$(tput setaf 2)$(tput bold) $MESSAGE $(tput sgr0)"
}

red_echo() {
    echo "$(tput setaf 1)$(tput bold) $MESSAGE $(tput sgr0)"
}

# Holds any alternate paths.
SETTINGS=~/.po
BASE_FIRMWARE=~/github
BRANCH="latest"

# Check if we have a saved settings file.  If not, create it.
if [ ! -f $SETTINGS ]
then
  echo BASE_FIRMWARE="$BASE_FIRMWARE" >> $SETTINGS
  echo BRANCH="latest" >> $SETTINGS
  echo PARTICLE_DEVELOP=1 >> $SETTINGS
fi

# Import our overrides from the ~/.po file.
source $SETTINGS

# See if we are connected via USB or Bluetooth.
if [ "$(uname -s)" == "Darwin" ];
then
modem="$(ls -1 /dev/cu.* | grep -vi bluetooth | tail -1)"
fi

if [ "$(uname -s)" == "Linux" ];
then
modem="$(ls -1 /dev/* | grep "ttyACM" | tail -1)"
fi

CWD="$(pwd)"


if [ "$1" == "install" ];
then
  # Check to see if we need to override the install directory.
  if [ "$2" ] && [ "$2" != $BASE_FIRMWARE ]
  then
    # TODO: Validate this path a bit more.
    BASE_FIRMWARE="$2"
    echo BASE_FIRMWARE="$BASE_FIRMWARE" >  $SETTINGS
  fi

  [ -d "$BASE_FIRMWARE" ] || mkdir -p "$BASE_FIRMWARE"  # Allow creation of parents as needed.

  # clone firmware repository
  cd "$BASE_FIRMWARE" || exit
  MESSAGE="Installing Particle firmware from Github..." ; blue_echo
  git clone https://github.com/spark/firmware.git

  if [ "$(uname -s)" == "Linux" ];
  then
    cd "$BASE_FIRMWARE" || exit
    # Install dependencies
    MESSAGE="Installing dependencies..." ; blue_echo
    echo
    MESSAGE="Installing ARM toolchain and dependencies (requires sudo)..." ; blue_echo
    sudo add-apt-repository -y ppa:team-gcc-arm-embedded/ppa #nrobinson2000: terry.guo ppa is down
    curl -sL https://deb.nodesource.com/setup_5.x | sudo -E bash -
    sudo apt-get remove -y node modemmanager gcc-arm-none-eabi

    sudo apt-get install -y nodejs python-software-properties python g++ make build-essential libusb-1.0-0-dev gcc-arm-embedded libarchive-zip-perl
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

    MESSAGE="Installing particle-cli..." ; blue_echo
    # install particle-cli
    sudo npm install -g node-pre-gyp npm particle-cli

    # create udev rules file - MOWGLI: This is not a generic rules file. Looks like a Photon?  Perhaps there should be a check before installing.
    MESSAGE="Installing udev rule (requires sudo) ..." ; blue_echo
    curl -fsSLO https://gist.githubusercontent.com/monkbroc/b283bb4da8c10228a61e/raw/e59c77021b460748a9c80ef6a3d62e17f5947be1/50-particle.rules
    sudo mv 50-particle.rules /etc/udev/rules.d/50-particle.rules
  fi # CLOSE: "$(uname -s)" == "Linux"

  if [ "$(uname -s)" == "Darwin" ];
  then
    MESSAGE="Installing Brew..." ; blue_echo
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    brew tap PX4/homebrew-px4
    brew update
    MESSAGE="Installing ARM toolchain..." ; blue_echo
    brew install gcc-arm-none-eabi-49 dfu-util
    curl -fsSLO https://nodejs.org/dist/v5.8.0/node-v5.8.0.pkg
    MESSAGE="Installing nodejs..." ; blue_echo
    sudo installer -pkg node-*.pkg -target /
    rm node-*.pkg
    MESSAGE="Installing particle-cli..." ; blue_echo
    sudo npm install -g node-pre-gyp npm
    sudo npm install -g particle-cli
  fi # CLOSE: "$(uname -s)" == "Linux"
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

# dfu upload binary
if [ "$1" == "dfu" ];
then
  if [ "$(uname -s)" == "Darwin" ];
  then
    stty -f "$modem" 19200
    sleep 1
    dfu-util -d 2b04:d006 -a 0 -i 0 -s 0x080A0000:leave -D "$CWD/bin/firmware.bin"
    exit
  else
    stty -F "$modem" 19200
    sleep 1
    dfu-util -d 2b04:d006 -a 0 -i 0 -s 0x080A0000:leave -D "$CWD/bin/firmware.bin"
    exit
  fi
fi

# dfu connect (Wired)
if [ "$1" == "dfu-open" ];
then
  if [ "$(uname -s)" == "Darwin" ];
  then
    stty -f "$modem" 19200
  else
    stty -F /dev/ttyACM0 19200
  fi
  exit
fi

# Close our connection (wired)
if [ "$1" == "dfu-close" ];
then
  dfu-util -d 2b04:d006 -a 0 -i 0 -s 0x080A0000:leave -D /dev/null
  exit
fi

#Update po-util
if [ "$1" == "update" ];
then
  MESSAGE="Updating firmware..." ; blue_echo
  cd "$BASE_FIRMWARE"/firmware
  git checkout $BRANCH
  git pull
  MESSAGE="Updating particle-cli..." ; blue_echo
  sudo npm update -g particle-cli
  exit
fi

# Specific to our photon or electron
if [ "$1" == "photon" ] || [ "$1" == "electron" ];
then
  MESSAGE="$1 selected." ; blue_echo
else
  MESSAGE="Please choose \"photon\" or \"electron\"" ; red_echo
fi

cd "$BASE_FIRMWARE"/firmware || exit

if [ "$1" == "photon" ];
then
  git checkout $BRANCH
  DFU_ADDRESS1="2b04:d006"
  DFU_ADDRESS2="0x080A0000"
fi

if [ "$1" == "electron" ];
then
  git checkout $BRANCH
  DFU_ADDRESS1="2b04:d00a"
  DFU_ADDRESS2="0x08080000"
fi

#Upgrade our firmware on device
if [ "$2" == "upgrade" ] || [ "$2" == "patch" ];
then
  cd "$CWD"
  sed '2s/.*/START_DFU_FLASHER_SERIAL_SPEED=19200/' "$BASE_FIRMWARE/"firmware/build/module-defaults.mk > temp
  rm -f "$BASE_FIRMWARE"/firmware/build/module-defaults.mk
  mv temp "$BASE_FIRMWARE"/firmware/build/module-defaults.mk

  cd "$BASE_FIRMWARE/"firmware/modules/"$1"/system-part1
  make clean all PLATFORM="$1" program-dfu

  cd "$BASE_FIRMWARE/"firmware/modules/"$1"/system-part2
  make clean all PLATFORM="$1" program-dfu
  cd "$BASE_FIRMWARE/"firmware && git stash
  sleep 1
  dfu-util -d 2b04:d006 -a 0 -i 0 -s 0x080A0000:leave -D /dev/null
  exit
fi


if [ "$2" == "clean" ];
then
  make clean
  cd "$CWD"
  rm -rf bin
  exit
fi

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
  cd "$CWD"
  if [ -d firmware ];
  then
    MESSAGE="Found firmware directrory" ; green_echo
  else
    MESSAGE="Firmware directory not found.
Please run \"po init\" to setup this repository or cd to a valid directrory" ; red_echo ; exit
  fi
echo
make all -s -C "$BASE_FIRMWARE/"firmware APPDIR="$CWD/firmware" TARGET_DIR="$CWD/bin" PLATFORM="$1" || exit
MESSAGE="Binary saved to $CWD/bin/firmware.bin" ; green_echo
exit
fi

if [ "$2" == "flash" ];
then
  cd "$CWD"
  if [ -d firmware ];
  then
    MESSAGE="Found firmware directory" ; green_echo
  else
    MESSAGE="Firmware directory not found.
    Please run with \"po init\" to setup this repository or cd to a valid directory" ; red_echo ; exit
  fi

<<<<<<< HEAD
  if [ "$(uname -s)" == "Darwin" ]; # No if needed for this
  then
    stty -f "$modem" 19200
    exit
  else  # MOWGLI: Redundant, Same code either way.
   stty -F "$modem" 19200
   exit
 fi

 make all -s -C "$BASE_FIRMWARE/"firmware APPDIR="$CWD/firmware" TARGET_DIR="$CWD/bin" PLATFORM="$1" || exit
 dfu-util -d 2b04:d006 -a 0 -i 0 -s 0x080A0000:leave -D "$CWD/bin/firmware.bin"

=======
if [ "$(uname -s)" == "Darwin" ];
  then
    stty -f "$modem" 19200
  else
    stty -F "$modem" 19200
  fi
    make all -s -C "$BASE_FIRMWARE/"firmware APPDIR="$CWD/firmware" TARGET_DIR="$CWD/bin" PLATFORM="$1" || exit
    dfu-util -d "$DFU_ADDRESS1" -a 0 -i 0 -s "$DFU_ADDRESS2":leave -D "$CWD/bin/firmware.bin"
    exit
>>>>>>> upstream/master
fi

MESSAGE="Please choose a command." ; red_echo

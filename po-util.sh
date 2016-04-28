#!/bin/bash
# Particle Offline Utility

if [ "$1" == "help" ];
then
echo "po-util 1.3 Copyright (C) 2016  Nathan Robinson
This program comes with ABSOLUTELY NO WARRANTY.

== Usage ==

Put your device into dfu mode and install the firmware patch with:
  \"po DEVICE patch\"

-- replace DEVICE with either \"photon\" or \"electron\" --

To format your working directory into a project folder, run:
  \"po init\"

To compile and test your firmware, run:
  \"po DEVICE build\"

To compile and automagically upload your firmware with dfu-util, run:
  \"po DEVICE flash\"

To reset the build directory, run:
  \"po DEVICE clean\"

To download new firmware from Particle, run:
  \"po DEVICE update\"

To upgrade firmware on your device to the latest Particle release, run:
  \"po DEVICE upgrade\"

To instantly flash code that you just compiled with \"build\", run:
  \"po dfu\"

To put your device into DFU mode, run:
  \"po dfu-open\"

To make your device exit DFU mode, run:
  \"po dfu-close\"

If you want to upload code compiled with \"build\" using Over The Air, run:
  \"po DEVICE ota DEVICE_NAME\"

 -- replace DEVICE_NAME with the name of your device --
 " | less
  exit
fi

if [ "$(uname -s)" == "Darwin" ];
then
modem="$(ls -1 /dev/cu.* | grep -vi bluetooth | tail -1)"
fi

CWD=$(pwd)

if [ "$1" == "install" ];
then
mkdir ~/github
cd ~/github
git clone https://github.com/spark/firmware.git
if [ "$(uname -s)" == "Linux" ];
then
cd ~/github || exit
# Install dependencies
echo "installing dependencies..."
sudo apt-add-repository -y ppa:terry.guo/gcc-arm-embedded
curl -sL https://deb.nodesource.com/setup_5.x | sudo -E bash -
sudo apt-get remove -y node modemmanager gcc-arm-none-eabi

sudo apt-get install -y nodejs python-software-properties python g++ make build-essential libusb-1.0-0-dev gcc-arm-none-eabi libarchive-zip-perl
# Install dfu-util
curl -fsSLO "https://sourceforge.net/projects/dfu-util/files/dfu-util-0.9.tar.gz/download"
tar -xzvf download
rm download
cd dfu-util-0.9 || exit
./configure
make
sudo make install
cd ..
rm -rf dfu-util-0.9

# clone firmware repository
cd ~/github || exit
git clone https://github.com/spark/firmware.git
# install particle-cli
sudo npm install -g node-pre-gyp npm
sudo npm install -g particle-cli
# create udev rules file
curl -fsSLO https://gist.githubusercontent.com/monkbroc/b283bb4da8c10228a61e/raw/e59c77021b460748a9c80ef6a3d62e17f5947be1/50-particle.rules
sudo mv 50-particle.rules /etc/udev/rules.d/50-particle.rules
fi
if [ "$(uname -s)" == "Darwin" ];
then
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew tap PX4/homebrew-px4
brew update
brew install gcc-arm-none-eabi-49 dfu-util
curl -fsSLO https://nodejs.org/dist/v5.8.0/node-v5.8.0.pkg
sudo installer -pkg node-v5.8.0.pkg -target /
rm node-v5.8.0.pkg
sudo npm install -g node-pre-gyp npm
sudo npm install -g particle-cli
fi
cd "$CWD" && echo "Sucessfully Installed!" && exit
fi


if [ "$1" == "init" ];
then
mkdir firmware/
cp *.cpp firmware/
cp *.h firmware/
ls firmware/ | grep -v "particle.include" | cat > firmware/particle.include
echo "Copied c++ files into firmware directory.  Setup complete."
exit
fi

if [ -d "firmware" ];
then echo
else echo "Please run with \"init\" to setup this repository.
For details type \"po help\"" && exit
fi

if [ "$1" == "dfu" ];
then
if [ "$(uname -s)" == "Darwin" ];
then
stty -f "$modem" 19200
sleep 1
dfu-util -d 2b04:d006 -a 0 -i 0 -s 0x080A0000:leave -D "$CWD/bin/firmware.bin"
exit
else
stty -F /dev/ttyACM0 19200
sleep 1
dfu-util -d 2b04:d006 -a 0 -i 0 -s 0x080A0000:leave -D "$CWD/bin/firmware.bin"
exit
fi
fi

if [ "$1" == "dfu-open" ];
then
if [ "$(uname -s)" == "Darwin" ];
then
stty -f "$modem" 19200
exit
else
stty -F /dev/ttyACM0 19200
exit
fi
fi

if [ "$1" == "dfu-close" ];
then
dfu-util -d 2b04:d006 -a 0 -i 0 -s 0x080A0000:leave -D /dev/null
exit
fi

if [ "$1" == "photon" ] || [ "$1" == "electron" ];
then echo "$1 selected."
else  echo "Please select photon or electron.  Try \"po-util help\" for help." && exit
fi


cd ~/github/firmware || exit

if [ "$1" == "photon" ];
then git checkout release/v0.5.0
fi

if [ "$1" == "electron" ];
then git checkout release/v0.5.0
fi

if [ "$2" == "upgrade" ];
then
cd "$CWD"
sed '2s/.*/START_DFU_FLASHER_SERIAL_SPEED=19200/' ~/github/firmware/build/module-defaults.mk > temp
rm -f ~/github/firmware/build/module-defaults.mk
mv temp ~/github/firmware/build/module-defaults.mk

cd ~/github/firmware/modules/"$1"/system-part1
make clean all PLATFORM="$1" program-dfu

cd ~/github/firmware/modules/"$1"/system-part2
make clean all PLATFORM="$1" program-dfu
sleep 1
dfu-util -d 2b04:d006 -a 0 -i 0 -s 0x080A0000:leave -D /dev/null
exit
fi


if [ "$2" == "update" ] || [ "$2" == "patch" ];
then git pull
fi

if [ "$2" == "clean" ];
then make clean
fi

if [ "$2" == "ota" ];
then
particle flash "$3" "$CWD/bin/firmware.bin"
fi

if [ "$2" == "build" ];
then make all -s -C ~/github/firmware APPDIR="$CWD/firmware" TARGET_DIR="$CWD/bin" PLATFORM="$1"
echo "Binary saved to $CWD/bin/firmware.bin"
fi

if [ "$2" == "flash" ];
then
if [ "$(uname -s)" == "Darwin" ];
then
stty -f "$modem" 19200
make all -s -C ~/github/firmware APPDIR="$CWD/firmware" TARGET_DIR="$CWD/bin" PLATFORM="$1" || exit
dfu-util -d 2b04:d006 -a 0 -i 0 -s 0x080A0000:leave -D "$CWD/bin/firmware.bin"

else
stty -F /dev/ttyACM0 19200
make all -s -C ~/github/firmware APPDIR="$CWD/firmware" TARGET_DIR="$CWD/bin" PLATFORM="$1" || exit
dfu-util -d 2b04:d006 -a 0 -i 0 -s 0x080A0000:leave -D "$CWD/bin/firmware.bin"

fi
fi

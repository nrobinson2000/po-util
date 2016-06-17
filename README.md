[![Github All Releases](https://img.shields.io/github/downloads/nrobinson2000/po-util/total.svg?maxAge=2592000)](https://nrobinson2000.github.io/po-util/)
[![Slack Status](https://nrobinson2000.herokuapp.com/badge.svg)](https://nrobinson2000.herokuapp.com/)
[![Donate Bitcoin](https://img.shields.io/badge/donate-bitcoin-orange.svg)](https://nrobinson2000.github.io/donate-bitcoin)
[![GitHub issues](https://img.shields.io/github/issues/nrobinson2000/po-util.svg)](https://github.com/nrobinson2000/po-util/issues)
[![GitHub stars](https://img.shields.io/github/stars/nrobinson2000/po-util.svg)](https://github.com/nrobinson2000/po-util/stargazers)
[![Build Status](https://travis-ci.org/nrobinson2000/po-util.svg?branch=master)](https://travis-ci.org/nrobinson2000/po-util) [![Circle CI](https://circleci.com/gh/nrobinson2000/po-util.svg?style=svg)](https://circleci.com/gh/nrobinson2000/po-util)

<img src="http://po-util.com/logos/po-util-updated.svg" width="400px">
# Particle Offline Utility:

A handy script for installing and using the Particle Toolchain on Ubuntu-based distros and OSX.
This script downloads and installs: [dfu-util](http://dfu-util.sourceforge.net/), [nodejs](https://nodejs.org/en/), [gcc-arm-embedded](https://launchpad.net/~terry.guo/+archive/ubuntu/gcc-arm-embedded), [particle-cli](https://github.com/spark/particle-cli), and the [Particle Firmware source code](https://github.com/spark/firmware).

<img src="https://raw.githubusercontent.com/nrobinson2000/po-util/po-util.com/screenshots/1.png">

# Manual Install / Update
You can get a copy of po-util at [the Github repository](http://github.com/nrobinson2000).  You can download it manually as a zip, unzip it into a folder, and run: 
```
./po-util install
```

or if updating:
```
./po-util update
```

Alternatively, you can checkout the utility with github:
```
git clone https://github.com/nrobinson2000/po-util
cd po-util
./po-util update
```

For either method, you will probably want to add po-util to your path to run it from anywhere.  To do this you can add an entry to you PATH environment variable.  Typically you would add this to your .bashrc file found in your home directory.  then you would add the following line at the bottom of your ` ~/.bashrc` file:
```
PATH=~/place_where_po-util-lives/:$PATH
```


# Quick Install / Update
```
curl po-util.com/download | bash
```
Copy and paste this into your terminal.  

Note: We download  everything from well known locations and Github.  While we believe this is a reasonable method as a quick start, it's always a good idea to know what is going on under the hood.  

# Info
```
po-util Copyright (GPL) 2016  Nathan Robinson
This program comes with ABSOLUTELY NO WARRANTY.
Read more at http://bit.ly/po-util

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
```

# Tips

The three most useful commands are `build`, `flash` and `clean`. Build compiles code in a `"firmware"` subdirectory and saves it as a `.bin` file in a `"bin"` subdirectory. Flash does the same, but uploads the compiled `.bin` to your device using dfu-util. Clean refreshes the Particle firmware source code.

A po-util project must be arranged like so:

```
po-util_project/
  └ firmware/
    └ main.cpp
    └ lib.cpp
    └ lib.h
```

Since po-util compiles `.cpp` and not `.ino` files, `#include "application.h"` must be present in your `main.cpp` file.

A blank `main.cpp` would look like:

```
#include "application.h"

void setup()
{

}

void loop()
{

}
```
One of the features of po-util is that it changes the baud rate to trigger dfu mode on Particle devices from `14400` to `19200`. **The reason for this is because Linux can not easily use 14400 as a baud rate.** To enable this feature, connect your device and put it into DFU mode, and type:

```
po DEVICE_TYPE patch

# Replace DEVICE_TYPE with either "photon" or "electron"
```

Your computer will then recompile both parts of the Particle system firmware and flash each part to your device using dfu-util.


# Why I created this script

I created this script because Particle does not currently have a script for easily installing the Particle Toolchain and depedencies on Linux and OSX. I created this script in order to help out other Particle users and to improve my bash scripting skills. It would be my dream come true if Particle added this script to its resources or gave it a shout out in its documentation. If that happened, I would feel very proud of myself for making a meaningful contribution.

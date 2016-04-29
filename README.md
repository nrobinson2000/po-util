[![Build Status](https://travis-ci.org/nrobinson2000/po-util.svg?branch=master)](https://travis-ci.org/nrobinson2000/po-util) [![Circle CI](https://circleci.com/gh/nrobinson2000/po-util.svg?style=svg)](https://circleci.com/gh/nrobinson2000/po-util)
# Particle Offline Utility:

A handy script for installing and using the Particle Toolchain on Ubuntu-based distros and OSX.
This script installs and downloads [dfu-util](http://dfu-util.sourceforge.net/), [nodejs](https://nodejs.org/en/), [gcc-arm-embedded](https://launchpad.net/~terry.guo/+archive/ubuntu/gcc-arm-embedded), [particle-cli](https://github.com/spark/particle-cli), and the [Particle Firmware source code](https://github.com/spark/firmware).

# Quick Install
```
curl -fsSL https://git.io/vwRRf | bash
```
Copy and paste this into your terminal.

# Info:
```
po-util 1.5 Copyright (GPL) 2016  Nathan Robinson
This program comes with ABSOLUTELY NO WARRANTY.
Read more at https://github.com/nrobinson2000/po-util

Usage: po DEVICE_TYPE COMMAND DEVICE_NAME
       po DFU_COMMAND

Commands:
  build        Compile code in \"firmware\" subdirectory
  flash        Compile code and flash to device using dfu-util
  clean        Refresh all code
  init         Initialize a new po-util project
  patch        Apply system firmware patch to change baud rate
  update       Download new firmware from Particle
  upgrade      Upgrade system firmware on device
  ota          Upload code Over The Air using particle-cli

DFU Commands:
  dfu         Quickly flash pre-compiled code
  dfu-open    Put device into DFU mode
  dfu-close   Get device out of DFU mode
```

<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/4/46/Bitcoin.svg/500px-Bitcoin.svg.png" height="20px" width="20px">  [Donate Bitcoin](https://onename.com/nrobinson2000)
---

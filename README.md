[![Build Status](https://travis-ci.org/nrobinson2000/po-util.svg?branch=master)](https://travis-ci.org/nrobinson2000/po-util) [![Circle CI](https://circleci.com/gh/nrobinson2000/po-util.svg?style=svg)](https://circleci.com/gh/nrobinson2000/po-util)
# Particle Offline Utility:
---
A handy script for installing and using the Particle Toolchain on Ubuntu-based distros and OSX.
This script installs and downloads [dfu-util](http://dfu-util.sourceforge.net/), [nodejs](https://nodejs.org/en/), [gcc-arm-embedded](https://launchpad.net/~terry.guo/+archive/ubuntu/gcc-arm-embedded), [particle-cli](https://github.com/spark/particle-cli), and the [Particle Firmware source code](https://github.com/spark/firmware).

# Quick Install
---

```
curl -fsSL https://git.io/vwRRf | bash
```
Copy and paste this into your terminal.

# Usage:
---

Put your device into dfu mode and install the firmware patch with:
```
$ po DEVICE patch
```
*replace* ***DEVICE*** *with either* ***photon*** *or* ***electron***

To format your working directory into a project folder, run:
```
$ po init
```
To compile and test your firmware, run:
```
$ po DEVICE build
```
To compile and automagically upload your firmware with dfu-util, run:
```
$ po DEVICE flash
```
To reset the build directory, run:
```
$ po DEVICE clean
```
To download new firmware from Particle, run:
```
$ po DEVICE update
```
To upgrade the system firmware on your device to the latest Particle release and change the [dfu-trigger speed](https://community.particle.io/t/local-compile-electron-workflow/21694/13?u=nrobinson2000), run:
```
$ po DEVICE upgrade
```
To instantly flash code that you just compiled with `build`, run:
```
$ po dfu
```
To put your device into DFU mode, run:
```
$ po dfu-open
```
To make your device exit DFU mode, run:
```
$ po dfu-close
```
If you want to upload code that you just compiled with `build` **O**ver **T**he **A**ir, run:
```
$ po DEVICE ota DEVICE_NAME
```
*replace* ***DEVICE_NAME*** *with the name of your device*


<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/4/46/Bitcoin.svg/500px-Bitcoin.svg.png" height="20px" width="20px">  [Donate Bitcoin](https://onename.com/nrobinson2000)
---

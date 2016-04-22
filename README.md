# po-util
Particle Offline Utility: A handy script for installing and using the Particle Toolchain on Ubuntu-based Distros and OSX

# Quick Install
```
curl -fsSL https://raw.githubusercontent.com/nrobinson2000/po-util/master/download-po-util.sh | bash
```
Copy and paste this into your terminal.

# Usage:

To format your working directory into a project folder run:
```
$ po init
```
Next, put your device into dfu mode and install the firmware patch with:
```
$ po DEVICE patch
```
*replace* ***DEVICE*** *with either* ***photon*** *or* ***electron***

To compile and test your firmware run:
```
$ po DEVICE build
```

To compile and automagically upload your firmware with dfu-util run:
```
$ po DEVICE flash
```

[Discuss on Particle Forums](http://community.particle.io/t/toolchain-installer-for-linux-ubuntu/21015)

<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/4/46/Bitcoin.svg/500px-Bitcoin.svg.png" height="16px" width="16px">  [Donate Bitcoin](https://onename.com/nrobinson2000)

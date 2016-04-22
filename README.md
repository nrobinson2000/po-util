# po-util
Particle Offline Utility: A handy script for installing and using the Particle Toolchain on Ubuntu-based Distros and OSX

# Quick Install
```
curl -s http://bit.ly/1ShvhdI | sh
```


# Notes:
To fully make use of this script you must first download and save it to your home folder.
Make the script executable and create an alias for it in your .bashrc.
```
$ chmod +x po-util.sh
$ echo 'alias po="~/po-util.sh"' >> .bashrc
```

You next have to install the Particle toolchain and dependecies.  All of this can be taken care with:
```
$ po install
```
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

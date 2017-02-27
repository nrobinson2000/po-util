```
                                            __      __  __
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
```

This directory is set up as a po-util project.

Po-util makes it easy to develop firmware for Particle devices.

Po-util supports the Photon, P1, and Electron devices.

Here is the directory structure of a full po-util project:

```
po-util_project/
  ├ firmware/
  | ├ main.cpp
  | ├ lib1.cpp
  | ├ lib1.h
  | └ ...
  ├ bin/
  | ├ firmware.bin
  | └ ...
  ├ devices.txt
  ├ libs.txt
  ├ .atom-build.yml
  └ README.md
```

The C++ files go in the `firmware/` directory, and the compiled binary will appear in the `bin/` directory, named `firmware.bin`.

To compile code, run `po DEVICE build`, substituting `DEVICE` for `photon`, `P1`, or `electron`.

To compile and flash code, run `po DEVICE flash`. Code is compiled and then flashed to your device over USB using dfu-util.

To clean the project, run `po DEVICE clean`.

To upload a pre-compiled project over USB, run `po DEVICE dfu`.

To put your device into DFU mode, run `po dfu-open`.

To get your device out of DFU mode, run `po dfu-close`.

To upload precompiled code over the air using particle-cli, run `po DEVICE ota DEVICE_NAME`, where `DEVICE_NAME` is the name of your device in the Particle cloud. Note: You must be logged into particle-cli to use this feature. You can log into particle-cli with `particle cloud login`.

You can also flash code to multiple devices at once by passing the `-m` or `--multi` argument to `ota`. This would look like `po DEVICE ota -m`. This relies on a file called `devices.txt` that you must create in your po-util project directory.

`devices.txt` must contain the names of your devices on individual lines.

Example:

```
product1
product2
product3
```

NOTE: This is different from the product firmware update feature in the Particle Console because it updates the firmware of devices one at a time and only if the devices are online when the command is run.

For more help, run the `po` command with no arguments, or visit <https://nrobinson2000.github.io/po-util/>

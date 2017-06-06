# This directory is set up as a [po-util](https://po-util.com) project

Po-util makes it easy to locally develop firmware for Particle devices.

Po-util supports the Particle Photon, P1, Electron, Core, Raspberry Pi, and Redbear Duo

# Project structure
The C++ files go in the `firmware/` directory, and the compiled binary will appear in the `bin/` directory, named `firmware.bin`.

To compile code, run `po DEVICE_TYPE build`, substituting `DEVICE_TYPE` with `photon`, `P1`, `electron`, `core`, `pi`, or `duo`.

To compile and flash code, run `po DEVICE_TYPE flash`. Code is compiled and then flashed to your device over USB using dfu-util.

To build your firmware without flashing, run `po DEVICE_TYPE build`.

To clean the project, run `po DEVICE_TYPE clean`.

To upload a pre-compiled project over USB, run `po DEVICE_TYPE dfu`.

To put your device into DFU mode, run `po dfu-open`.

To get your device out of DFU mode, run `po dfu-close`.

To upload precompiled code over the air using particle-cli, run `po DEVICE ota DEVICE_NAME`, where `DEVICE_NAME` is the name of your device in the Particle cloud. Note: You must be logged into particle-cli to use this feature. You can log into particle-cli with `particle cloud login`.

For more help, run `man po`, or visit <https://docs.po-util.com/>

Feel free to replace this README with content more suitable to your project.

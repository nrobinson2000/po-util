[![Built with po-util](https://rawgit.com/nrobinson2000/po-util/master/images/built-with-po-util.svg)](https://po-util.com)

# This repository is a [po-util](https://po-util.com) project

Po-util makes it easy to locally develop firmware for Particle devices, and supports the Particle Photon, P1, Electron, Core, Raspberry Pi, and Redbear Duo.

Your project’s C++ files go in the `firmware/` directory, and the binary will appear in the `bin/` directory.

To compile code, run `po DEVICE_TYPE build`, substituting `DEVICE_TYPE` with `photon`, `P1`, `electron`, `core`, `pi`, or `duo`.

To compile and flash code, run `po DEVICE_TYPE flash`. Code is compiled and then flashed to your device over USB.

To clean the project, run `po DEVICE_TYPE clean`.

To flash a project over USB without rebuilding, run `po DEVICE_TYPE dfu`.

To upload a compiled project over the air run `po DEVICE ota DEVICE_NAME`, where `DEVICE_NAME` is the name of your device in the Particle cloud. **Note: You must be logged into particle-cli to use this feature. You can log into particle-cli with:**

```
particle login
```

For more help, run `man po`, or visit <https://docs.po-util.com/>

*By the way, po-util has tab completion. Try pressing [TAB] at any time to have arguments completed.*

Feel free to edit this README.md to make it more suitable for your project. **(I do ask that you please include the badge at the top though.)**

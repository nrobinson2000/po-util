# Contributing to po-util:

First off, thank you for considering contributing to po-util. It's people like you that make po-util such a great tool.

Whenever possible, please follow these guidelines for contributions:

- Keep each pull request small and focused on a single feature or bug fix.
- Familiarize yourself with the code base, and follow the formatting principles adhered to in the surrounding code.
- Wherever possible, test your contributions.
- If the changes have an impact on developers, then those changes should be described in the documentation.
- If you are adding a new feature please make an effort to add it to both the Linux and macOS versions of po-util.

# Introduction to the po-util code base:

>**You are currently viewing the Linux version of po-util.**
>
>**The macOS version can be found over at [nrobinson2000/homebrew-po](https://github.com/nrobinson2000/homebrew-po).**

--------

[`po-util.sh`](https://github.com/nrobinson2000/po-util/blob/master/po-util.sh) - The main script for the `po` command

[`completion/po`](https://github.com/nrobinson2000/homebrew-po/blob/master/completion/po) - The bash completion script that provides tab completion for `po`

[`man/po.1`](https://github.com/nrobinson2000/homebrew-po/blob/master/man/po.1) - The man page for `po`

# Conventions:

- Please use [Shellcheck](https://www.shellcheck.net/) to test your contributions.
- All variables must be in `UPPER_CAMEL_CASE`
- Your contributions must be compatible with older versions of bash. On macOS Sierra for example, bash `3.2.57(1)-release` is installed by default and your contributions must operate correctly.

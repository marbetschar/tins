# Boxes

Use lightweight containers just like any virtual machine.

<img src="data/screenshots/App.png?raw=true" width="448" align="right" />

## Usage

In case you want to learn more about LXD, there is a pretty good documenation on [linuxcontainers.org](https://linuxcontainers.org/lxd).

Even though the usage of Boxes should be pretty self explanatory, feel free to open an issue if you have any questions.

## Installation

Boxes will be available in elementary AppCenter soon!

**PLEASE NOTE:** Until [issue #7](https://github.com/marbetschar/boxes/issues/7) is fixed, Boxes expects LXD to be installed via apt and initialized on the host system.
To do so, please execute the following commands in your terminal:

```
sudo apt install lxd
sudo lxd init            # use default values for everything
```

## Building

You'll need the following dependencies:
* glib-2.0
* json-glib-1.0
* gtk+-3.0
* meson
* valac

Simply run

```
./install.sh
```

The install script configures the build environment, compiles the app and installs it.
The app is started automatically after successful installation.


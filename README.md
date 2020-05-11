# Tins

Containers just like Virtual Machines

> **Tins:** a tinplate container - often used to package breath mints.
> In some cultures, these boxes are referred to as "tins".

<img src="data/screenshots/App.png?raw=true" width="448" align="right" />

## Usage

Even though the usage of Tins should be straight forward, feel free to open an issue if you have any questions.

In case you want to learn more about LXD, there is a pretty good documentation on [linuxcontainers.org](https://linuxcontainers.org/lxd).

## Installation

Tins will be available in elementary AppCenter soon!

**PLEASE NOTE:** Until [issue #7](https://github.com/marbetschar/tins/issues/7) is fixed, Tins expects LXD to be installed via apt and initialized on the host system.
To do so, please execute the following commands in your terminal:

```
sudo apt install lxd

# use default values everywhere:
sudo lxd init
```

## Building

You'll need the following dependencies:
* glib-2.0
* json-glib-1.0
* gtk+-3.0
* granite
* meson
* valac

Simply run

```
./install.sh
```

The install script configures the build environment, compiles the app and installs it.
The app is started automatically after successful installation.


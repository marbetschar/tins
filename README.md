# <img src="data/icons/128/com.github.marbetschar.tins.svg?raw=true" width="42" height="42" align="left" /> Tins

Containers just like Virtual Machines

> **Tins:** tinplate containers - often used to package breath mints.
> In some cultures, these boxes are referred to as "tins".

<img src="data/screenshots/App.png?raw=true" width="448" align="right" />

Tins uses LXD to easily create and manage Containers providing a Desktop Environment (Graphical User Interface).
The usability is similar to VirtualBox, but without the downsides of traditional Virtual Machines:
Unprivileged, lightweight Linux Containers provide good isolation along with superior performance.

## Usage

Even though the usage of Tins should be straight forward, feel free to open an issue if you have any questions.

In case you want to learn more about LXD, there is a pretty good documentation on [linuxcontainers.org](https://linuxcontainers.org/lxd).

## Installation

Tins will be available in elementary AppCenter soon!

**PLEASE NOTE:** Until [issue #7](https://github.com/marbetschar/tins/issues/7) is fixed, Tins expects LXD to be initialized on the host system.
To do so, please execute the following commands in your terminal:

```
# use default values everywhere:
lxd init

# allow lxd to remap your user id into a container:
echo "root:$UID:1" | sudo tee -a /etc/subuid /etc/subgid
```

## Building

You'll need the following dependencies:
* glib-2.0
* json-glib-1.0
* gtk+-3.0
* granite
* posix
* meson
* valac

Simply run

```
./install.sh
```

The install script configures the build environment, compiles the app and installs it.
The app is started automatically after successful installation.


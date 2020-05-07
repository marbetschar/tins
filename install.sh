#!/bin/bash
set -e

meson build --prefix=/usr
cd build
ninja

sudo ninja install
sudo chown -R $USER:$USER .

export G_MESSAGES_DEBUG=all
com.github.marbetschar.tins


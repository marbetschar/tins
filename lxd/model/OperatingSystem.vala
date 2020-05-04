/*
* Copyright (c) 2020 - Today Marco Betschart (https://marco.betschart.name)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Marco Betschart <boxes@marco.betschart.name>
*/

namespace LXD {

    public const OperatingSystem[] ALL_KNOWN_OPERATING_SYSTEMS = {
        OperatingSystem.FEDORA,
        OperatingSystem.UBUNTU
    };

    public enum OperatingSystem {
        ALPINE,
        ALT,
        APERTIS,
        ARCHLINUX,
        CENTOS,
        DEBIAN,
        DEVUAN,
        FEDORA,
        FUNTOO,
        GENTOO,
        KALI,
        MINT,
        OPENSUSE,
        OPENWRT,
        ORACLE,
        PLAMO,
        PLD,
        SABAYON,
        UBUNTU,
        VOIDLINUX,
        UNKNOWN;

        public static OperatingSystem from_string (string str) {
            switch (str) {
                case "alpine":
                    return ALPINE;
                case "alt":
                    return ALT;
                case "apertis":
                    return APERTIS;
                case "archlinux":
                    return ARCHLINUX;
                case "centos":
                    return CENTOS;
                case "debian":
                    return DEBIAN;
                case "devuan":
                    return DEVUAN;
                case "fedora":
                    return FEDORA;
                case "funtoo":
                    return FUNTOO;
                case "gentoo":
                    return GENTOO;
                case "kali":
                    return KALI;
                case "mint":
                    return MINT;
                case "opensuse":
                    return OPENSUSE;
                case "openwrt":
                    return OPENWRT;
                case "oracle":
                    return ORACLE;
                case "plamo":
                    return PLAMO;
                case "pld":
                    return PLD;
                case "sabayon":
                    return SABAYON;
                case "ubuntu":
                    return UBUNTU;
                case "voidlinux":
                    return VOIDLINUX;
                default:
                    return UNKNOWN;
            }
        }

        public string to_string () {
            switch (this) {
                case ALPINE:
                    return "alpine";
                case ALT:
                    return "alt";
                case APERTIS:
                    return "apertis";
                case ARCHLINUX:
                    return "archlinux";
                case CENTOS:
                    return "centos";
                case DEBIAN:
                    return "debian";
                case DEVUAN:
                    return "devuan";
                case FEDORA:
                    return "fedora";
                case FUNTOO:
                    return "funtoo";
                case GENTOO:
                    return "gentoo";
                case KALI:
                    return "kali";
                case MINT:
                    return "mint";
                case OPENSUSE:
                    return "opensuse";
                case OPENWRT:
                    return "openwrt";
                case ORACLE:
                    return "oracle";
                case PLAMO:
                    return "plamo";
                case PLD:
                    return "pld";
                case SABAYON:
                    return "sabayon";
                case UBUNTU:
                    return "ubuntu";
                case VOIDLINUX:
                    return "voidlinux";
                default:
                    return "other";
            }
        }
    }
}

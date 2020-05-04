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

    public struct Source {
        public SourceType type;
        public Properties properties;

        public string mode;
        public string server;
        public string protocol;
        public string alias;

        /*
        "source": {"type": "image",                                         // Can be: "image", "migration", "copy" or "none"
               "mode": "pull",                                          // One of "local" (default) or "pull"
               "server": "https://10.0.2.3:8443",                       // Remote server (pull mode only)
               "protocol": "lxd",                                       // Protocol (one of lxd or simplestreams, defaults to lxd)
               "certificate": "PEM certificate",                        // Optional PEM certificate. If not mentioned, system CA is used.
               "alias": "ubuntu/devel"},*/

        public static Source from_json_object (Json.Object json) {
            var source = Source () {
                type = SourceType.from_string (json.get_string_member ("type"))
            };

            if (json.has_member ("properties")) {
                source.properties = Properties.from_json_object (json.get_object_member ("properties"));
            }

            return source;
        }
    }

    public enum SourceType {
        IMAGE,
        MIGRATION,
        COPY,
        NONE;

        public static SourceType from_string (string str) {
            switch (str.down ()) {
                case "migration":
                    return SourceType.MIGRATION;
                case "copy":
                    return SourceType.COPY;
                case "image":
                    return SourceType.IMAGE;
                default:
                    return SourceType.NONE;
            }
        }
    }
}

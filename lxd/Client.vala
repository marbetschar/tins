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

errordomain LXDClientError {
    CURL,
    RESPONSE
}

public class LXD.Client {

    private string host = "lxd";
    private string version = "1.0";

    public struct Container {
        public string name;
        public string status;
    }

    public Container[] get_containers () throws Error {
        var list_json = request (@"/$version/containers");

        var list = list_json.get_array_member ("metadata");
        int i;

        Container[] containers = {};
        for (i = 0; i < list.get_length (); i++) {
            var endpoint = list.get_string_element (i);
            var container_json = request (endpoint).get_object_member ("metadata");

            containers += Container () {
                name = container_json.get_string_member ("name"),
                status = container_json.get_string_member ("status")
            };
        }

        return containers;

      /*
        {
    "architecture": "x86_64",
    "config": {
        "limits.cpu": "3",
        "volatile.base_image": "97d97a3d1d053840ca19c86cdd0596cf1be060c5157d31407f2a4f9f350c78cc",
        "volatile.eth0.hwaddr": "00:16:3e:1c:94:38"
    },
    "created_at": "2016-02-16T01:05:05Z",
    "devices": {
        "rootfs": {
            "path": "/",
            "type": "disk"
        }
    },
    "ephemeral": false,
    "expanded_config": {    // the result of expanding profiles and adding the instance's local config
        "limits.cpu": "3",
        "volatile.base_image": "97d97a3d1d053840ca19c86cdd0596cf1be060c5157d31407f2a4f9f350c78cc",
        "volatile.eth0.hwaddr": "00:16:3e:1c:94:38"
    },
    "expanded_devices": {   // the result of expanding profiles and adding the instance's local devices
        "eth0": {
            "name": "eth0",
            "nictype": "bridged",
            "parent": "lxdbr0",
            "type": "nic"
        },
        "root": {
            "path": "/",
            "type": "disk"
        }
    },
    "last_used_at": "2016-02-16T01:05:05Z",
    "name": "my-instance",
    "profiles": [
        "default"
    ],
    "stateful": false,      // If true, indicates that the instance has some stored state that can be restored on startup
    "status": "Running",
    "status_code": 103
}*/

    }

    private Json.Object request (string endpoint) throws Error {
        int exit_code;
        string stdout;
        string stderr;

        Process.spawn_command_line_sync (
            curl_command_line (endpoint),
            out stdout,
            out stderr,
            out exit_code
        );

        if (exit_code == 0 && stdout != null && stdout != "") {
            var parser = new Json.Parser ();
            parser.load_from_data (stdout, -1);

            var root = parser.get_root ().get_object ();

            int64 error_code = 0;
            if (root.has_member ("error_code")) {
                error_code = root.get_int_member ("error_code");
            }

            if (error_code != 0) {
                throw new LXDClientError.RESPONSE ("%f: %s".printf (error_code, root.get_string_member ("error")));
            }

            return root;
        }
        throw new LXDClientError.CURL(stderr);
    }

    private string curl_command_line (string endpoint) {
        var args = "--silent --show-error";
        if (host == "lxd") {
            args += " --unix-socket /var/lib/lxd/unix.socket";
        }
        var command_line = @"curl $args $host$endpoint";
        debug (@"lxd-client: $command_line");
        return command_line;
    }
}

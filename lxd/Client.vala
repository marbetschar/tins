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
    API
}

public class LXD.Client {

    private string host;
    private string version;

    public Client (string host = "lxd", string version = "1.0") {
        this.host = host;
        this.version = version;
    }

    public Instance[] get_instances () throws Error {
        var json = http_get (@"/$version/containers");
        var list = json.get_array_member ("metadata");
        int i;

        Instance[] instances = {};
        for (i = 0; i < list.get_length (); i++) {
            instances += get_instance (list.get_string_element (i));
        }

        return instances;
    }

    public Instance get_instance (string id_or_endpoint) throws Error {
        var endpoint = id_or_endpoint;
        if (!endpoint.has_prefix (@"/$version/containers/")) {
            endpoint = @"/$version/containers/$id_or_endpoint";
        }
        var json = http_get (endpoint);

        return Instance.from_json_object (json.get_object_member ("metadata"));
    }

    public bool add_instance (Instance instance) {
        var json = new Json.Node (Json.NodeType.OBJECT);
        json.set_object (instance.to_json ());

        //var response =
        http_post (@"/$version/containers", json);
        return true;

           /* "name": "my-new-instance",                                          // 64 chars max, ASCII, no slash, no colon and no comma
    "architecture": "x86_64",
    "profiles": ["default"],                                            // List of profiles
    "ephemeral": true,                                                  // Whether to destroy the instance on shutdown
    "config": {"limits.cpu": "2"},                                      // Config override.
    "devices": {                                                        // Optional list of devices the instance should have
        "kvm": {
            "path": "/dev/kvm",
            "type": "unix-char"
        },
    },
    "source": {"type": "image",                                         // Can be: "image", "migration", "copy" or "none"
               "properties": {                                          // Properties
                    "os": "ubuntu",
                    "release": "18.04",
                    "architecture": "x86_64"
                }},*/
    }

    public Image[] get_images () throws Error {
        var json = http_get (@"/$version/images");
        var list = json.get_array_member ("metadata");
        int i;

        Image[] images = {};
        for (i = 0; i < list.get_length (); i++) {
            images += get_image (list.get_string_element (i));
        }

        return images;
    }

    public Image get_image (string id_or_endpoint) throws Error {
        var endpoint = id_or_endpoint;
        if (!endpoint.has_prefix (@"/$version/images/")) {
            endpoint = @"/$version/images/$id_or_endpoint";
        }
        var json = http_get (endpoint);

        return Image.from_json_object (json.get_object_member ("metadata"));
    }

    public Profile get_profile (string id_or_endpoint) throws Error {
        var endpoint = id_or_endpoint;
        if (!endpoint.has_prefix (@"/$version/profiles/")) {
            endpoint = @"/$version/profiles/$id_or_endpoint";
        }
        var json = http_get (endpoint);

        return Profile.from_json_object (json.get_object_member ("metadata"));
    }

    private Json.Object http_get (string endpoint) throws Error {
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
            debug (@"lxd-client: $stdout");

            var parser = new Json.Parser ();
            parser.load_from_data (stdout, -1);

            var root = parser.get_root ().get_object ();

            int64 error_code = 0;
            if (root.has_member ("error_code")) {
                error_code = root.get_int_member ("error_code");
            }

            if (error_code != 0) {
                throw new LXDClientError.API ("%f: %s".printf (error_code, root.get_string_member ("error")));
            }

            return root;
        }
        throw new LXDClientError.CURL(stderr);
    }

    private void http_post (string endpoint, Json.Node json) {
        var generator = new Json.Generator ();
        generator.root = json;

        var data = new StringBuilder ();
        generator.to_gstring (data);

        debug (@"json_data: $(data.str)");

        //return null;
    }

    private string curl_command_line (string endpoint) {
        var args = "--silent --show-error --location";
        if (host == "lxd") {
            args += " --unix-socket /var/lib/lxd/unix.socket";
        }
        var command_line = @"curl $args $host$endpoint";
        debug (@"lxd-client: $command_line");
        return command_line;
    }
}

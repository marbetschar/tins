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
    API,
    RESPONSE
}

public class LXD.Client {

    public string host { get; private set; }
    public string version { get; private set; }

    public Client (string host = "lxd", string version = "1.0") {
        this.host = host;
        this.version = version;
    }

    public Array<Instance> get_instances () throws Error {
        var json = api_request ("GET", @"/$version/containers");
        var list = json.get_array ();
        int i;

        var instances = new GLib.Array<Instance> ();
        for (i = 0; i < list.get_length (); i++) {
            instances.append_val (get_instance (list.get_string_element (i)));
        }

        return instances;
    }

    public LXD.Instance get_instance (string id_or_endpoint) throws Error {
        var endpoint = id_or_endpoint;
        if (!endpoint.has_prefix (@"/$version/containers/")) {
            endpoint = @"/$version/containers/$id_or_endpoint";
        }
        var node = api_request ("GET", endpoint);

        return Json.gobject_deserialize (typeof (LXD.Instance), node) as LXD.Instance;
    }

    public LXD.Operation add_instance (Instance instance) throws Error {
        var json = Json.gobject_serialize (instance);

        /**
         * remove: "display_name"
         */
        if (json.get_object ().has_member ("display-name")) {
            json.get_object ().remove_member ("display-name");
        }

        /**
         * rename: "source-type" => "type"
         */
        if (json.get_object ().has_member ("source")) {
            var source = json.get_object ().get_object_member ("source");
            if (source.has_member ("source-type")) {
                source.set_string_member ("type", source.get_string_member ("source-type"));
                source.remove_member ("source-type");
            }
        }

        var generator = new Json.Generator ();
        generator.root = json;

        var data = new StringBuilder ();
        generator.to_gstring (data);

        var node = api_request ("POST", @"/$version/containers", data.str);

        return Json.gobject_deserialize (typeof (LXD.Operation), node) as LXD.Operation;
    }

    public LXD.Operation start_instance (string id_or_endpoint) throws Error {
        var endpoint = id_or_endpoint;
        if (!endpoint.has_prefix (@"/$version/containers/")) {
            endpoint = @"/$version/containers/$id_or_endpoint/state";
        }
        var node = api_request ("PUT", endpoint, "{ \"action\": \"start\" }");
        return Json.gobject_deserialize (typeof (LXD.Operation), node) as LXD.Operation;
    }

    public LXD.Operation stop_instance (string id_or_endpoint) throws Error {
        var endpoint = id_or_endpoint;
        if (!endpoint.has_prefix (@"/$version/containers/")) {
            endpoint = @"/$version/containers/$id_or_endpoint/state";
        }
        var node = api_request ("PUT", endpoint, "{ \"action\": \"stop\" }");
        return Json.gobject_deserialize (typeof (LXD.Operation), node) as LXD.Operation;
    }

    public LXD.Operation remove_instance (string id_or_endpoint) throws Error {
        var endpoint = id_or_endpoint;
        if (!endpoint.has_prefix (@"/$version/containers/")) {
            endpoint = @"/$version/containers/$id_or_endpoint";
        }
        var node = api_request ("DELETE", endpoint, "{}");
        return Json.gobject_deserialize (typeof (LXD.Operation), node) as LXD.Operation;
    }

    public Operation get_operation (string id_or_endpoint) throws Error {
        var endpoint = id_or_endpoint;
        if (!endpoint.has_prefix (@"/$version/operations/")) {
            endpoint = @"/$version/operations/$id_or_endpoint";
        }
        var node = api_request ("GET", endpoint);
        return Json.gobject_deserialize (typeof (LXD.Operation), node) as LXD.Operation;
    }

    public Operation wait_operation (string id_or_endpoint) throws Error {
        var endpoint = id_or_endpoint;
        if (!endpoint.has_prefix (@"/$version/operations/")) {
            endpoint = @"/$version/operations/$id_or_endpoint/wait";
        }
        var node = api_request ("GET", endpoint);
        return Json.gobject_deserialize (typeof (LXD.Operation), node) as LXD.Operation;
    }

    public uint count_images (string? filter = null) throws Error {
        var json = api_request ("GET", @"/$version/images", (filter == null ? "" : @"filter=$filter"));
        var list = json.get_array ();

        return list.get_length ();
    }

    public Array<Image> get_images (string? filter = null) throws Error {
        var json = api_request ("GET", @"/$version/images", (filter == null ? "" : @"filter=$filter"));
        var list = json.get_array ();
        int i;

        var images = new GLib.Array<Image> ();
        for (i = 0; i < list.get_length (); i++) {
            images.append_val (get_image (list.get_string_element (i)));
        }

        return images;
    }

    public Image get_image (string id_or_endpoint) throws Error {
        var endpoint = id_or_endpoint;
        if (!endpoint.has_prefix (@"/$version/images/")) {
            endpoint = @"/$version/images/$id_or_endpoint";
        }
        var node = api_request ("GET", endpoint);

        return Json.gobject_deserialize (typeof (LXD.Image), node) as LXD.Image;
    }

    private Json.Node api_request (string method, string endpoint, string? data = null) throws Error {
        int exit_code;
        string stdout;
        string stderr;

        Process.spawn_command_line_sync (
            curl_command_line (method, endpoint, data),
            out stdout,
            out stderr,
            out exit_code
        );

        if (exit_code == 0 && stdout != null && stdout != "") {
            debug (@"lxd-client: $stdout");

            var parser = new Json.Parser ();
            parser.load_from_data (stdout, -1);

            var root = parser.get_root ();
            var result = root.get_object ();

            int64 error_code = 0;
            if (result.has_member ("error_code")) {
                error_code = result.get_int_member ("error_code");
            }

            if (error_code != 0) {
                throw new LXDClientError.API ("Error %lld: %s".printf (error_code, result.get_string_member ("error")));
            }

            if (result.has_member("metadata")) {
                return result.get_member ("metadata");
            }
            throw new LXDClientError.RESPONSE (stdout);
        }
        throw new LXDClientError.CURL(stderr);
    }

    private string curl_command_line (string method, string endpoint, string? data = null) {
        var args = "--silent --show-error --location --request " + method;
        if (method == "POST") {
            args += @" --header \"Content-Type: application/json\"";
        }
        if (data != null) {
            args += @" --data \'$data\'";
        }
        if (host == "lxd") {
            args += " --unix-socket /var/lib/lxd/unix.socket";
        }
        var command_line = @"curl $args \"$host$endpoint\"";
        debug (@"lxd-client: $command_line");
        return command_line;
    }

}

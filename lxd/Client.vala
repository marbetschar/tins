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
* Authored by: Marco Betschart <elementary-tins@marco.betschart.name>
*/

errordomain LXDClientError {
    CURL,
    SERVER,
    RESPONSE
}

public class LXD.Client {

    public string host { get; private set; }
    public string version { get; private set; }

    public Client (string host = "lxd", string version = "1.0") {
        this.host = host;
        this.version = version;
    }

    public GenericArray<Instance> get_instances () throws Error {
        var json = api_request ("GET", @"/$version/containers");
        var list = json.get_array ();
        int i;

        var instances = new GLib.GenericArray<Instance> ();
        for (i = 0; i < list.get_length (); i++) {
            instances.add (get_instance (list.get_string_element (i)));
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

    public void update_instance (LXD.Instance instance) throws Error {
        var endpoint = @"/$version/containers/$(instance.name)";
        var json = Json.gobject_serialize (instance);

        /**
         * remove: "display_name"
         */
        if (json.get_object ().has_member ("display-name")) {
            json.get_object ().remove_member ("display-name");
        }

        /**
         * remove: "name"
         */
        if (json.get_object ().has_member ("name")) {
            json.get_object ().remove_member ("name");
        }

        /**
         * rename: "expanded-config" => "expanded_config"
         */
        if (json.get_object ().has_member ("expanded-config")) {
            json.get_object ().set_object_member ("expanded_config", json.get_object ().get_object_member ("expanded-config"));
            json.get_object ().remove_member ("expanded-config");
        }

        /**
         * rename: "expanded-devices" => "expanded_devices"
         */
        if (json.get_object ().has_member ("expanded-devices")) {
            json.get_object ().set_object_member ("expanded_devices", json.get_object ().get_object_member ("expanded-devices"));
            json.get_object ().remove_member ("expanded-devices");
        }

        var generator = new Json.Generator ();
        generator.root = json;

        var data = new StringBuilder ();
        generator.to_gstring (data);

        api_request ("PATCH", endpoint, data.str);
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

    public LXD.Operation exec_instance (string id, LXD.InstanceExec instance_exec) throws Error {
        var endpoint = @"/$version/containers/$id/exec";
        var json = Json.gobject_serialize (instance_exec);

        var generator = new Json.Generator ();
        generator.root = json;

        var data = new StringBuilder ();
        generator.to_gstring (data);

        var node = api_request ("POST", endpoint, data.str);

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

    public LXD.Profile get_profile (string id_or_endpoint) throws Error {
        var endpoint = id_or_endpoint;
        if (!endpoint.has_prefix (@"/$version/profiles/")) {
            endpoint = @"/$version/profiles/$id_or_endpoint";
        }
        var node = api_request ("GET", endpoint);

        return Json.gobject_deserialize (typeof (LXD.Profile), node) as LXD.Profile;
    }

    public void add_profile(LXD.Profile profile) throws Error {
        var json = Json.gobject_serialize (profile);

        var generator = new Json.Generator ();
        generator.root = json;

        var data = new StringBuilder ();
        generator.to_gstring (data);

        api_request ("POST", @"/$version/profiles", data.str);
    }

    public LXD.Operation replace_profile (Profile profile) throws Error {
        var endpoint = @"/$version/profiles/$(profile.name)";
        var json = Json.gobject_serialize (profile);

        /**
         * remove: "name"
         */
        if (json.get_object ().has_member ("name")) {
            json.get_object ().remove_member ("name");
        }

        var generator = new Json.Generator ();
        generator.root = json;

        var data = new StringBuilder ();
        generator.to_gstring (data);

        var node = api_request ("PUT", endpoint, data.str);

        return Json.gobject_deserialize (typeof (LXD.Operation), node) as LXD.Operation;
    }

    private Json.Node api_request (string method, string endpoint, string? data = null) throws Error {
        int exit_code;
        string stdout;
        string stderr;
        File data_file;

        Process.spawn_command_line_sync (
            curl_command_line (method, endpoint, data, out data_file),
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
                throw new LXDClientError.SERVER ("Error %lld: %s".printf (error_code, result.get_string_member ("error")));
            }

            if (result.has_member("metadata")) {
                if (data_file != null) {
                    try {
                        data_file.delete ();
                    } catch (Error e) {
                        warning (e.message);
                    }
                }
                return result.get_member ("metadata");
            }
            throw new LXDClientError.RESPONSE (stdout);
        }
        throw new LXDClientError.CURL(stderr);
    }

    private string curl_command_line (string method, string endpoint, string? data = null, out File? data_file = null) {
        var args = "--silent --show-error --location --request " + method;
        if (method == "POST") {
            args += @" --header \"Content-Type: application/json\"";
        }
        if (data != null) {
            try {
                FileIOStream streams;
                data_file = File.new_tmp ("lxd-XXXXXX.json", out streams);

                DataOutputStream out_stream = new DataOutputStream (streams.output_stream);
                out_stream.put_string (data);

                args += " --data @" + data_file.get_path ();

            } catch (Error e) {
                warning (e.message);
                args += @" --data \'$data\'";
                data_file = null;
            }
        } else {
            data_file = null;
        }
        if (host == "lxd") {
            args += " --unix-socket /var/lib/lxd/unix.socket";
        }
        var command_line = @"curl $args \"$host$endpoint\"";
        if (data == null) {
            debug (@"lxd-client: $command_line");
        } else {
            debug (@"lxd-client: $command_line -- data: $data");
        }
        return command_line;
    }

}

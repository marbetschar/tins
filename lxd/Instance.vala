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

public class LXD.Instance : LXD.Object {

    public static Regex name_non_alpha_regex;
    public static Regex name_multi_dash_regex;

    static construct  {
        try {
            name_non_alpha_regex = new Regex ("[^a-zA-Z0-9_]");
            name_multi_dash_regex = new Regex ("-+");
        } catch (Error e) {
            critical (e.message);
        }
    }

    public string? display_name {
        owned get {
            if (this.name == null) {
                return null;
            }
            var name = this.name;

            try {
                name = name_multi_dash_regex.replace (name, -1, 0, " ");
            } catch (Error e) {
                warning (e.message);
            }
            return name;
        }
        set {
            var name = value;
            if (name != null){
                try {
                    name = name_non_alpha_regex.replace (name, -1, 0, "-");
                    name = name_multi_dash_regex.replace (name, -1, 0, "-");
                } catch (Error e) {
                    warning (e.message);
                }
            }
            this.name = name;
        }
    }

    /**
     * 64 chars max, ASCII, no slash, no colon and no comma
     */
    public string name { get; set; }
    public string architecture { get; set; }
    public GenericArray<string> profiles { get; set; }
    public bool ephemeral { get; set; }
    public bool stateful { get; set; }
    public string status { get; set; }

    public HashTable<string,string> config { get; set; }
    public HashTable<string,HashTable<string,string>> devices { get; set; }

    public Source source { get; set; }

    public class Source : LXD.Object {
        [Description (nick = "type")]
        public string source_type { get; set; }
        public string mode { get; set; }
        public string server { get; set; }
        public string alias { get; set; }
    }


    /* --- Json.Serializable --- */

    public override void property_boxed_value_type_with_param_spec (ParamSpec pspec, out Type boxed_value_type, out bool boxed_in_array) {
        switch (pspec.name) {
            case "profiles":
                boxed_value_type = typeof (string);
                boxed_in_array = true;
                break;
            case "config":
                boxed_value_type = typeof (string);
                boxed_in_array = false;
                break;
            case "devices":
                boxed_value_type = typeof (HashTable);
                boxed_in_array = false;
                break;
            default:
                default_property_boxed_value_type_with_param_spec (pspec, out boxed_value_type, out boxed_in_array);
                break;
        }
    }

    public static LXD.Instance new_from_template_uri (string uri, HashTable<string, string> template_vars = new HashTable<string, string> (str_hash, str_equal)) throws Error {
        var file = File.new_for_uri (uri);

        var json_parser = new Json.Parser ();
        json_parser.load_from_stream (file.read (null), null);

        var instance = Json.gobject_deserialize (typeof (LXD.Instance), json_parser.get_root ()) as LXD.Instance;

        if (instance != null) {
            if (instance.config != null) {
                if (instance.config.get("user.user-data") != null) {
                    try {
                        var user_data = LXD.read_file_from_uri (instance.config.get("user.user-data"));
                        if (user_data != null) {
                            instance.config.set("user.user-data", user_data);
                        }

                    } catch (Error e) {
                        warning (e.message);
                    }
                }

                if (template_vars != null) {
                    LXD.apply_vars_to_hash_table (instance.config, template_vars);
                }
            }

            if (instance.devices != null) {
                var device_names = instance.devices.get_keys ();
                device_names.foreach ((device_name) => {
                    var device = instance.devices.get (device_name);

                    if (device != null && template_vars != null) {
                        LXD.apply_vars_to_hash_table (device, template_vars);
                    }
                });
            }
        }

        return instance;
    }
}

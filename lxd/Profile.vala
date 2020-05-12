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

public class LXD.Profile : LXD.Object {

    public string name { get; set; }
    public string description { get; set; }

    public HashTable<string,string> config { get; set; }
    public HashTable<string,LXD.Device> devices { get; set; }

    /* --- Json.Serializable --- */

    public override void property_boxed_value_type_with_param_spec (ParamSpec pspec, out Type boxed_value_type, out bool boxed_in_array) {
        switch (pspec.name) {
            case "config":
                boxed_value_type = typeof (string);
                boxed_in_array = false;
                break;
            case "devices":
                boxed_value_type = typeof (LXD.Device);
                boxed_in_array = false;
                break;
            default:
                default_property_boxed_value_type_with_param_spec (pspec, out boxed_value_type, out boxed_in_array);
                break;
        }
    }

    public static LXD.Profile new_from_template_uri (string uri) throws Error {
        var file = File.new_for_uri (uri);

        var json_parser = new Json.Parser ();
        json_parser.load_from_stream (file.read (null), null);

        var profile = Json.gobject_deserialize (typeof (LXD.Profile), json_parser.get_root ()) as LXD.Profile;

        if (profile != null) {
            if (profile.config.get("user.user-data") != null) {
                try {
                    var user_data_file = File.new_for_uri (profile.config.get("user.user-data"));

                    if (user_data_file.query_exists ()) {
                        var in_stream = new DataInputStream (user_data_file.read ());
                        var builder = new StringBuilder ();

                        string line;
                        while ((line = in_stream.read_line ()) != null) {
                            builder.append(line + "\n");
                        }
                        var user_data = builder.str;

                        profile.config.set("user.user-data", user_data);
                    }

                } catch (Error e) {
                    warning (e.message);
                }
            }

            unowned Posix.Passwd passwd = Posix.getpwuid (Posix.getuid ());
            if (passwd != null) {
                var pw_uid = "%zu".printf (passwd.pw_uid);

                if (profile.config != null) {
                    var keys = profile.config.get_keys ();
                    keys.foreach ((key) => {
                        var val = profile.config.get (key);

                        if (val != null) {
                            profile.config.set(key, val.replace (
                                "$UID", pw_uid
                            ).replace (
                                "$USER", passwd.pw_name
                            ));
                        }
                    });
                }

                if (profile.devices != null) {
                    profile.devices.foreach ((name, device) => {
                        if (device.path != null) {
                            device.path = device.path.replace (
                                "$UID", pw_uid
                            ).replace (
                                "$USER", passwd.pw_name
                            );
                        }

                        if (device.source != null) {
                            device.source = device.source.replace (
                                "$UID", pw_uid
                            ).replace (
                                "$USER", passwd.pw_name
                            );
                        }

                        if (device.device_type != null) {
                            device.device_type = device.device_type.replace (
                                "$UID", pw_uid
                            ).replace (
                                "$USER", passwd.pw_name
                            );
                        }
                    });
                }
            }
        }

        return profile;
    }
}

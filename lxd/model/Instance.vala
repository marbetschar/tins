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

    public struct Instance {

        public string name;
        public InstanceStatus status;
        public string[] profiles;

        public static Instance from_json_object (Json.Object json) {
            var profiles_json = json.get_array_member ("profiles");

            string[] profiles = {};
            for (var i = 0; i < profiles_json.get_length (); i++) {
                profiles += profiles_json.get_string_element (i);
            }

            return Instance () {
                name = json.get_string_member ("name"),
                status = InstanceStatus.from_string (json.get_string_member ("status")),
                profiles = profiles
            };
        }

        public bool has_profile (string profile) {
            for (var i = 0; i < profiles.length; i++) {
                if (profiles[i] == profile) {
                    return true;
                }
            }
            return false;
        }

        public Json.Object to_json () {
            var json = new Json.Object ();
            json.set_string_member ("name", name);

            var json_profiles =  new Json.Array ();
            for (var i = 0; i < profiles.length; i++) {
                json_profiles.add_string_element (profiles[i]);
            }
            json.set_array_member ("profiles", json_profiles);

            return json;
        }
    }

    public enum InstanceStatus {
        STOPPED,
        RUNNING;

        public static InstanceStatus from_string (string str) {
            switch (str.down ()) {
                case "running":
                    return InstanceStatus.RUNNING;
                default:
                    return InstanceStatus.STOPPED;
            }
        }
    }
}

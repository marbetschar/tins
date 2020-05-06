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

public class LXD.Instance : LXD.Object {

    public static Regex name_non_alpha_regex;
    public static Regex name_multi_dash_regex;

    static construct  {
        name_non_alpha_regex = new Regex ("[^a-zA-Z0-9_]");
        name_multi_dash_regex = new Regex ("-+");
    }

    public string display_name {
        owned get {
            if (this.name == null) {
                return null;
            }
            return name_multi_dash_regex.replace (this.name, -1, 0, " ");
        }
        set {
            var name = value;
            if (name != null){
                name = name_non_alpha_regex.replace (name, -1, 0, "-");
                name = name_multi_dash_regex.replace (name, -1, 0, "-");
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
            default:
                default_property_boxed_value_type_with_param_spec (pspec, out boxed_value_type, out boxed_in_array);
                break;
        }
    }
}

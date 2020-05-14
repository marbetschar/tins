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

public class LXD.Image : LXD.Object {

    public string fingerprint { get; construct set; }

    public string filename { get; set; }
    public string architecture { get; set; }
    public int size { get; set; }

    public Properties properties { get; set; }
    public GenericArray<string> desktops { get; set; }

    public class Properties : LXD.Object {
        public string architecture { get; set; }
        public string description { get; set; }
        public string os { get; set; }
        public string release { get; set; }
        public string variant { get; set; }
    }

    /* --- Json.Serializable --- */

    public override void property_boxed_value_type_with_param_spec (ParamSpec pspec, out Type boxed_value_type, out bool boxed_in_array) {
        switch (pspec.name) {
            case "desktops":
                boxed_value_type = typeof (string);
                boxed_in_array = true;
                break;
            default:
                default_property_boxed_value_type_with_param_spec (pspec, out boxed_value_type, out boxed_in_array);
                break;
        }
    }
}

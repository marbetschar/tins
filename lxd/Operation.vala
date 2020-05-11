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

public class LXD.Operation : LXD.Object {

    public string id { get; set; }
    public string status { get; set; }
    public int status_code { get; set; }
    public string description { get; set; }
    public bool may_cancel { get; set; }
    public string err { get; set; }

    public Metadata metadata { get; set; }
    public Resources resources { get; set; }

    public class Metadata : LXD.Object {
        public string download_progress { get; set; }
    }

    public class Resources : LXD.Object {
        public GenericArray<string> containers { get; set; }


        /* --- Json.Serializable --- */

        public override void property_boxed_value_type_with_param_spec (ParamSpec pspec, out Type boxed_value_type, out bool boxed_in_array) {
            switch (pspec.name) {
                case "containers":
                    boxed_value_type = typeof (string);
                    boxed_in_array = true;
                    break;
                default:
                    default_property_boxed_value_type_with_param_spec (pspec, out boxed_value_type, out boxed_in_array);
                    break;
            }
        }
    }
}

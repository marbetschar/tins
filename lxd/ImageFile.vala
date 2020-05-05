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

public class LXD.ImageFile : LXD.Object {

    public string origin { get; set; }
    public string created { get; set; }

    public Array<LXD.Image> data { get; set; }
    public LXD.Image test { get; set; }

    public override Type deserialize_property_with_boxed_type (ParamSpec pspec) {
        switch (pspec.name) {
            case "data":
                return typeof (LXD.Image);
            default:
                return default_deserialize_property_with_boxed_type (pspec);
        }
    }
}

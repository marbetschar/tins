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

    public struct Profile {

        public string name;
        public string description;

        public static Profile from_json_object (Json.Object json) {
            return Profile () {
                name = json.has_member ("name") ? json.get_string_member ("name") : null,
                description = json.has_member ("description") ? json.get_string_member ("description") : null
            };
        }
    }

    // TODO:
    // public static Profile GUI_PROFILE = ...
}

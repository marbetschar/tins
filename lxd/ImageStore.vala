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

public class LXD.ImageStore : LXD.Object {

    public string created_at { get; set; }
    public GenericArray<LXD.ImageSource> data { get; set; }

    public GenericArray<string> get_operating_systems () {
        var operating_systems = new GenericArray<string> ();

        data.foreach((image_source) => {
            if (!operating_systems.find_with_equal_func (image_source.os, str_equal)) {
                operating_systems.add (image_source.os);
            }
        });
        operating_systems.sort (strcmp);

        return operating_systems;
    }

    public GenericArray<string> get_releases (string operating_system) {
        var releases = new GenericArray<string> ();

        data.foreach((image_source) => {
            if (
                image_source.os == operating_system &&
                !releases.find_with_equal_func (image_source.release, str_equal)
            ) {
                releases.add (image_source.release);
            }
        });
        releases.sort (strcmp);

        return releases;
    }

    public GenericArray<string> get_variants (string operating_system, string release) {
        var variants = new GenericArray<string> ();

        data.foreach((image_source) => {
            if (
                image_source.os == operating_system &&
                image_source.release == release &&
                !variants.find_with_equal_func (image_source.variant, str_equal)
            ) {
                variants.add (image_source.variant);
            }
        });
        variants.sort (strcmp);

        return variants;
    }

    public LXD.ImageSource? get_image_source (
        string operating_system,
        string release,
        string variant,
        string architecture
    ) {
        for (int i = 0; i < data.length; i++) {
            var image_source = data.get(i);
            if (
                image_source.os == operating_system &&
                image_source.release == release &&
                image_source.architecture == architecture &&
                image_source.variant == variant
            ) {
                return image_source;
            }
        }
        return null;
    }

    /* --- Json.Serializable --- */

    public override void property_boxed_value_type_with_param_spec (ParamSpec pspec, out Type boxed_value_type, out bool boxed_in_array) {
        switch (pspec.name) {
            case "data":
                boxed_value_type = typeof (LXD.ImageSource);
                boxed_in_array = true;
                break;
            default:
                default_property_boxed_value_type_with_param_spec (pspec, out boxed_value_type, out boxed_in_array);
                break;
        }
    }
}

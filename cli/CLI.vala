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

public class Boxes.Application : GLib.Application {

    public static LXD.Client lxd_client;

    static construct {
        lxd_client = new LXD.Client ("https://images.linuxcontainers.org");
    }

    protected override void activate () {
        var images = lxd_client.get_images ();

        var image_file = new LXD.ImageFile ();
        image_file.origin = lxd_client.host;
        image_file.created = new DateTime.now_utc ().format ("%FT%TZ");

        Json.Node root = Json.gobject_serialize (image_file);

        var json_object = root.get_object ();
        Json.Array json_images = new Json.Array.sized (images.length ());
        images.@foreach((image) => {
            json_images.add_object_element (Json.gobject_serialize (image).get_object ());
        });
        json_object.set_array_member ("metadata", json_images);

        Json.Generator generator = new Json.Generator ();
        generator.set_root (root);

        var file = GLib.File.new_for_path ("com.github.marbetschar.boxes.images.json");
        stdout.printf ("Write to %s ...\n", file.get_path ());

        if (file.query_exists ()) {
            file.@delete ();
        }

        var file_out_stream = file.create (FileCreateFlags.REPLACE_DESTINATION);
        generator.to_stream (file_out_stream, null);

        stdout.printf ("Done.\n");
    }

    public static int main (string[] args) {
        var app = new Application ();
        return app.run (args);
    }
}


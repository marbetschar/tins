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
        stdout.printf ("Downloading metadata for %u images from %s - this may take a while…\n",
            lxd_client.count_images (),
            lxd_client.host
        );
        var all_images = lxd_client.get_images ();

        HashTable<string,Array<LXD.Image>> data = new HashTable<string,Array<LXD.Image>> (str_hash, str_equal);
        for(var i = 0; i < all_images.length; i++) {
            var image = all_images.index (i);

            if (image.architecture != "x86_64") {
                stdout.printf ("Skipping %s…\n", image.properties.description);
                continue;
            }

            if (data.get(image.properties.os) == null) {
                data.set(image.properties.os, new Array<LXD.Image> ());
            }
            data.get(image.properties.os).append_val (image);
        }

        var image_store = new LXD.ImageStore ();
        image_store.server = lxd_client.host;
        image_store.created_at = new DateTime.now_utc ().format ("%FT%TZ");
        image_store.data = data;

        Json.Node root = Json.gobject_serialize (image_store);
        Json.Generator generator = new Json.Generator ();
        generator.set_root (root);

        var file = GLib.File.new_for_path ("image-store.json");
        stdout.printf ("Writing image store to %s …\n", file.get_path ());

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


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

public class Boxes.Application : Gtk.Application {

    public static GLib.Settings settings;
    public static LXD.Client lxd_client;
    public static LXD.PublicImageCache lxd_image_cache;

    static construct {
        settings = new Settings ("com.github.marbetschar.boxes");
        lxd_client = new LXD.Client ();

        /**
         * Using Idle to load cached image data
         * avoids blocking application startup
         */
        Idle.add (() => {
            try {
                var image_cache_file = File.new_for_uri ("resource:///com/github/marbetschar/boxes/cache/public-image-cache.json");

                var parser = new Json.Parser ();
                parser.load_from_stream (image_cache_file.read (null), null);
                lxd_image_cache = Json.gobject_deserialize (typeof (LXD.PublicImageCache), parser.get_root ()) as LXD.PublicImageCache;

                debug ("Loaded images for %u operating systems from cache.".printf (lxd_image_cache.data.size ()));

            } catch (Error e) {
                critical (e.message);
            }

            return GLib.Source.REMOVE;
        });
    }

    public Application () {
        Object (
            application_id: "com.github.marbetschar.boxes",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        if (get_windows ().length () > 0) {
            get_windows ().data.present ();
            return;
        }
        var main_window = new MainWindow (this);

        int window_x, window_y;
        var rect = Gtk.Allocation ();

        settings.get ("window-position", "(ii)", out window_x, out window_y);
        settings.get ("window-size", "(ii)", out rect.width, out rect.height);

        if (window_x != -1 || window_y != -1) {
            main_window.move (window_x, window_y);
        }

        main_window.set_allocation (rect);
        main_window.show_all ();

        var quit_action = new SimpleAction ("quit", null);

        add_action (quit_action);
        set_accels_for_action ("app.quit", {"<Control>q"});

        quit_action.activate.connect (() => {
            if (main_window != null) {
                main_window.destroy ();
            }
        });
    }

    public static int main (string[] args) {
        var app = new Application ();
        return app.run (args);
    }
}


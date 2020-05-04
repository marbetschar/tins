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

[GtkTemplate (ui = "/com/github/marbetschar/boxes/ui/AddContainerAssistant.glade")]
public class Boxes.AddContainerAssistant : Gtk.Assistant {

    private static LXD.OperatingSystem[] all_known_operating_systems;
    private static HashTable<LXD.OperatingSystem, Gee.Collection<LXD.Image?>> all_known_operating_system_images;

    static construct {
        all_known_operating_systems = LXD.ALL_KNOWN_OPERATING_SYSTEMS;
        all_known_operating_system_images = new HashTable<LXD.OperatingSystem, Gee.Collection<LXD.Image?>> (direct_hash, direct_equal);

        /* TODO: Put available images in JSON file and parse from there */

        var fedora_images = new Gee.ArrayList<LXD.Image?> ((Gee.EqualDataFunc<LXD.Image>?) direct_equal);
        fedora_images.add (LXD.Image () { properties = LXD.Properties () { os = LXD.OperatingSystem.FEDORA, release = "30", architecture = "amd64" } });
        fedora_images.add (LXD.Image () { properties = LXD.Properties () { os = LXD.OperatingSystem.FEDORA, release = "31", architecture = "amd64" } });
        fedora_images.add (LXD.Image () { properties = LXD.Properties () { os = LXD.OperatingSystem.FEDORA, release = "32", architecture = "amd64" } });
        all_known_operating_system_images.insert (LXD.OperatingSystem.FEDORA, fedora_images);

        var ubuntu_images = new Gee.ArrayList<LXD.Image?> ((Gee.EqualDataFunc<LXD.Image>?) direct_equal);
        ubuntu_images.add (LXD.Image () { properties = LXD.Properties () { os = LXD.OperatingSystem.UBUNTU, release = "bionic", architecture = "amd64" } });
        ubuntu_images.add (LXD.Image () { properties = LXD.Properties () { os = LXD.OperatingSystem.UBUNTU, release = "eoan", architecture = "amd64" } });
        ubuntu_images.add (LXD.Image () { properties = LXD.Properties () { os = LXD.OperatingSystem.UBUNTU, release = "focal", architecture = "amd64" } });
        all_known_operating_system_images.insert (LXD.OperatingSystem.UBUNTU, ubuntu_images);
    }

    construct {
        for(var i = 0; i < all_known_operating_systems.length; i++) {
            operating_system_combobox.append_text (_(all_known_operating_systems[i].to_string ()));
        }
        operating_system_combobox.active = 0;
    }

    [GtkChild]
    private Gtk.Entry name_entry;

    [GtkChild]
    private Gtk.ComboBoxText operating_system_combobox;

    [GtkChild]
    private Gtk.ComboBoxText image_combobox;

    [GtkChild]
    private Gtk.CheckButton gui_enabled_checkbutton;

    [GtkCallback]
    private bool on_key_release_name_entry (Gtk.Widget source, Gdk.EventKey event) {
        validate_current_page ();
        return Gdk.EVENT_PROPAGATE;
    }

    [GtkCallback]
    private void on_changed_operating_system (Gtk.Widget source) {
        image_combobox.remove_all ();

        var operating_system = all_known_operating_systems[operating_system_combobox.active];
        var operating_system_images = all_known_operating_system_images[operating_system];

        if (operating_system_images != null) {
            var images = operating_system_images.to_array ();

            for(var i = 0; i < images.length; i++) {
                var image = images[i];
                image_combobox.append_text (_(@"$(image.properties.release)"));
            }
            image_combobox.active = 0;
        }

        validate_current_page ();
    }

    [GtkCallback]
    private void on_cancel (Gtk.Widget source) {
        destroy ();
    }

    [GtkCallback]
    private void on_close (Gtk.Widget source) {
        destroy ();
    }

    [GtkCallback]
    private void on_apply (Gtk.Widget source) {
        string[] profiles = { "default" };
        if (gui_enabled_checkbutton.active) {
            profiles += "gui";
        }

        var instance = LXD.Instance () {
            name = name_entry.text.strip (),
            profiles = profiles
        };

        Application.lxd_client.add_instance (instance);
    }

    private void validate_current_page () {
        var current_index = get_current_page ();
        var current_page = get_nth_page (current_index);

        if (current_index == 0) {
            if (name_entry.text == null || name_entry.text.strip () == "" || image_combobox.get_active_text () == null) {
                set_page_complete (current_page, false);
            } else {
                set_page_complete (current_page, true);
            }

        } else {
            set_page_complete (current_page, true);
        }
    }
}

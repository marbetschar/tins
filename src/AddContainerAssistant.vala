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

    private static List<unowned string> all_os_keys;

    static construct {
        all_os_keys = Application.lxd_image_store.data.get_keys ();
        all_os_keys.sort (strcmp);
    }

    construct {
        all_os_keys.@foreach ((os) => {
            operating_system_combobox.append_text (_(os));
        });
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

        var os_key = all_os_keys.nth_data (operating_system_combobox.active);
        var os_images = Application.lxd_image_store.data.get (os_key);

        if (os_images != null) {
            for(var i = 0; i < os_images.length; i++) {
                var os_image = os_images.get(i);
                image_combobox.append_text (_(os_image.properties.release));
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
        var os_key = all_os_keys.nth_data (operating_system_combobox.active);
        var all_os_images = Application.lxd_image_store.data.get (os_key);
        var os_image = all_os_images.get (image_combobox.active);

        var instance_source = new LXD.Instance.Source ();
        instance_source.source_type = "image";
        instance_source.mode = "pull";
        instance_source.server = Application.lxd_image_store.server;
        instance_source.alias = @"$(os_image.properties.os)/$(os_image.properties.release)/$(os_image.properties.architecture)";

        var instance = new LXD.Instance ();
        instance.source = instance_source;

        instance.display_name = name_entry.text;
        debug (@"instance.name: $(instance.name)");
        instance.architecture = "x86_64";

        var profiles = new GenericArray<string> ();
        profiles.add ("default");
        if (gui_enabled_checkbutton.active) {
            profiles.add ("gui");
        }
        instance.profiles = profiles;

        try {
            Application.lxd_client.add_instance (instance);

        } catch (Error e) {
            critical (e.message);
        }
    }

    [GtkCallback]
    private void on_prepare (Gtk.Widget page) {
        validate_current_page ();
    }

    private void validate_current_page () {
        if (name_entry.text == null || name_entry.text.strip () == "" || image_combobox.get_active_text () == null) {
            set_current_page_complete (false);
        } else {
            set_current_page_complete (true);
        }
    }

    private void set_current_page_complete (bool complete) {
        var current_index = get_current_page ();
        var current_page = get_nth_page (current_index);

        set_page_complete (current_page, complete);
    }
}

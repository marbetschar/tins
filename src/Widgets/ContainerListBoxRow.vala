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

[GtkTemplate (ui = "/com/github/marbetschar/boxes/ui/WidgetsContainerListBoxRow.glade")]
public class Boxes.Widgets.ContainerListBoxRow : Gtk.ListBoxRow {

    public string title {
        get { return title_label.label; }
        set { title_label.label = value; }
    }

    public string description {
        get { return description_label.label; }
        set { description_label.label = value; }
    }

    public string image_resource {
        owned get { return logo_box.image_resource; }
        set { logo_box.image_resource = value; }
    }

    public bool enabled {
        get { return logo_box.enabled; }
        set { logo_box.enabled = value; }
    }

    public signal void open ();

    public bool gui_enabled {
        get { return open_button_stack.visible_child == open_button_desktop_image; }
        set {
            open_button_stack.visible_child = value ? open_button_desktop_image : open_button_terminal_image;
        }
    }

    [GtkChild]
    private ContainerLogoBox logo_box;

    [GtkChild]
    private Gtk.Label title_label;

    [GtkChild]
    private Gtk.Label description_label;

    [GtkChild]
    private Gtk.Button open_button;

    [GtkChild]
    private Gtk.Stack open_button_stack;

    [GtkChild]
    private Gtk.Image open_button_terminal_image;

    [GtkChild]
    private Gtk.Image open_button_desktop_image;

    [GtkChild]
    private Gtk.Button settings_button;

    construct {
        logo_box.toggle_enabled.connect ((enabled) => {
            update_request ();
        });
        update_request ();
    }

    private void update_request () {
        if (enabled) {
            description = _("Running...");
            open_button.sensitive = true;
            settings_button.sensitive = false;

        } else {
            settings_button.sensitive = true;
            open_button.sensitive = false;
            description = _("Stopped.");
        }
    }

    [GtkCallback]
    private void on_open_button_clicked (Gtk.Widget source) {
        open ();
    }
}



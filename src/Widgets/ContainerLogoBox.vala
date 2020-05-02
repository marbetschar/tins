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

[GtkTemplate (ui = "/com/github/marbetschar/boxes/ui/WidgetsContainerLogoBox.glade")]
public class Boxes.Widgets.ContainerLogoBox : Gtk.Overlay {

    public signal void toggle_enabled (bool enabled);

    public string image_resource {
        owned get { return logo_image.resource; }
        set { logo_image.resource = value; }
    }

    public bool enabled {
        get { return state_stack.visible_child == state_enabled; }
        set {
            if (value == enabled) {
                return;
            }
            var logo_image_style_context = logo_image.get_style_context ();

            if (value) {
                state_stack.visible_child = state_enabled;
                logo_image_style_context.remove_class (Gtk.STYLE_CLASS_DIM_LABEL);

            } else {
                state_stack.visible_child = state_disabled;
                logo_image_style_context.add_class (Gtk.STYLE_CLASS_DIM_LABEL);
            }

            toggle_enabled (value);
        }
    }

    [GtkChild]
    private Gtk.Image logo_image;

    [GtkChild]
    private Gtk.Stack state_stack;

    [GtkChild]
    private Gtk.Image state_enabled;

    [GtkChild]
    private Gtk.Image state_disabled;

    [GtkCallback]
    private bool on_button_release_event (Gtk.Widget source, Gdk.EventButton event) {
        enabled = !enabled;
        return Gdk.EVENT_PROPAGATE;
    }
}



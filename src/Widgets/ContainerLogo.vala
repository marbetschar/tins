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

public class Boxes.Widgets.ContainerLogo : Gtk.Overlay {

    public Gtk.Image logo;

    [CCode (instance_pos = -1)]
    public Gtk.Stack action_stack;
    public Gtk.Image action_start;
    public Gtk.Image action_stop;

    construct {
        set_template_from_resource ("/com/github/marbetschar/boxes/templates/ContainerLogo.glade");
        init_template ();

        button_release_event.connect (on_button_release_event);
    }

    public bool on_button_release_event (Gdk.EventButton event) {
        debug ("toggle_state...");

        if (action_stack.visible_child == action_start) {
            action_stack.visible_child = action_stop;
        } else {
            action_stack.visible_child = action_start;
        }

        return Gdk.EVENT_STOP;
    }
}



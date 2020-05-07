/*
* Copyright 2019 elementary, Inc. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
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

[GtkTemplate (ui = "/com/github/marbetschar/tins/ui/MainWindow.glade")]
public class Tins.MainWindow : Gtk.ApplicationWindow {

    private uint configure_id;
    private AddContainerAssistant add_container_assistant;

    [GtkChild]
    private Gtk.Viewport viewport;

    [GtkChild]
    private Gtk.Button remove_button;

    private Widgets.ContainerListBox list_box;

    public MainWindow (Gtk.Application application) {
        Object (
            application: application,
            icon_name: "com.github.marbetschar.tins",
            title: _("Tins")
        );
    }

    construct {
        var style_provider = new Gtk.CssProvider ();
        style_provider.load_from_resource ("/com/github/marbetschar/tins/styles/Application.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        list_box = new Widgets.ContainerListBox ();
        try {
            list_box.instances = Application.lxd_client.get_instances ();
        } catch (Error e) {
            critical (e.message);
        }
        viewport.add (list_box);

        list_box.row_selected.connect ((row) => {
            if (row == null) {
                remove_button.sensitive = false;
            } else {
                var instance_row = row as Widgets.ContainerListBoxRow;
                remove_button.sensitive = instance_row.instance.status == "Stopped";
            }
        });

        /**
         * Refresh all available instances
         * in a regular interval
         */
        Timeout.add_seconds (3, () => {
            try {
                list_box.instances = Application.lxd_client.get_instances ();
            } catch (Error e) {
                critical (e.message);
            }

            return GLib.Source.CONTINUE;
        });
    }

    [GtkCallback]
    private void on_add_button_clicked (Gtk.Widget source) {
        if (add_container_assistant == null) {
            add_container_assistant = new AddContainerAssistant ();
            add_container_assistant.destroy.connect (() => {
                add_container_assistant = null;
            });
        }
        add_container_assistant.present ();
    }

    [GtkCallback]
    private void on_remove_button_clicked (Gtk.Widget source) {
        var row = list_box.get_selected_row () as Widgets.ContainerListBoxRow;
        list_box.remove (row);

        try {
            var operation = Application.lxd_client.remove_instance (row.instance.name);

            /**
             * Using Idle to wait for deletion to be completed.
             */
            Idle.add (() => {
                try {
                    Application.lxd_client.wait_operation (operation.id);

                } catch (Error e) {
                    critical (e.message);
                }

                return GLib.Source.REMOVE;
            });

        } catch (Error e) {
            critical (e.message);
        }
    }

    public override bool configure_event (Gdk.EventConfigure event) {
        if (configure_id != 0) {
            GLib.Source.remove (configure_id);
        }

        configure_id = Timeout.add (100, () => {
            configure_id = 0;

            Gdk.Rectangle rect;
            get_allocation (out rect);
            Application.settings.set ("window-size", "(ii)", rect.width, rect.height);

            int root_x, root_y;
            get_position (out root_x, out root_y);
            Application.settings.set ("window-position", "(ii)", root_x, root_y);

            return false;
        });

        return base.configure_event (event);
    }
}

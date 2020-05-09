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

public class Tins.Widgets.ContainerListBox : Gtk.ListBox {

    public GenericArray<LXD.Instance> instances { get; set; }

    construct {
        instances = null;
        selection_mode = Gtk.SelectionMode.SINGLE;

        notify["instances"].connect (() => {
            update_request ();
        });
        update_request ();
    }

    private void update_request () {
        if (instances == null || instances.length == 0) {
            var children = get_children ();

            if (children != null) {
                children.@foreach((row) => {
                    remove (row);
                });
            }

        } else {
            var children = get_children ();

            for (var i = 0; i < instances.length; i++) {
                ContainerListBoxRow row;

                if (children != null && i < children.length ()) {
                    row = children.nth_data (i) as ContainerListBoxRow;
                } else {
                    row = construct_instance_row ();
                }

                row.instance = instances.get (i);

                if (children == null || children.length () < (i+1)) {
                    add (row);
                }
            }

            if (children != null && children.length () > instances.length) {
                for(var i = instances.length; i < children.length (); i++){
                    remove (children.nth_data (i-1));
                }
            }
        }
    }

    private ContainerListBoxRow construct_instance_row () {
        var row = new ContainerListBoxRow ();

        row.toggle_enable.connect ((instance, did_enable) => {
            var selected_row = get_selected_row ();
            if (selected_row != null) {
                unselect_row (selected_row);
            }

            try {
                if (did_enable) {
                    Application.lxd_client.start_instance (instance.name);
                } else {
                    Application.lxd_client.stop_instance (instance.name);
                }

                if (selected_row != null) {
                    select_row (selected_row);
                }

            } catch (Error e) {
                var error_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                    _("Error"),
                    _(e.message),
                    "dialog-error",
                    Gtk.ButtonsType.CLOSE
                );
                error_dialog.run ();
                error_dialog.destroy ();
            }
        });

        row.open_clicked.connect ((instance) => {
            try {
                var app_info = AppInfo.create_from_commandline (
                    @"io.elementary.terminal --execute=\"lxc exec $(instance.name) -- /bin/bash\"",
                    null,
                    AppInfoCreateFlags.NONE
                );

                if (app_info != null) {
                    app_info.launch (null, Gdk.Screen.get_default ().get_display ().get_app_launch_context ());
                }

            } catch (Error e) {
                var error_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                    _("Error"),
                    _(e.message),
                    "dialog-error",
                    Gtk.ButtonsType.CLOSE
                );
                error_dialog.run ();
                error_dialog.destroy ();
            }
        });

        return row;
    }
}



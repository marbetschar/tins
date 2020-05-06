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

public class Boxes.Widgets.ContainerListBox : Gtk.ListBox {

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

                update_instance_row (row, instances.get (i));

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

        row.toggle_enabled.connect ((instance, enabled) => {
            var selected_row = get_selected_row ();
            if (selected_row != null) {
                unselect_row (selected_row);
            }

            try {
                 LXD.Operation operation;

                if (enabled) {
                    operation = Application.lxd_client.start_instance (instance.name);
                    instance.status = "Running";
                } else {
                    operation = Application.lxd_client.stop_instance (instance.name);
                    instance.status = "Stopped";
                }

                if (selected_row != null) {
                    select_row (selected_row);
                }

                /**
                 * Using Idle to wait for status change to be completed.
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
        });

        row.open_clicked.connect ((instance) => {
            try {
                Process.spawn_command_line_async (@"io.elementary.terminal --execute=\"lxc exec $(instance.name) -- /bin/bash\"");
            } catch (Error e) {
                critical (e.message);
            }
        });

        return row;
    }

    private void update_instance_row (ContainerListBoxRow row, LXD.Instance instance) {
        row.instance = instance;
        row.title = instance.display_name;
        row.enabled = instance.status == "Running";
        //row.gui_enabled = container.gui_enabled;
        var instance_os = instance.config.get("image.os");
        if (instance_os != null) {
            row.image_resource = resource_for_os (instance_os);
        }
    }

    private string resource_for_os (string os) {
        var file = File.new_for_uri (@"resource:///com/github/marbetschar/boxes/os/$os.svg");
        if (file.query_exists ()) {
            return @"/com/github/marbetschar/boxes/os/$os.svg";
        }
        return "/com/github/marbetschar/boxes/os/linux.svg";
    }
}



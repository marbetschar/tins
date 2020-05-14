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

errordomain TinsError {
    X11
}


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
            var selected_row = get_selected_row ();

            if (selected_row != null) {
                unselect_row (selected_row);
            }

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

            if (selected_row != null) {
                select_row (selected_row);
            }
        }
    }

    private ContainerListBoxRow construct_instance_row () {
        var row = new ContainerListBoxRow ();

        row.toggle_enable.connect ((instance, did_enable) => {
            try {
                if (did_enable) {
                    if (instance.profiles.find_with_equal_func ("tins-x11", str_equal)) {
                        var template = LXD.Instance.new_from_template_uri ("resource:///com/github/marbetschar/tins/lxd/instances/tins-x11.json");
                        template.name = instance.name;

                        if (template.devices != null) {
                            var device_names = template.devices.get_keys ();
                            device_names.foreach ((device_name) => {
                                var device = template.devices.get (device_name);

                                if (device != null) {
                                    device.get_keys ().foreach ((key) => {
                                        if (key == "type") {
                                            device.set(key, "none");
                                        } else {
                                            device.remove(key);
                                        }
                                    });
                                }
                            });
                        }

                        Application.lxd_client.update_instance (template);
                    }

                    Application.lxd_client.start_instance (instance.name);
                } else {
                    Application.lxd_client.stop_instance (instance.name);
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
            open_instance.begin (instance, (obj,res) => {
                try {
                    open_instance.end (res);

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
        });

        return row;
    }

    private async void open_instance (LXD.Instance instance) throws Error {
        var app_info_commandline = @"io.elementary.terminal --execute=\"lxc exec '$(instance.name)' -- su --login\"";

        if (instance.profiles != null && instance.profiles.find_with_equal_func ("tins-default", str_equal)) {
            string username = LXD.get_username ();

            if (username != null) {
                app_info_commandline = @"io.elementary.terminal --execute=\"lxc exec '$(instance.name)' -- su '$(username)' --login\"";
            }

            if (instance.profiles.find_with_equal_func ("tins-x11", str_equal)) {
                var x11_vars = new HashTable<string, string> (str_hash, str_equal);
                x11_vars.set("$INSTANCE", instance.display_name);

                int x11_display;
                try {
                    x11_display = LXD.count_files_in_path ("/tmp/.X11-unix");
                } catch (Error e) {
                    warning (e.message);
                    x11_display = Random.int_range(50,99);
                }
                x11_vars.set("$DISPLAY", @"$x11_display");

                var xephyr_command_line = LXD.apply_vars_to_string (
                """Xephyr :$DISPLAY \
                        -resizeable \
                        -glamor \
                        -no-host-grab \
                        -title 'Tins -- $INSTANCE' \
                        -screen 1024x768 \
                        -br \
                        -terminate \
                        -noreset \
                        +extension GLX \
                        +extension RANDR \
                        +extension RENDER"""
                , x11_vars);

                debug (xephyr_command_line);
                Process.spawn_command_line_async (xephyr_command_line);

                var stop_operation = Application.lxd_client.stop_instance (instance.name);
                try {
                    Application.lxd_client.wait_operation (stop_operation.id);
                } catch (Error e) {
                    warning (e.message);
                }

                var template = LXD.Instance.new_from_template_uri ("resource:///com/github/marbetschar/tins/lxd/instances/tins-x11.json", x11_vars);
                template.name = instance.name;
                Application.lxd_client.update_instance (template);

                var start_operation = Application.lxd_client.start_instance (instance.name);
                try {
                    Application.lxd_client.wait_operation (start_operation.id);
                } catch (Error e) {
                    warning (e.message);
                }

                string stdout;
                string stderr;
                int exit_status = 0;

                // TODO: Run this command via REST API
                try {
                    Process.spawn_command_line_sync (
                        "lxc exec $(instance.name) -- systemctl restart display-manager",
                        out stdout,
                        out stderr,
                        out exit_status
                    );
                } catch (Error e) {
                    warning (e.message);
                }

                // if (exit_status != 0) {
                //     throw new TinsError.X11 ("%s %s".printf (stderr, stdout));
                // }

                // make sure we don't open any terminal if we get here
                // so jump out of the function
                return;
            }
        }

        var app_info = AppInfo.create_from_commandline (
            app_info_commandline,
            null,
            AppInfoCreateFlags.NONE
        );

        if (app_info != null) {
            app_info.launch (null, Gdk.Screen.get_default ().get_display ().get_app_launch_context ());
        }
    }
}



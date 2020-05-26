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
    XSERVER,
    COMPOSITOR
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
                var xenv_vars = new HashTable<string, string> (str_hash, str_equal);
                xenv_vars.set("$INSTANCE", instance.display_name);

                int xenv_display_var;
                try {
                    xenv_display_var = LXD.count_files_in_path ("/tmp/.X11-unix");
                } catch (Error e) {
                    warning (e.message);
                    xenv_display_var = Random.int_range(50,99);
                }
                xenv_vars.set("$DISPLAY", @"$xenv_display_var");

                var home_dir_path = Environ.get_variable (Environ.@get (), "HOME");
                var work_dir_path = home_dir_path + LXD.apply_vars_to_string ("/.cache/com.github.marbetschar.tins/$INSTANCE", xenv_vars);

                var work_dir = File.new_for_path (work_dir_path);
                if (!work_dir.query_exists ()) {
                    work_dir.make_directory_with_parents ();
                }

                var work_share_dir = File.new_for_path (work_dir.get_path () + "/share");
                if (!work_share_dir.query_exists ()) {
                    work_share_dir.make_directory_with_parents ();
                }

                string[] xenvp = {};
                xenvp = Environ.set_variable (xenvp, "DISPLAY", LXD.apply_vars_to_string (":$DISPLAY", xenv_vars), true);
                xenvp = Environ.set_variable (xenvp, "XAUTHORITY", Environ.get_variable (Environ.@get (), "XAUTHORITY"), true);
                xenvp = Environ.set_variable (xenvp, "XSOCKET", LXD.apply_vars_to_string ("/tmp/.X11-unix/X$DISPLAY", xenv_vars), true);
                xenvp = Environ.set_variable (xenvp, "WAYLAND_DISPLAY", LXD.apply_vars_to_string ("wayland-$DISPLAY", xenv_vars), true);
                xenvp = Environ.set_variable (xenvp, "XDG_RUNTIME_DIR", LXD.apply_vars_to_string ("/run/user/$UID", xenv_vars), true);

                var compositor_config_file = File.new_for_path (work_dir_path + "/weston.ini");

                string[] compositor_config = {
                    "[core]",
                    "shell=desktop-shell.so",
                    "backend=x11-backend.so",
                    "xwayland=false",
                    "idle-time=0",
                    "",
                    "[xwayland]",
                    "path=/usr/bin/Xwayland",
                    "",
                    "[shell]",
                    "panel-location=none",
                    "panel-position=none",
                    "locking=false",
                    "background-color=0xff002244",
                    "animation=fade",
                    "startup-animation=fade",
                    "",
                    "[keyboard]",
                    "",
                    "[output]",
                    LXD.apply_vars_to_string ("name=X$DISPLAY", xenv_vars),
                    "mode=1024x768",
                    "scale=1",
                    "transform=normal"
                };

                if (compositor_config_file.query_exists ()) {
                    compositor_config_file.@delete ();
                }

                var compositor_config_file_stream = compositor_config_file.create (FileCreateFlags.REPLACE_DESTINATION, null);
                var compositor_config_data_stream = new DataOutputStream (compositor_config_file_stream);
                compositor_config_data_stream.put_string (string.joinv ("\n", compositor_config) + "\n");

                string[] compositor_argv = {
                    "/usr/bin/weston",
                    LXD.apply_vars_to_string ("--socket=wayland-$DISPLAY", xenv_vars),
                    @"--config=$(compositor_config_file.get_path())"
                };

                string[] xserver_argv = {
                    "/usr/bin/Xwayland",
                    LXD.apply_vars_to_string (":$DISPLAY", xenv_vars),
                    "-retro",
                    "+extension", "RANDR",
                    "+extension", "RENDER",
                    "+extension", "GLX",
                    "+extension", "XVideo",
                    "+extension", "DOUBLE-BUFFER",
                    "+extension", "SECURITY",
                    "+extension", "DAMAGE",
                    "+extension", "X-Resource",
                    "-extension", "XINERAMA", "-xinerama",
                    "-extension", "MIT-SHM",
                    "+extension", "Composite",
                    "-extension", "XTEST", "-tst",
                    "-dpms",
                    "-s", "off",
                    "-auth", work_dir.get_path () + "Xauthority.server",
                    "-nolisten", "tcp",
                    "-dpi", "96"
                };

                debug (LXD.apply_vars_to_string("Environment [DISPLAY=:$DISPLAY, WAYLAND_DISPLAY=wayland-$DISPLAY]:\n\t", xenv_vars) +
                    string.joinv("\n\t", xenvp)
                );

                var process_spawn_flags = SpawnFlags.SEARCH_PATH_FROM_ENVP;

                var stop_operation = Application.lxd_client.stop_instance (instance.name);
                try {
                    Application.lxd_client.wait_operation (stop_operation.id);
                } catch (Error e) {
                    warning (e.message);
                }

                var template = LXD.Instance.new_from_template_uri ("resource:///com/github/marbetschar/tins/lxd/instances/tins-x11.json", xenv_vars);
                template.name = instance.name;
                Application.lxd_client.update_instance (template);

                debug (LXD.apply_vars_to_string("Starting Compositor [WAYLAND_DISPLAY=wayland-$DISPLAY]:\n\t",xenv_vars) +
                    string.joinv("\n\t", compositor_argv)
                );

                Pid compositor_pid;
                Process.spawn_async (work_dir.get_path (), compositor_argv, xenvp, process_spawn_flags, null, out compositor_pid);
                // ChildWatch.add (compositor_pid, (pid, status) => {
                //     Process.close_pid (pid);
                //     try {
                //         Process.check_exit_status (status);
                //         debug (LXD.apply_vars_to_string("Closed Compositor [WAYLAND_DISPLAY=wayland-$DISPLAY].", xenv_vars));
                //     } catch (Error e) {
                //         critical (LXD.apply_vars_to_string("Error Compositor [WAYLAND_DISPLAY=wayland-$DISPLAY]:", xenv_vars) + e.message);
                //     }
                // });

                debug (LXD.apply_vars_to_string("Starting X server [DISPLAY=:$DISPLAY]:\n\t", xenv_vars) +
                    string.joinv("\n\t", xserver_argv)
                );

                Pid xserver_pid;
                Process.spawn_async (work_dir.get_path (), xserver_argv, xenvp, process_spawn_flags, null, out xserver_pid);
                // ChildWatch.add (xserver_pid, (pid, status) => {
                //     Process.close_pid (pid);
                //     try {
                //         Process.check_exit_status (status);
                //         debug (LXD.apply_vars_to_string("Closed X server [DISPLAY=:$DISPLAY].", xenv_vars));
                //     } catch (Error e) {
                //         critical (LXD.apply_vars_to_string("Error X server [DISPLAY=:$DISPLAY]:", xenv_vars) + e.message);
                //     }
                // });

                var start_operation = Application.lxd_client.start_instance (instance.name);
                try {
                    Application.lxd_client.wait_operation (start_operation.id);
                } catch (Error e) {
                    warning (e.message);
                }

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



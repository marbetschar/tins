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
    MCOOKIE,
    XAUTH,
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
                critical (e.message);

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
                    critical (e.message);

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
                string[] host_envp = Environ.@get ();

                int host_xserver_envp_display_number;
                try {
                    host_xserver_envp_display_number = LXD.count_files_in_path ("/tmp/.X11-unix", "X[0-9]+");
                } catch (Error e) {
                    warning (e.message);
                    host_xserver_envp_display_number = Random.int_range(50,99);
                }

                int host_compositor_envp_display_number;
                try {
                    host_compositor_envp_display_number = LXD.count_files_in_path (Environ.get_variable (host_envp, "XDG_RUNTIME_DIR"), "wayland-[0-9]+");
                } catch (Error e) {
                    warning (e.message);
                    host_compositor_envp_display_number = Random.int_range(50,99);
                }

                var home_dir_path = Environ.get_variable (host_envp, "HOME");
                var work_dir_path = home_dir_path + @"/.cache/com.github.marbetschar.tins/$(instance.name)";

                var work_dir = File.new_for_path (work_dir_path);
                if (!work_dir.query_exists ()) {
                    work_dir.make_directory_with_parents ();
                }

                var xauth_cookie_file = File.new_for_path (work_dir_path + "/.Xauthority");

                // Create X auth cookie for secure authentication:
                string mcookie_stdout, mcookie_stderr;
                int mcookie_exit_status;

                Process.spawn_command_line_sync (
                    "mcookie",
                    out mcookie_stdout,
                    out mcookie_stderr,
                    out mcookie_exit_status
                );

                if (mcookie_exit_status != 0) {
                    throw new TinsError.MCOOKIE (mcookie_stderr);
                }

                var xauth_command_line = @"xauth -v -i -f '$(xauth_cookie_file.get_path())' add :$host_xserver_envp_display_number . '$mcookie_stdout'";
                string xauth_stdout, xauth_stderr;
                int xauth_exit_status;

                Process.spawn_command_line_sync (
                    xauth_command_line,
                    out xauth_stdout,
                    out xauth_stderr,
                    out xauth_exit_status
                );

                if (xauth_exit_status != 0) {
                    throw new TinsError.XAUTH (xauth_stderr + "\n" + _("Command failed:") + " " + xauth_command_line);
                }

                xauth_command_line = @"xauth -i -f '$(xauth_cookie_file.get_path())' nlist";
                Process.spawn_command_line_sync (
                    xauth_command_line,
                    out xauth_stdout,
                    out xauth_stderr,
                    out xauth_exit_status
                );

                if (xauth_exit_status != 0) {
                    throw new TinsError.XAUTH (xauth_stderr + "\n" + _("Command failed:") + " " + xauth_command_line);
                }

                var xauth_cookie_content = xauth_stdout;
                try {
                    // There is some network specific information in the first 4 bytes of the cookie.
                    // You can replace them with ffff to allow the cookie for other networks.
                    var xauth_cookie_regex = new Regex ("^....");
                    xauth_cookie_content = xauth_cookie_regex.replace_literal (xauth_cookie_content, -1, 0, "ffff");
                } catch (Error e) {
                    warning (e.message);
                }

                FileIOStream xauth_cookie_tmp_file_streams;
                var xauth_cookie_tmp_file = File.new_tmp ("xauth-XXXXXX.cookie", out xauth_cookie_tmp_file_streams);
                DataOutputStream xauth_cookie_tmp_file_out_stream = new DataOutputStream (xauth_cookie_tmp_file_streams.output_stream);
                xauth_cookie_tmp_file_out_stream.put_string (xauth_cookie_content);

                xauth_command_line = @"xauth -v -i -f '$(xauth_cookie_file.get_path())' nmerge '$(xauth_cookie_tmp_file.get_path())'";
                Process.spawn_command_line_sync (
                    xauth_command_line,
                    out xauth_stdout,
                    out xauth_stderr,
                    out xauth_exit_status
                );

                if (xauth_exit_status != 0) {
                    throw new TinsError.XAUTH (xauth_stderr + "\n" + _("Command failed:") + " " + xauth_command_line);
                }

                try {
                    if (xauth_cookie_tmp_file.query_exists ()) {
                        xauth_cookie_tmp_file.@delete ();
                    }
                } catch (Error e) {
                    warning (e.message);
                }

                string[] host_xserver_envp = {};
                host_xserver_envp = Environ.set_variable (host_xserver_envp, "DISPLAY", @":$host_xserver_envp_display_number", true);
                host_xserver_envp = Environ.set_variable (host_xserver_envp, "WAYLAND_DISPLAY", @"wayland-$host_compositor_envp_display_number", true);
                host_xserver_envp = Environ.set_variable (host_xserver_envp, "XDG_RUNTIME_DIR", Environ.get_variable (host_envp, "XDG_RUNTIME_DIR"), true);

                string[] host_compositor_envp = {};
                host_compositor_envp = Environ.set_variable (host_compositor_envp, "DISPLAY", Environ.get_variable (host_envp, "DISPLAY"), true);
                host_compositor_envp = Environ.set_variable (host_compositor_envp, "WAYLAND_DISPLAY", @"wayland-$host_compositor_envp_display_number", true);
                host_compositor_envp = Environ.set_variable (host_compositor_envp, "XDG_RUNTIME_DIR", Environ.get_variable (host_envp, "XDG_RUNTIME_DIR"), true);

                // We need to set the user environment variables
                // manually, because they don't survive init
                // when we set them using LXD's config.environment.XYZ
                // @see: https://github.com/lxc/lxd/issues/910#issuecomment-125870419

                var instance_xenv_vars = new HashTable<string, string> (str_hash, str_equal);
                instance_xenv_vars.set("$DISPLAY", @"$host_xserver_envp_display_number");
                instance_xenv_vars.set("$XAUTHORITY", xauth_cookie_file.get_path ());

                var monitor = Gdk.Display.get_default ().get_primary_monitor ();
                var monitor_geometry = monitor.get_geometry();

                var host_compositor_config_file = File.new_for_path (work_dir_path + "/weston.ini");
                string[] host_compositor_config = {
                    "[core]",
                    "shell=desktop-shell.so",
                    "backend=x11-backend.so",
                    "idle-time=0",
                    "",
                    "[shell]",
                    "panel-location=none",
                    "panel-position=none",
                    "locking=false",
                    "background-color=0xff002244",
                    "animation=fade",
                    "startup-animation=fade",
                    "",
                    "[output]",
                    @"name=X$host_xserver_envp_display_number",
                    @"mode=$(monitor_geometry.width - 25)x$(monitor_geometry.height - 75)",
                    @"scale=$(monitor.scale_factor)"
                };

                if (host_compositor_config_file.query_exists ()) {
                    host_compositor_config_file.@delete ();
                }

                var host_compositor_config_file_stream = host_compositor_config_file.create (FileCreateFlags.REPLACE_DESTINATION, null);
                var host_compositor_config_data_stream = new DataOutputStream (host_compositor_config_file_stream);
                host_compositor_config_data_stream.put_string (string.joinv ("\n", host_compositor_config) + "\n");

                string[] host_compositor_argv = {
                    "/usr/bin/weston",
                    @"--socket=wayland-$host_compositor_envp_display_number",
                    @"--config=$(host_compositor_config_file.get_path())"
                };

                string[] host_xserver_argv = {
                    "/usr/bin/Xwayland",
                    Environ.get_variable (host_xserver_envp, "DISPLAY"),
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
                    "+extension", "MIT-SHM",
                    "+extension", "Composite",
                    "-extension", "XTEST", "-tst",
                    "-dpms",
                    "-s", "off",
                    "-auth", xauth_cookie_file.get_path (),
                    "-nolisten", "tcp",
                    "-dpi", "%i".printf (monitor_geometry.width / (monitor.width_mm / 26))
                };

                var host_process_spawn_flags = SpawnFlags.SEARCH_PATH_FROM_ENVP;

                debug ("Environment Compositor:\n\t" + string.joinv("\n\t", host_compositor_envp));
                debug (@"Starting Compositor [$(Environ.get_variable (host_compositor_envp, "WAYLAND_DISPLAY"))]:\n\t" + string.joinv("\n\t", host_compositor_argv));

                Pid host_compositor_pid;
                Process.spawn_async (work_dir.get_path (), host_compositor_argv, host_compositor_envp, host_process_spawn_flags, null, out host_compositor_pid);
                // ChildWatch.add (compositor_pid, (pid, status) => {
                //     Process.close_pid (pid);
                //     try {
                //         Process.check_exit_status (status);
                //         debug (@"Closed Compositor [$(Environ.get_variable (compositor_envp, "WAYLAND_DISPLAY"))].");
                //     } catch (Error e) {
                //         critical (@"Error Compositor [$(Environ.get_variable (compositor_envp, "WAYLAND_DISPLAY")):" + e.message);
                //     }
                // });

                // TODO: We need to use something better than just sleep here.
                Thread.usleep (1000000);

                debug ("Environment X server:\n\t" + string.joinv("\n\t", host_xserver_envp));
                debug (@"Starting X server [$(Environ.get_variable (host_xserver_envp, "DISPLAY"))]:\n\t" + string.joinv("\n\t", host_xserver_argv));

                Pid host_xserver_pid;
                Process.spawn_async (work_dir.get_path (), host_xserver_argv, host_xserver_envp, host_process_spawn_flags, null, out host_xserver_pid);
                // ChildWatch.add (xserver_pid, (pid, status) => {
                //     Process.close_pid (pid);
                //     try {
                //         Process.check_exit_status (status);
                //         debug (@"Closed X server [$(Environ.get_variable (xserver_envp, "DISPLAY"))].");
                //     } catch (Error e) {
                //         critical (@"Error X server [$(Environ.get_variable (xserver_envp, "DISPLAY"))]:" + e.message);
                //     }
                // });

                var stop_operation = Application.lxd_client.stop_instance (instance.name);
                try {
                    Application.lxd_client.wait_operation (stop_operation.id);
                } catch (Error e) {
                    warning (e.message);
                }

                var template = LXD.Instance.new_from_template_uri ("resource:///com/github/marbetschar/tins/lxd/instances/tins-x11.json", instance_xenv_vars);
                template.name = instance.name;
                Application.lxd_client.update_instance (template);

                var start_operation = Application.lxd_client.start_instance (instance.name);
                try {
                    Application.lxd_client.wait_operation (start_operation.id);
                } catch (Error e) {
                    warning (e.message);
                }

                var instance_x11_profile_file_content = LXD.read_template_from_uri ("resource:///com/github/marbetschar/tins/lxd/instances/tins-x11-profile.sh", instance_xenv_vars);
                Application.lxd_client.upload_file_content_instance (instance.name, "/etc/profile.d/99-tins-x11-profile.sh", instance_x11_profile_file_content);

                Application.lxd_client.upload_file_instance (instance.name, LXD.apply_vars_to_string ("/home/$USER/.Xauthority", instance_xenv_vars), xauth_cookie_file);

                // start desktop environment if known:
                if (instance.config != null) {
                    var variant = instance.config.get("image.variant");

                    string? startx_command = null;
                    if (variant != null) {
                        switch (variant.down ()) {
                            case "xfce":
                                startx_command = "startxfce4";
                                break;
                        }
                    }

                    if (startx_command != null) {
                        var startx_exec = new LXD.InstanceExec ();
                        startx_exec.command = new GenericArray<string> ();
                        startx_exec.command.add("su");
                        startx_exec.command.add("--login");
                        startx_exec.command.add(LXD.apply_vars_to_string ("$USER", instance_xenv_vars));
                        startx_exec.command.add("--command");
                        startx_exec.command.add (startx_command);

                        startx_exec.user = int.parse (LXD.get_uid ());
                        startx_exec.group = int.parse (LXD.get_gid ());

                        Application.lxd_client.exec_instance (instance.name, startx_exec);
                    }
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



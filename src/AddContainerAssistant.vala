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

[GtkTemplate (ui = "/com/github/marbetschar/tins/ui/AddContainerAssistant.glade")]
public class Tins.AddContainerAssistant : Gtk.Assistant {

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
    private Gtk.CheckButton desktop_enabled_checkbutton;

    [GtkChild]
    private Gtk.ComboBoxText desktop_combobox;

    [GtkChild]
    private Gtk.Label progress_title_label;

    [GtkChild]
    private Gtk.Label progress_description_label;

    [GtkChild]
    private Gtk.Label progress_state_label;

    [GtkChild]
    private Gtk.Stack progress_image_stack;

    [GtkChild]
    private Gtk.Image progress_error_image;

    [GtkChild]
    private Gtk.Stack progress_info_stack;

    [GtkChild]
    private Gtk.Label progress_error_label;

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
    private void on_changed_image (Gtk.Widget source) {
        desktop_combobox.remove_all ();
        desktop_combobox.append_text (_("other"));

        var os_key = all_os_keys.nth_data (operating_system_combobox.active);
        var os_images = Application.lxd_image_store.data.get (os_key);

        if (os_images != null) {
            var os_image = os_images.get (image_combobox.active < 0 ? 0 : image_combobox.active);

            if (os_image.desktops != null) {
                for(var i = 0; i < os_image.desktops.length; i++) {
                    var desktop = os_image.desktops.get(i);
                    desktop_combobox.append_text (_(desktop));
                }
            }
        }
        desktop_combobox.active = 0;

        validate_current_page ();
    }

    [GtkCallback]
    private void on_toggled_desktop_enable (Gtk.Widget source) {
        var toggle_button = source as Gtk.ToggleButton;
        desktop_combobox.sensitive = toggle_button.active;
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
        set_current_page_complete (false);

        var os_key = all_os_keys.nth_data (operating_system_combobox.active);
        var all_os_images = Application.lxd_image_store.data.get (os_key);
        var os_image = all_os_images.get (image_combobox.active);

        var instance_source = new LXD.Instance.Source ();
        instance_source.source_type = "image";
        instance_source.mode = "pull";
        instance_source.server = Application.lxd_image_store.server;
        instance_source.alias = @"$(os_image.properties.os)/$(os_image.properties.release)/$(os_image.properties.architecture)/$(os_image.properties.variant)";

        var instance = new LXD.Instance ();
        instance.source = instance_source;

        instance.display_name = name_entry.text;
        instance.architecture = "x86_64";

        var profiles = new GenericArray<string> ();
        profiles.add ("default");
        profiles.add ("tins-default");
        if (desktop_enabled_checkbutton.active) {
            profiles.add ("tins-x11");

            if (os_image.desktops != null && desktop_combobox.active != 0) {
                var desktop_name = os_image.desktops.get(desktop_combobox.active - 1);
                var desktop_profile_name = @"tins-x11-$(os_image.properties.os)-$(desktop_name)";

                try {
                    var desktop_profile = Application.lxd_client.get_profile (desktop_profile_name);

                    if (desktop_profile != null) {
                        profiles.add (desktop_profile_name);
                    }

                } catch (Error e) {
                    warning (e.message);
                }
            }
        }
        instance.profiles = profiles;

        try {
            var add_operation = Application.lxd_client.add_instance (instance);
            wait_operation.begin (add_operation, (obj, res) => {
                try {
                    add_operation = wait_operation.end (res);

                    if (add_operation.status_code < 300) {
                        try {
                            var start_operation = Application.lxd_client.start_instance (instance.name);
                            wait_operation.begin (start_operation, (obj, res) => {
                                try {
                                    start_operation = wait_operation.end (res);

                                    if (start_operation.status_code < 300) {
                                        try {
                                            var exec = new LXD.InstanceExec ();

                                            // run as root
                                            exec.user = 0;
                                            exec.group = 0;

                                            // wait until done
                                            exec.interactive = false;
                                            exec.record_output = true;

                                            // execute command
                                            exec.command = new GenericArray<string> ();
                                            exec.command.add ("cloud-init");
                                            exec.command.add ("status");
                                            exec.command.add ("--wait");

                                            var init_operation = Application.lxd_client.exec_instance (instance.name, exec);
                                            wait_operation.begin (init_operation, (obj, res) => {
                                                try {
                                                    init_operation = wait_operation.end (res);

                                                    if (init_operation.status_code < 300) {

                                                        if (init_operation.metadata != null && init_operation.metadata.return != null && init_operation.metadata.return != "0") {
                                                            set_error_message (_(@"Initial configuration using cloud-init failed. Execute the following command for more details:\n\n\tlxc exec $(instance.name) -- cat /var/log/cloud-init-output.log"));
                                                        } else {
                                                            close ();
                                                        }

                                                    } else {
                                                        on_operation_error (init_operation);
                                                    }

                                                } catch (Error e) {
                                                    on_error (e);
                                                }
                                            });

                                        } catch (Error e) {
                                            on_error (e);
                                        }

                                    } else {
                                        on_operation_error (start_operation);
                                    }

                                } catch (Error e) {
                                    on_error (e);
                                }
                            });

                        } catch (Error e) {
                            on_error (e);
                        }

                    } else {
                        on_operation_error (add_operation);
                    }

                } catch (Error e) {
                    on_error (e);
                }
            });

        } catch (Error e) {
            on_error (e);
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

    private async LXD.Operation wait_operation (LXD.Operation operation) throws Error {
        SourceFunc callback = wait_operation.callback;
        LXD.Operation[] output = { operation };

        ThreadFunc<bool> wait = () => {
            var wait_operation = output[0];
            var error_count = 0;

            while (wait_operation != null && wait_operation.status_code < 200 && error_count < 5) {
                if (wait_operation.metadata != null && wait_operation.metadata.download_progress != null) {
                    progress_state_label.label = _("Downloading…") + " " + wait_operation.metadata.download_progress;
                } else {
                    progress_state_label.label = @"$(wait_operation.description)…";
                }
                Thread.usleep (1000000);

                try {
                    wait_operation = Application.lxd_client.get_operation (wait_operation.id);
                } catch (Error e) {
                    warning (e.message);
                    error_count++;
                }
            }

            output[0] = wait_operation;
            Idle.add((owned) callback);
            return true;
        };
        new Thread<bool>("wait-operation", wait);

        yield;
        return output[0];
    }

    private void on_error (Error e) {
        set_error_message (e.message);
    }

    private void on_operation_error (LXD.Operation operation) {
        set_error_message (@"$(operation.err) ($(operation.status_code)).");
    }

    private void set_error_message (string error_message) {
        progress_title_label.label = _("Error Creating Container");
        progress_description_label.label = _("There was an error setting up your container.");

        progress_image_stack.visible_child = progress_error_image;
        progress_info_stack.visible_child = progress_error_label;
        progress_error_label.label = error_message;
    }
}

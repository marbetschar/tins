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
    private Gtk.Label progress_label;

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
            var os_image = os_images.get (image_combobox.active);

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
        }
        instance.profiles = profiles;

        try {
            var operation = Application.lxd_client.add_instance (instance);
            progress_label.label = @"$(operation.description)…";

            Timeout.add_seconds (1, () => {
                try {
                    operation = Application.lxd_client.get_operation (operation.id);

                    if (operation.status_code < 200) {
                        if (operation.metadata != null && operation.metadata.download_progress != null) {
                            progress_label.label = _("Downloading…") + " " + operation.metadata.download_progress;
                        } else {
                            progress_label.label = @"$(operation.description)…";
                        }

                    } else {
                         if (operation.status_code < 300) {

                            try {
                                var start_operation = Application.lxd_client.start_instance (instance.name);

                                Timeout.add_seconds (3, () => {
                                    try {
                                        start_operation = Application.lxd_client.get_operation (start_operation.id);

                                        if (start_operation.status_code < 200) {
                                            progress_label.label = @"$(start_operation.description)…";

                                        } else {
                                            if (start_operation.status_code < 300) {
                                                close ();
                                            } else {
                                                on_operation_error (start_operation);
                                            }
                                            return Source.REMOVE;
                                        }

                                    } catch (Error e) {
                                        critical (e.message);
                                    }

                                    return Source.CONTINUE;
                                });

                            } catch (Error e) {
                                var error_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                                    _("Error"),
                                    _(e.message),
                                    "dialog-error",
                                    Gtk.ButtonsType.CLOSE
                                );
                                error_dialog.run ();
                                error_dialog.destroy ();
                                close ();
                            }

                        } else {
                            on_operation_error (operation);
                        }
                        return Source.REMOVE;
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

                return Source.CONTINUE;
            });

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
    }

    private void on_operation_error (LXD.Operation operation) {
        progress_image_stack.visible_child = progress_error_image;
        progress_info_stack.visible_child = progress_error_label;
        progress_error_label.label = @"$(operation.err) ($(operation.status_code)).";
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
}

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

[GtkTemplate (ui = "/com/github/marbetschar/tins/ui/WidgetsContainerListBoxRow.glade")]
public class Tins.Widgets.ContainerListBoxRow : Gtk.ListBoxRow {

    public LXD.Instance instance { get; set; }

    public signal void open_clicked (LXD.Instance instance);
    public signal void configure_clicked (LXD.Instance instance);
    public signal void toggle_enable (LXD.Instance instance, bool did_enable);

    [GtkChild]
    private ContainerLogoBox logo_box;

    [GtkChild]
    private Gtk.Label title_label;

    [GtkChild]
    private Gtk.Label description_label;

    [GtkChild]
    private Gtk.Stack button_stack;

    [GtkChild]
    private Gtk.Button configure_button;

    [GtkChild]
    private Gtk.Button open_button;

    [GtkChild]
    private Gtk.Stack open_button_stack;

    [GtkChild]
    private Gtk.Image open_button_terminal_image;

    [GtkChild]
    private Gtk.Image open_button_desktop_image;

    construct {
        logo_box.toggle_state.connect ((new_state) => {
            toggle_enable (instance, new_state == ContainerLogoBox.ENABLED);
        });
        notify["instance"].connect (update_request);
        update_request ();
    }

    private void update_request () {
        if (instance != null) {
            title_label.label = instance.display_name;

            var version = "";
            var instance_os = instance.config.get("image.os");

            if (instance_os != null) {
                logo_box.image_resource = resource_for_os (instance_os);

                if (instance_os.strip () != "") {
                    version += instance_os;
                }
            }

            if (instance.config.get("image.release") != null && instance.config.get("image.release").strip () != "") {
                version += (version.strip () == "" ? "" : " ") + instance.config.get("image.release");
            }

            if (version.strip () != "") {
                version += ", ";
            }

            switch (instance.status.up ()) {
                case "RUNNING":
                    logo_box.state = ContainerLogoBox.State.ENABLED;
                    description_label.label = version + _("running…");
                    button_stack.visible_child = open_button;
                    button_stack.sensitive = true;
                    break;

                case "STOPPED":
                    logo_box.state = ContainerLogoBox.State.DISABLED;
                    // button_stack.visible_child = configure_button;
                    button_stack.sensitive = false;
                    description_label.label = version + _("stopped.");
                    break;

                default:
                    break;
            }

            if (instance.profiles != null && instance.profiles.find_with_equal_func ("tins-x11", str_equal)) {
                open_button_stack.visible_child = open_button_desktop_image;
            } else {
                open_button_stack.visible_child = open_button_terminal_image;
            }

        } else {
            title_label.label = _("Unknown");
            logo_box.state = ContainerLogoBox.State.ENABLED;
            logo_box.image_resource = resource_for_os ("unknown");
            button_stack.sensitive = false;
            description_label.label = _("unknown");
            open_button_stack.visible_child = open_button_terminal_image;
        }
    }

    private string resource_for_os (string os) {
        if (os != null) {
            var os_down = os.down ();

            var file = File.new_for_uri (@"resource:///com/github/marbetschar/tins/os/$(os_down).svg");
            if (file.query_exists ()) {
                return @"/com/github/marbetschar/tins/os/$(os_down).svg";
            }
        }

        return "/com/github/marbetschar/tins/os/linux.svg";
    }

    [GtkCallback]
    private void on_open_button_clicked (Gtk.Widget source) {
        open_clicked (instance);
    }

    [GtkCallback]
    private void on_configure_button_clicked (Gtk.Widget source) {
        configure_clicked (instance);
    }
}



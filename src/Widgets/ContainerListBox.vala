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

    private static Gtk.CssProvider style_provider;

    static construct {
        style_provider = new Gtk.CssProvider ();
        style_provider.load_from_resource ("/com/github/marbetschar/boxes/styles/WidgetsContainerListBox.css");
    }


    private struct Container {
        public string name;
        public bool gui_enabled;
        public bool enabled;
        public OperatingSystem operating_system;
    }

    private enum OperatingSystem {
        UBUNTU,
        ELEMENTARY,
        CENTOS,
        FEDORA,
        LINUX
    }

    construct {
        selection_mode = Gtk.SelectionMode.SINGLE;
        get_style_context ().add_provider (style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        add (create_row (Container (){ name = "Ubuntu 18.04 LTS", operating_system = OperatingSystem.UBUNTU, gui_enabled = false, enabled = false }));
        add (create_row (Container (){ name = "CentOS v7", operating_system = OperatingSystem.CENTOS, gui_enabled = true, enabled = false }));
        add (create_row (Container (){ name = "elementary OS 6.0", operating_system = OperatingSystem.ELEMENTARY, gui_enabled = false, enabled = true }));
        add (create_row (Container (){ name = "Fedora v32", operating_system = OperatingSystem.FEDORA, gui_enabled = true, enabled = true }));
        add (create_row (Container (){ name = "Alpine Test", operating_system = OperatingSystem.LINUX, gui_enabled = true, enabled = true }));
    }

    private Gtk.ListBoxRow create_row (Container container) {
        var row = new ContainerListBoxRow ();
        row.title = container.name;
        row.enabled = container.enabled;
        row.gui_enabled = container.gui_enabled;
        row.image_resource = resource_for_operating_system (container.operating_system);
        row.get_style_context ().add_provider (style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        return row;
    }

    private string resource_for_operating_system (OperatingSystem operating_system) {
        switch (operating_system) {
            case OperatingSystem.UBUNTU:
                return "/com/github/marbetschar/boxes/os/ubuntu.svg";
            case OperatingSystem.ELEMENTARY:
                return "/com/github/marbetschar/boxes/os/elementary.svg";
            case OperatingSystem.CENTOS:
                return "/com/github/marbetschar/boxes/os/centos.svg";
            case OperatingSystem.FEDORA:
                return "/com/github/marbetschar/boxes/os/fedora.svg";
            default:
                return "/com/github/marbetschar/boxes/os/linux.svg";
        }
    }
}



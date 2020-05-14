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

namespace LXD {
    private unowned Posix.Passwd passwd;
    private string uid;
    private string gid;
    private string username;

    private unowned Posix.Passwd get_passwd () {
        if (passwd == null) {
            passwd = Posix.getpwuid (Posix.getuid ());
        }
        return passwd;
    }

    public string get_uid () {
        unowned Posix.Passwd passwd = get_passwd ();
        if (uid == null && passwd != null) {
            uid = "%zu".printf (passwd.pw_uid);
        }
        return uid;
    }

    public string? get_username () {
        unowned Posix.Passwd passwd = get_passwd ();
        if (username == null && passwd != null) {
            username = passwd.pw_name;
        }
        return username;
    }

    public string get_gid () {
        unowned Posix.Passwd passwd = get_passwd ();
        if (gid == null && passwd != null) {
            gid = "%zu".printf (passwd.pw_gid);
        }
        return gid;
    }

    public void apply_vars_to_hash_table (
        HashTable<string,string> template,
        HashTable<string, string> vars = new HashTable<string, string> (str_hash, str_equal)
    ) {
        if (template == null) {
            return;
        }
        vars_set_well_known (vars);

        template.get_keys ().foreach ((template_key) => {
            var template_val = template.get (template_key);

            if (template_val != null) {
                template.set(template_key, apply_vars_to_string(template_val, vars));
            }
        });
    }

    public string apply_vars_to_string (
        string template,
        HashTable<string, string> vars = new HashTable<string, string> (str_hash, str_equal)
    ) {
        if (template == null) {
            return template;
        }
        var new_template = template;
        vars_set_well_known (vars);

        vars.get_keys ().foreach ((var_key) => {
            new_template = new_template.replace (var_key, vars.get(var_key));
        });

        return new_template;
    }

    private void vars_set_well_known (HashTable<string, string> vars) {
        vars.set("$GID", get_gid ());
        vars.set("$UID", get_uid ());
        vars.set("$USER", get_username ());
    }

    public string? read_file_from_uri (string uri) throws Error {
        var file = File.new_for_uri (uri);

        if (file.query_exists ()) {
            var in_stream = new DataInputStream (file.read ());
            var builder = new StringBuilder ();

            string line;
            while ((line = in_stream.read_line ()) != null) {
                builder.append(line + "\n");
            }

            return builder.str;
        }
        return null;
    }

    public int count_files_in_path (string path) throws Error {
        Dir dir = Dir.open (path);
        string? name = null;

        int i = 0;
        while ((name = dir.read_name ()) != null) {
            i++;
        }
        return i;
    }
}

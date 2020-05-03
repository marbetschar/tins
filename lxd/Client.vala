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

public class LXD.Client {

    private string host = "lxd";
    private string version = "1.0";

    private SocketClient client;
    private SocketConnection connection;
    private TlsCertificate certificate;

    public Client () throws Error {
        client = new SocketClient ();
        connection = client.connect (new UnixSocketAddress ("/var/lib/lxd/unix.socket"));
    }

    public void test () {
        var http_response = http_request ("GET", @"/$version");
        debug (@"http_response: $http_response");
    }

    private HTTPResponse http_request (string method, string endpoint) throws Error {
        var message = "%s %s HTTP/1.1\r\nHost: %s\r\n\r\n".printf (
            method.up (),
            endpoint,
            host
        );

        connection.output_stream.write (message.data);
        var response = new DataInputStream (connection.input_stream);

        string[] response_header = {};
        StringBuilder response_body = new StringBuilder ();

        bool response_is_header = true;
        string current_response_line = "";
        string? previous_response_line = null;

        while ((current_response_line = response.read_line_utf8 ()) != null) {
            if (response_is_header) {
                if (current_response_line.strip () == "") {
                    response_is_header = false;
                } else {
                    response_header += current_response_line.strip ();
                }

            } else if (previous_response_line != null && previous_response_line.strip () == "" && current_response_line.strip () == "0") {
                break;

            } else {
                if (current_response_line.strip () != "117f") {
                    response_body.append_printf ("%s\n", current_response_line.strip ());
                }
            }

            previous_response_line = current_response_line;
        }

        return HTTPResponse () {
            header = response_header,
            body = response_body.str.strip ()
        };
    }

     private struct HTTPResponse {
        string[] header;
        string body;

        public string? to_string () {
            return body;
        }
    }
}

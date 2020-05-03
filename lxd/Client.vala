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

    public static const string PATH = ".config/lxc/";
    public static const string SNAP_ROOT = "~/snap/lxd/current/";
    public static const string APT_ROOT = "~/";
    public static const string CERT_FILE_NAME = "client.crt";
    public static const string KEY_FILE_NAME = "client.key";

    public static string CERT_ROOT_PATH;
    public static TlsCertificate DEFAULT_CERT;

    static construct {
        CERT_ROOT_PATH = APT_ROOT + PATH;

        try {
            DEFAULT_CERT = new TlsCertificate.from_files (
                CERT_ROOT_PATH + CERT_FILE_NAME,
                CERT_ROOT_PATH + KEY_FILE_NAME
            );
        } catch (Error e) {
            warning (e.message);
        }
    }

    private SocketClient client;
    private SocketConnection connection;
    private TlsCertificate certificate;

    public Client () throws Error {
        client = new SocketClient ();
        //client.tls = true;

        //connection = client.connect (new UnixSocketAddress ("/var/lib/lxd/unix.socket"), null);
        certificate = DEFAULT_CERT;

        //client.event.connect (on_client_event);
    }

    private void on_client_event (SocketClientEvent event, SocketConnectable connectable, IOStream? connection) {
        debug ("on_client_event");
        if (event != SocketClientEvent.TLS_HANDSHAKING) {
            return;
        }
        debug ("set_certificate");
        var tls_connection = connection as TlsConnection;
        tls_connection.certificate = certificate;
    }

    public async void test () {
        debug ("test request");

        var message = "GET /1.0/ HTTP/1.1\r\n";
        connection.output_stream.write (message.data);
        debug ("wrote request");

        var response = new DataInputStream (connection.input_stream);
        var status_line = response.read_line (null).strip ();
        debug (@"Received status line: $status_line");
    }


   /* var host = "www.google.com";

    try {
        // Resolve hostname to IP address
        var resolver = Resolver.get_default ();
        var addresses = resolver.lookup_by_name (host, null);
        var address = addresses.nth_data (0);
        print (@"Resolved $host to $address\n");

        // Connect
        var client = new SocketClient ();
        var conn = client.connect (new InetSocketAddress (address, 80));
        print (@"Connected to $host\n");

        // Send HTTP GET request
        var message = @"GET / HTTP/1.1\r\nHost: $host\r\n\r\n";
        conn.output_stream.write (message.data);
        print ("Wrote request\n");

        // Receive response
        var response = new DataInputStream (conn.input_stream);
        var status_line = response.read_line (null).strip ();
        print ("Received status line: %s\n", status_line);

    } catch (Error e) {
        stderr.printf ("%s\n", e.message);
    }*/
}

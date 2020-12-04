/**
* dplugin
*
* Represents a dplugin
*
* On initialization it connects over a UNIX domain socket
* to the server and then the plugin can be used whenver it
* needs to be (send and receive)
*/

module dnetd.dplugin;

import dnetd.dserver;
import std.socket;
import bmessage;

public final class DPlugin
{
    /* The associated server */
    private DServer server;

    /* The UNIX domaion socket path */
    private string unixDomainSocketPath;

    /**
    * Constructs a new DPugin associated with the
    * given server and with the intent to connect
    * to the UNIX domain socket at the path given
    */
    this(DServer server, string unixDomainSocketPath)
    {
        this.server = server;
        this.unixDomainSocketPath = unixDomainSocketPath;
    }

    /**
    * Opens a new session to the plugin server
    * then sends the data, awaits a reply, then
    * closes the session (connection)
    */
    public byte[] sendPlugin(byte[] data)
    {
        /* The response */
        byte[] response;

        /* The status */
        bool status;

        /* Open a connection to the plugin server */
        Socket socket = new Socket(AddressFamily.UNIX, SocketType.STREAM, ProtocolType.RAW);
        socket.connect(new UnixAddress(unixDomainSocketPath));

        /* Send the data */
        /* TODO: Error handling */
        status = sendMessage(socket, data);

        /* Encode the status in the reply */
        response ~= [status];

        /* If the send succeeded */
        if(status)
        {
            /* Get the reply */
            /* TODO: Error handling */
            byte[] reply;
            receiveMessage(socket, reply);

            /* Close the connetion to the plugin server */
            socket.close();

            /* Encode the response */
            response ~= reply;
        }

        return response;
    }



}
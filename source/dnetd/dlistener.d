module dnetd.dlistener;

import std.socket;
import dnetd.dserver;

public final class DListener
{
    /* Associated server */
    private DServer server;

    /* The socket */
    private Socket socket;

    /**
    * Creates new listener with the associated server
    * and listens on the given address
    */
    this(DServer server, AddressInfo addressInfo)
    {
        /* Set the server */
        this.server = server;
        
        // /* Get the Address */
        // Address address = addressInfo.address;


        /* TODO: Check AF_FAMILY (can only be INET,INET6,UNIX) */
        /* TODO: Check SocketType (can only be STREAM) */
        /* TODO: Check Protocol, can only be RAW (assuming UNIX) or TCP */
        /* address.addressFamily, addressInfo.type, addressInfo.protocol */

        /* Create the Socket and bind it */
        socket = new Socket(addressInfo);
    }
}
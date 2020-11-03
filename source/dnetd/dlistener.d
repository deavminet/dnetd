module dnetd.dlistener;

import std.socket;

public final class DListener
{
    /* The socket */
    private Socket socket;

    /**
    * Creates new listener with the associated server
    * and the given Add
    *
    */
    this(AddressInfo addressInfo)
    {
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
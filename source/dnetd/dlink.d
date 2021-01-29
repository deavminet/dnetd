module dnetd.dlink;

import dnetd.dconnection;
import core.sync.mutex : Mutex;
import std.stdio;
import std.conv;
import dnetd.dserver;
import dnetd.dconfig;
import std.socket : Address;
import core.thread : Thread;


/**
* Represents a server link
*
* Either used for inbound or outbound
*/
public final class DLink : Thread
{
    /* Associated server */
    private DServer server;

    /* The connection */
    private DConnection connection;

    /**
    * Links details
    */
    private string name;
    private Address address;

    /**
    * Constructs a DLink for an outbound peering
    */
    this(DServer server, string name, Address address)
    {
        /* Set the worker thread for outbound connections */
        super(&outboundWorker);

        /* Create an outbound connection */
        /* TODO: Fuuuuuuuuuuuuuuuuuuuck handling of shit here bababooey and not in dconnection.d as we would have done below */

        /* Initialize a new outbound connection */
        initializeOutboundConnection();
    }

    /**
    * Initializes a new outbound connection
    */
    private void initializeOutboundConnection()
    {
        /* Open a connection to the server */
        // connection = new DConnection();
    }

    private void outboundWorker()
    {
        /* TODO: Implement me */
        while(true)
        {

        }
    }


    /**
    * Constructs a DLink for an inbound peering
    */
    this(DServer server, string name, Address address, DConnection connection)
    {
        /* Save the server, name and address */

        /* Save the active connection */
        /* Save name and address */
        this(server, name, address);

        /* Save connection */
    }
}

public final class DMeyer
{
    /* Direct peers */
    private DLink[] links;
    private Mutex linksMutex;

    /* Associated server */
    private DServer server;

    this(DServer server, DLink[] links)
    {
        this.server = server;
        
        /* Initialize the locks */
        initLocks();

        /* Open a connection to the server */

        /* TODO: Open connections to all servers we are yet to open a connection to (check the `links` array) */
    }

    /* Initialize locks */
    private void initLocks()
    {
        linksMutex = new Mutex();
    }

    // /* Attach a direct peer */
    // public void attachDirectPeer(DConnection peer)
    // {
    //     /* TODO: Add to `directPeers` */
    //     linksMutex.lock();

    //     links ~= new DLink(peer);
    //     writeln("Attached direct peer: "~to!(string)(peer));

    //     linksMutex.unlock();
    // }

    /* Get a list of all servers we know of */


    // public DLink getLink(DConnection peer)
    // {
    //     DLink link;

    //     linksMutex.lock();

        

    //     linksMutex.unlock();

    //     return link;
    // }

}

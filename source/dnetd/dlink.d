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
* DLink
*
* Couples a DConneciton (direct peer)
* with information about what this link
* knows and can tell us
*/
public final class DLidnk
{
    /* The directly attached peer */
    private DConnection directPeer;

    /* Servers (by name) this server is aware of */
    private string[] knowledgeList;

    this(DConnection directPeer)
    {
        this.directPeer = directPeer;
    }

    /* Call this to update list */
    public void updateKB()
    {
        /* TODO: Ask DConneciton here for the servers he knows */
    }
}

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
    }


    /**
    * Constructs a DLink for an inbound peering
    */
    this(DServer server, string name, Address address, DConnection connection)
    {
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

    this(DServer server, DLinkConfig linkConfig)
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

module dnetd.dlink;

import dnetd.dconnection;
import core.sync.mutex : Mutex;
import std.stdio;
import std.conv;
import dnetd.dserver;
import dnetd.dconfig;
import std.socket : Address;
import core.thread : Thread;
import std.socket;
import gogga;
import core.thread;
import tristanable.encoding : DataMessage;
import bmessage : bSendMessage = sendMessage, bReceiveMessage = receiveMessage;

/**
* Link manager
*
* Given a set of original DLink objects, it will open connections to them
* It also facilitates DConnection making a call to `.addLink` here when an
* inbound peering request comes in
*/
public final class DLinkManager
{

    this(DServer server)
    {
        
    }

    /**
    * Goes through the DConnection[] array in DServer and returns
    * all connections that are SERVER connections
    */
    public DConnection[] getLinkedServers()
    {
        DConnection[] links;

        /* TODO: Implement me */


        return links;
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
    * Outbound utilities
    */
    private Socket outboundSocket;

    /**
    * Constructs a DLink for an outbound peering
    */
    this(DServer server, string name, Address address)
    {
        /* Set the worker thread for outbound connections */
        super(&outboundWorker);

        this.name = name;
        this.address = address;

        /* Create an outbound connection */
        /* TODO: Fuuuuuuuuuuuuuuuuuuuck handling of shit here bababooey and not in dconnection.d as we would have done below */

        
    }

    /**
    * Initializes a new outbound connection
    */
    private void initializeOutboundConnection()
    {
        /* Open a connection to the server */
        outboundSocket = new Socket(address.addressFamily, SocketType.STREAM, ProtocolType.TCP);

        gprintln(address);



        while(true)
        {
            try
            {
                outboundSocket.connect(address);
                break;
            }
            catch(SocketOSException)
            {
                gprintln("Could not link with server "~name~"!", DebugType.ERROR);
                Thread.sleep(dur!("seconds")(3));
            }
        }
        


        
    }

    private void outboundWorker()
    {
        /* Initialize a new outbound connection */
        initializeOutboundConnection();

        bool status = linkHandshake();

        /* TODO: Implement me */
        while(true)
        {

        }
    }

    /**
    * Performs the server LINK command and makes sure
    * the server accepts the linking and also that the
    * links name on our local server match up
    */
    private bool linkHandshake()
    {
        bool status = true;

        /* TODO: Send LINK (1) command */
        byte[] data;
        data ~= [1];

        /* TODO: Encode [serverNameLen, serverName] */
        string serverName = server.getGeneralConfig().getName();
        data ~= [cast(byte)serverName.length];
        data ~= serverName;

        /* Encode and send LINK command */     
        DataMessage message = new DataMessage(0, data);
        bSendMessage(outboundSocket, message.encode());

        /* TODO: Await an acknowledgement [status] */
        byte[] receivedResponseBytes;
        bReceiveMessage(outboundSocket, receivedResponseBytes);
        DataMessage receivedResponse = DataMessage.decode(receivedResponseBytes);

        ubyte[] dataReply = cast(ubyte[])receivedResponse.getData();

        /* TODO: 0 is good, 1 is bad */
        if(dataReply[0] == 0)
        {
            /* TODO: Get server name, makes sure it matches on in config file */

            
        }
        else if(dataReply[0] == 1)
        {
            /* TODO: Handle this case */
            gprintln("Server linking rejected", DebugType.ERROR);
            status = false;
        }
        else
        {
            /* TODO: Handle this case */
            status = false;
        }
        /* TODO: If 0, then expect following [nameLen, name] */


        return status;
    }


    override public string toString()
    {
        return "Server: "~name~", Address: "~to!(string)(address);
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

/* TODO: Remove this from here and put it in DServer */
public final class DMeyer
{
    /* Direct peers */
    private DLink[] outboundPeers;
    private Mutex linksMutex;

    /* Associated server */
    private DServer server;

    this(DServer server, DLink[] outboundPeers)
    {
        this.server = server;
        
        /* Initialize the locks */
        initLocks();

        /* Open a connection to the server */

        /* TODO: Open connections to all servers we are yet to open a connection to (check the `links` array) */


        this.outboundPeers = outboundPeers;
    }


    /* Initialize locks */
    private void initLocks()
    {
        linksMutex = new Mutex();
    }

    public DLink[] getOutboundLinks()
    {
        return outboundPeers;
    }
}

/**
* Initializes a new inbound connection that is to be used for linking
*/
void initializeLink(DServer server, DConnection newConnection)
{

}
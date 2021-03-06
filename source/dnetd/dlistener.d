module dnetd.dlistener;

import std.socket;
import dnetd.dserver;
import core.thread;
import dnetd.dconnection;
import gogga;
import std.conv : to;

public final class DListener : Thread
{
    /* Associated server */
    private DServer server;

    /* The socket */
    private Socket serverSocket;

    /**
    * Creates new listener with the associated server
    * and listens on the given address
    */
    this(DServer server, AddressInfo addressInfo)
    {
        super(&dequeueLoop);

        /* Set the server */
        this.server = server;

        // /* Get the Address */
        Address address = addressInfo.address;

    

        gprintln("DListener: Hello there I am a new listener "~to!(string)(addressInfo));



        /* TODO: Check AF_FAMILY (can only be INET,INET6,UNIX) */
        /* TODO: Check SocketType (can only be STREAM) */
        /* TODO: Check Protocol, can only be RAW (assuming UNIX) or TCP */
        /* address.addressFamily, addressInfo.type, addressInfo.protocol */

        /* Create the Socket and bind it */
        serverSocket = new Socket(addressInfo);
        serverSocket.bind(address);
        gprintln("New listener started with address "~to!(string)(addressInfo));

        /* Start the connection dequeue thread */
		//start();
    }

    private void dequeueLoop()
	{
        gprintln("Starting dequeue loop...");
        
		/* Start accepting-and-enqueuing connections */
		serverSocket.listen(0); /* TODO: Linux be lile, hehahahhahahah who gives one - I give zero */
		
		while(true)
		{
			/* Dequeue a connection */
            gprintln("Awaiting a connection...");
			Socket socket = serverSocket.accept();
            gprintln("Dequeued a socket");

			/* Spawn a connection handler */
			DConnection connection = new DConnection(server, socket);

			/* Add to the connection queue */
			server.addConnection(connection);
		}
	}
}
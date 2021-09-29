module dnetd.listener;

import core.thread;
import std.socket;
import dnetd.server;
import dnetd.connection;

/**
* Listener
*
* A listener represents a socket the handles incoming connections
* to the server and spawns client handlers for each client
* connection.
*/
public class Listener : Thread
{
    /* Server instance */
    public static __gshared Server server;

    /* Server's socket for inbound connections */
    private Socket servSocket;

    /**
    * Spawns a new listener on the following address
    */
    this(Address address)
    {
        super(&run);

        /* TODO: Throw exception is the Family is not INET or INET6 */
        if(address.addressFamily != AddressFamily.INET && address.addressFamily != AddressFamily.INET6)
        {
            /* TODO: Add here */
        }

        try
        {
            servSocket = new Socket(address.addressFamily, SocketType.STREAM, ProtocolType.TCP);
            servSocket.bind(address);
        }
        catch(SocketOSException e)
        {
            /* TODO: Throw exception here */
        }


    }

    private void run()
    {
        /* Start listening */
        servSocket.listen(0);

        while(true)
        {
            /* Accept a new connection */
            Socket clientSocket = servSocket.accept();

            /* Create a new Connection */
            Connection connection = new Connection(clientSocket);
        }
    }
}
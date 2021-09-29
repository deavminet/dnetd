module dnetd.connection;

import std.socket;
import dnetd.server;

/**
* Connection
*
* Represents a connection made by a client or server to
* one of the listeners
*/

public class Connection : Thread
{

    public static __gshared Server server;
    private Socket socket;

    /**
    * 
    */
    this(Socket clientSocket)
    {
        socket = clientSocket;
    }
}
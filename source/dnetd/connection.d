module dnetd.connection;

import std.socket;

/**
* Connection
*
* Represents a connection made by a client or server to
* one of the listeners
*/

public class Connection
{

    private Socket socket;

    /**
    * 
    */
    this(Socket clientSocket)
    {
        socket = clientSocket;
    }
}
module dnetd.connection;

import std.socket;
import dnetd.server;
import core.thread;

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
    * Creates a new handler for a client Connection
    */
    this(Socket clientSocket)
    {
        super(&run);
        socket = clientSocket;

        /* Add myself to the server's connection queue */
        server.addConnection(this);

        start();
    }

    private void run()
    {
        while(true)
        {
            /* TODO: Add handling here */
            /**
            * TODO
            *
            * Here we want to bformat receive, then get a tristanable tag
            * (for later replying), then get the remaining message (the
            * command) and pass that to `process(message, tag)`, it can
            * then reply by tristanable-tag encoding and bformat encoding
            * and send over the socket
            *
            * The `process` call must spawn a new thread to handle all of
            * that
            */
        }
    }
}
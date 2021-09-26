module listener;

import core.thread;
import std.socket;

/**
* Listener
*
* A listener represents a socket the handles incoming connections
* to the server and spawns client handlers for each client
* connection.
*/
public class Listener : Thread
{
    /**
    * Spawns a new listener on the following address
    */
    this(Address address)
    {
        
    }

    private void run()
    {
        while(true)
        {
            
        }
    }
}
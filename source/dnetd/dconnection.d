/**
* dconnection
*
* Client/server connection handler spawned
* by socket connection dequeue loop.
*
* Handles all interactions between
* the server and the specific client/server.
*/

module dnetd.dconnection;

import core.thread : Thread;
import std.socket : Socket;

public class DConnection : Thread
{
	/* The client's socket */
	private Socket socket;

	this(Socket socket)
	{
		/* Set the function to be called on thread start */
		super(&worker);

		/* Set the socket */
		this.socket = socket;

		/* Start the connection handler */
		start();
	}

	/**
	* Byte dequeue loop
	*/
	private void worker()
	{
		while(true)
		{
			
		}
	}
}

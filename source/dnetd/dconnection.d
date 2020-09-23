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
import bmessage;
import tristanable.encoding : DataMessage;


public class DConnection : Thread
{
	/**
	* Connection information
	*/
	private Socket socket;
	private bool hasAuthed;

	/* Reserved tag for push notifications */
	private long notificationTag = 0;

	this(Socket socket)
	{
		/* Set the function to be called on thread start */
		super(&worker);

		/* Set the socket */
		this.socket = socket;

		/* Initialize the tagging facility */
		initTagger();

		/* Start the connection handler */
		start();
	}

	/**
	* Initializes tristanable
	* TODO: Implemet me (also tristanable needs reserved tags first)
	*/
	private void initTagger()
	{
		
	}

	/**
	* Byte dequeue loop
	*/
	private void worker()
	{
		/* Received bytes (for bformat) */
		byte[] receivedBytes;

		/* Received message */
		DataMessage receivedMessage;

		while(true)
		{		
			/**
			* Block to receive a bformat message
			*
			* (Does decoding for bformat too)
			*/
			bool status = receiveMessage(socket, receivedBytes);

			/* TODO: Check status */

			/* Decode the tristanable message (tagged message) */
			receivedMessage = DataMessage.decode(receivedBytes);

			/* TODO: Tristanable needs reserved-tag support (client-side concern) */
		}
	}

	/**
	* Process the received message
	*/
	private void process(DataMessage message)
	{
		/* Get the tag */
		long tag = message.tag;

		/* Get the command byte */
		byte commandByte = message.data[0];

		/* If `auth` command (requires: unauthed) */
		if(commandByte == 0 && !hasAuthed)
		{
			/* Get the length of the username */
			byte usernameLength = message.data[1];

			/* Get the username and password */
			string username = cast(string)message.data[2..usernameLength];
			string password = cast(string)message.data[cast(ulong)2+usernameLength..message.data.length];
		}
		/* If `link` command (requires: unauthed) */
		else if(commandByte == 1 && !hasAuthed)
		{
			
		}
		/* TODO: Handle this case */
		else
		{
			/* TODO: Check plugins */
			bool isPlugin = false;

			if(isPlugin)
			{
				
			}
			else
			{
				
			}
		}
	}

	/**
	*
	*/
}

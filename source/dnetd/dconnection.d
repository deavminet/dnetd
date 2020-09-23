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
import core.sync.mutex : Mutex;
import dnetd.dserver : DServer;
import std.string : split;
import dnetd.dchannel : DChannel;

public class DConnection : Thread
{
	/**
	* Connection information
	*/
	private DServer server;
	private Socket socket;
	private bool hasAuthed;

	/* Write lock for socket */
	/* TODO: Forgot how bmessage works, might need, might not, if multipel calls
	* then yes, if single then no as it is based off (well glibc's write)
	* thread safe code
	*/
	private Mutex writeLock;
	
	/* Reserved tag for push notifications */
	private long notificationTag = 0;

	this(DServer server, Socket socket)
	{
		/* Set the function to be called on thread start */
		super(&worker);

		/* Set the associated server */
		this.server = server;

		/* Set the socket */
		this.socket = socket;

		/* Initialize locks */
		initLocks();

		/* Start the connection handler */
		start();
	}

	/**
	* Initializes mutexes
	*/
	private void initLocks()
	{
		/* Initialie the socket write lock */
		writeLock = new Mutex();
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

			/* Process the message */
			process(receivedMessage);

			/* TODO: Tristanable needs reserved-tag support (client-side concern) */
		}
	}

	/* TODO: add mutex for writing with message and funciton for doing so */

	/**
	* Write to socket
	*
	* Encodes the byte array as a tristanable tagged
	* message and then encodes that as a bformat
	* message
	*
	* Locks the writeLock mutex, sends it over the
	* socket to the client/server, and unlocks the
	* mutex
	*/
	private bool writeSocket(long tag, byte[] data)
	{
		/* Send status */
		bool status;

		/* Create the tagged message */
		DataMessage message = new DataMessage(tag, data);

		/* Lock the write mutex */
		writeLock.lock();

		/* Send the message */
		status  = sendMessage(socket, message.encode());

		/* Unlock the write mutex */
		writeLock.unlock();

		return status;
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

			/* Authenticate */
			bool status = authenticate(username, password);

			/* Encode the reply */
			byte[] reply = [status];

			/* TODO: Implement me, use return value */
			writeSocket(tag, reply);
		}
		/* If `link` command (requires: unauthed) */
		else if(commandByte == 1 && !hasAuthed)
		{
			
		}
		/* */
		else if(commandByte == 2 && !hasAuthed)
		{
			
		}
		/* If `join` command (requires: authed) */
		else if(commandByte == 3 && !hasAuthed)
		{
			/* Get the channel names */
			string channelList = cast(string)message.data[1..message.data.length];
			string[] channels = split(channelList, ",");

			/**
			* Loop through each channel, check if it
			* exists, if so join it, else create it
			* and then join it
			*/
			foreach(string channelName; channels)
			{
				/* Attempt to find the channel */
				DChannel channel = server.getChannelByName(channelName);

				/* Create the channel if it doesn't exist */
				if(channel is null)
				{
					/* TODO: Thread safety for name choice */
					channel = new DChannel(channelName);
				}

				/* Join the channel */
				channel.join(this);
			}
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
	* Authenticate
	*
	* Login as a user with the given credentials
	*/
	private bool authenticate(string username, string password)
	{
		/* TODO: Implement me */
		return true;
	}
}

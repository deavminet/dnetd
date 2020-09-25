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
import std.conv : to;

public class DConnection : Thread
{
	/* The connection type */
	public enum ConnectionType
	{
		CLIENT, SERVER
	}

	/**
	* Connection information
	*/
	private DServer server;
	private Socket socket;
	private bool hasAuthed;
	private ConnectionType connType;
	private string username;

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
			if(status)
			{
				/* Decode the tristanable message (tagged message) */
				receivedMessage = DataMessage.decode(receivedBytes);

				/* Process the message */
				process(receivedMessage);

				/* TODO: Tristanable needs reserved-tag support (client-side concern) */	
			}
			else
			{
				/* TODO: Error handling */
			}
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
	public bool writeSocket(long tag, byte[] data)
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
		/**
		* TODO: Client side will always do 1, because we don't have
		* multi-thread job processing, only need this to differentiate
		* between commands and async notifications
		*/
		long tag = message.tag;

		/* Get the command byte */
		byte commandByte = message.data[0];

		/* If `auth` command (requires: unauthed) */
		if(commandByte == 0 && !hasAuthed)
		{
			/* Get the length of the username */
			byte usernameLength = message.data[1];

			/* Get the username and password */
			string username = cast(string)message.data[2..cast(ulong)2+usernameLength];
			string password = cast(string)message.data[cast(ulong)2+usernameLength..message.data.length];

			/* Authenticate */
			bool status = authenticate(username, password);

			/* TODO: What to do on bad authetication? */

			/* Set the username */
			this.username = username;

			/* Set the type of this connection to `client` */
			connType = ConnectionType.CLIENT;
			hasAuthed = true;

			/* Encode the reply */
			byte[] reply = [status];

			/* TODO: Implement me, use return value */
			writeSocket(tag, reply);
		}
		/* If `link` command (requires: unauthed) */
		else if(commandByte == 1 && !hasAuthed)
		{
			/* TODO: Implement me later */


			/* Set the type of this connection to `server` */
			connType = ConnectionType.SERVER;
		}
		/* If `register` command (requires: unauthed, client) */
		else if(commandByte == 2 && !hasAuthed && connType == ConnectionType.CLIENT)
		{
			
		}
		/* If `join` command (requires: authed, client) */
		else if(commandByte == 3 && hasAuthed && connType == ConnectionType.CLIENT)
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
					
					server.addChannel(this, channel);
				}

				/* Join the channel */
				channel.join(this);
			}

			/* TODO: Do reply */
			/* Encode the reply */
			byte[] reply = [true];
			
			/* TODO: Implement me, use return value */
			writeSocket(tag, reply);
		}
		/* If `part` command (requires: authed, client) */
		else if(commandByte == 4 && hasAuthed && connType == ConnectionType.CLIENT)
		{
			/* Get the channel names */
			string channelList = cast(string)message.data[1..message.data.length];
			string[] channels = split(channelList, ",");

			/**
			* Loop through each channel, check if it
			* exists, if so leave it
			*/
			foreach(string channelName; channels)
			{
				/* Attempt to find the channel */
				DChannel channel = server.getChannelByName(channelName);

				/* Leave a channel the channel only if it exists */
				if(!(channel is null))
				{
					channel.leave(this);
				}
			}

			/* TODO: Do reply */
			/* Encode the reply */
			byte[] reply = [true];
			
			/* TODO: Implement me, use return value */
			writeSocket(tag, reply);
		}
		/* If `list` command (requires: authed, client) */
		else if(commandByte == 6 && hasAuthed && connType == ConnectionType.CLIENT)
		{
			/* Get all channels */
			DChannel[] channels = server.getChannels();

			/* Generate a list of channel names (CSV) */
			string channelList;
			for(ulong i = 0; i < channels.length; i++)
			{
				if(i == channels.length-1)
				{
					channelList ~= channels[i].getName();
				}
				else
				{
					channelList ~= channels[i].getName()~",";
				}
			}

			/* TODO: Reply */
			/* Encode the reply */
			byte[] reply = [true];
			reply ~= channelList;

			/* TODO: Implement me, use return value */
			writeSocket(tag, reply);
		}
		/* If `msg` command (requires: authed, client) */
		else if(commandByte == 7 && hasAuthed && connType == ConnectionType.CLIENT)
		{
			/* Status */
			bool status = true;

			/* Get the type of message */
			byte messageType = message.data[0];

			/* Get the channel/person name */
			string destination;
			ulong i = 0;
			while(message.data[1+i] != cast(byte)0)
			{
				destination ~= message.data[1+i];
				i++;
			}

			/* Get the message (offset from null-terminator, hence +1 at the end) */
			string msg = cast(string)message.data[1+i+1..message.data.length];

			/* If we are sending to a user */
			if(messageType == cast(byte)0)
			{
				/* TODO Implemet  me */
			}
			/* If we are sending to a channel */
			else if(messageType == cast(ubyte)1)
			{
				/* The channel wanting to send to */
				DChannel channel = server.getChannelByName(destination);

				/* If the channel exists */
				if(channel)
				{
					/* TODO Implemet  me */
					channel.sendMessage(this, msg);
				}
				/* If the channel does not exist */
				else
				{
					status = false;
				}
			}
			/* Unknown destination type */
			else
			{
				status = false;
			}

			
			
			/* TODO: Handling here, should we make the user wait? */

			/* Encode the reply */
			// byte[] reply = [status];
			// reply ~= channelList;
			
						/* TODO: Implement me, use return value */
					//	writeSocket(tag, reply);
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
				byte[] reply = [false];
				writeSocket(tag, reply);
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

	public string getUsername()
	{
		return username;
	}

	public override string toString()
	{
		string toStr = to!(string)(connType)~"hjhf";
		
		if(connType == ConnectionType.CLIENT)
		{
			toStr = toStr ~ getUsername();
		}
		else
		{
			/* TODO Implement me */
		}

		return toStr;
	}
}

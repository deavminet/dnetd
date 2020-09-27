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
import std.stdio : writeln;

public class DConnection : Thread
{
	/* The connection type */
	public enum ConnectionType
	{
		CLIENT, SERVER, UNSPEC
	}

	/* Command types */
	public enum Command
	{
		JOIN,
		PART,
		AUTH,
		LINK,
		REGISTER,
		LIST,
		MSG,
		UNKNOWN
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

		/* Set the default state */
		connType = ConnectionType.UNSPEC;

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

	private Command getCommand(byte commandByte)
	{
		Command command = Command.UNKNOWN;
		
		if(commandByte == cast(ulong)0)
		{
			command	= Command.AUTH;
		}
		else if(commandByte == cast(ulong)1)
		{
			command = Command.LINK;
		}
		else if(commandByte == cast(ulong)2)
		{
			command = Command.REGISTER;
		}
		else if(commandByte == cast(ulong)3)
		{
			command = Command.JOIN;
		}
		else if(commandByte == cast(ulong)4)
		{
			command = Command.PART;
		}
		else if(commandByte == cast(ulong)5)
		{
			command = Command.MSG;
		}
		else if(commandByte == cast(ulong)6)
		{
			command = Command.LIST;
		}
		else if(commandByte == cast(ulong)7)
		{
			command = Command.MSG;
		}



		return command;
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

		/* The reply */
		byte[] reply;

		/* Get the command */
		byte commandByte = message.data[0];
		Command command = getCommand(commandByte);
		writeln(to!(string)(this)~" ~> "~to!(string)(command));

		/* If `auth` command (requires: unauthed) */
		if(command == Command.AUTH && !hasAuthed)
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
			reply = [status];
		}
		/* If `link` command (requires: unauthed) */
		else if(command == Command.LINK && !hasAuthed)
		{
			/* TODO: Implement me later */


			/* Set the type of this connection to `server` */
			connType = ConnectionType.SERVER;
			hasAuthed = true;
		}
		/* If `register` command (requires: unauthed, client) */
		else if(command == Command.REGISTER && !hasAuthed && connType == ConnectionType.CLIENT)
		{
			
		}
		/* If `join` command (requires: authed, client) */
		else if(command == Command.JOIN && hasAuthed && connType == ConnectionType.CLIENT)
		{
			/* Get the channel names */
			string channelList = cast(string)message.data[1..message.data.length];
			string[] channels = split(channelList, ",");

			/**
			* Loop through each channel, check if it
			* exists, if so join it, else create it
			* and then join it
			*/
			bool isPresentInfo = false;
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
				isPresentInfo = channel.join(this);
			}

			/* TODO: Do reply */
			/* Encode the reply */
			reply = [isPresentInfo];
		}
		/* If `part` command (requires: authed, client) */
		else if(command == Command.PART && hasAuthed && connType == ConnectionType.CLIENT)
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
			reply = [true];
		}
		/* If `list` command (requires: authed, client) */
		else if(command == Command.LIST && hasAuthed && connType == ConnectionType.CLIENT)
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
			reply = [true];
			reply ~= channelList;
		}
		/* If `msg` command (requires: authed, client) */
		else if(command == Command.MSG && hasAuthed && connType == ConnectionType.CLIENT)
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

			/* Send status */
			bool sendStatus;

			/* If we are sending to a user */
			if(messageType == cast(byte)0)
			{
				/* Send the message to the user */
				sendStatus = sendUserMessage(destination, msg);
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
					sendStatus = channel.sendMessage(this, msg);
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
			/* TODO: */
			reply = [status];
		}
		/* If no matching built-in command was found */
		else
		{
			/* TODO: Check plugins */
			bool isPlugin = false;

			/* A matching plugin was found */
			if(isPlugin)
			{
				/* TODO: Implement me */
			}
			/* The command was invalid */
			else
			{
				/* Write error message */
				reply = [2];
			}
		}

		/* Write the response */
		writeSocket(tag, reply);
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

	/**
	* Send user a message
	*
	* Sends the provided user the specified message
	*/
	private bool sendUserMessage(string username, string message)
	{
		/* Find the user to send to */
		DConnection user = server.findUser(username);

		/* If the user was found */
		if(user)
		{
			/* Send the messge */
			/* TODO: Implement me */
			
			
			/* TODO: Return value should be based off message send success */
			return true;
		}
		/* If the user was not found */
		else
		{
			return false;
		}
	}

	public string getUsername()
	{
		return username;
	}

	public ConnectionType getConnectionType()
	{
		return connType;
	}

	public override string toString()
	{
		string toStr = "["~to!(string)(connType)~"]: ";
		
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

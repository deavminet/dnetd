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
import std.algorithm : reverse;

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
		MEMBER_COUNT,
		MEMBER_LIST,
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
			writeln("waiting");
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
				writeln("Error with receive: "~to!(string)(this));
				break;
			}
		}

		/* Clean up */
		cleanUp();
	}

	private void cleanUp()
	{
		writeln(to!(string)(this)~" Cleaning up connection...");

		/* Remove this user from all channels he is in */
		DChannel[] channels = server.getChannels();

		/* Loop through each channel */
		foreach(DChannel currentChannel; channels)
		{
			/* Check if you are a member of it */
			if(currentChannel.isMember(this))
			{
				/* Leave the channel */
				currentChannel.leave(this);
				writeln(to!(string)(this)~" Leaving '"~currentChannel.getName()~"'...");
			}
		}
		
		/* Remove this user from the connection queue */
		server.removeConnection(this);

		writeln(to!(string)(this)~" Connection cleaned up");
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

		writeln("writeSocket: mutex lock");
		/* Lock the write mutex */
		writeLock.lock();

		/* Send the message */
		writeln("writeSocket: Data: "~to!(string)(data)~" Tag: "~to!(string)(tag));
		status = sendMessage(socket, message.encode());

		/* Unlock the write mutex */
		writeLock.unlock();

		writeln("writeSocket: mutex unlock");

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
		else if(commandByte == cast(ulong)8)
		{
			command = Command.MEMBER_COUNT;
		}
		else if(commandByte == cast(ulong)9)
		{
			command = Command.MEMBER_LIST;
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
		writeln("tag:", tag);

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
				/**
				* Finds the channel, if it exists then it returns it,
				* if it does not exist then it will create it and then
				* return it
				*/
				DChannel channel = server.getChannel(this, channelName);

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
			byte messageType = message.data[1];

			/* Get the location length */
			byte locationLength = message.data[2];

			/* Get the channel/person name */
			string destination = cast(string)message.data[3..cast(ulong)3+locationLength];

			/* Get the message */
			string msg = cast(string)message.data[cast(ulong)3+locationLength..message.data.length];

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
		/* If `membercount` command (requires: authed, client) */
		else if(command == Command.MEMBER_COUNT && hasAuthed && connType == ConnectionType.CLIENT)
		{
			/* Status */
			bool status = true;

			/* Get the channel name */
			string channelName = cast(string)message.data[1..message.data.length];

			/* The memebr count */
			long memberCount;

			/* Get the member count */
			status = getMemberCount(channelName, memberCount);

			/* Encode the status */
			reply = [status];

			/* If there was no error fetching the member count */
			if(status)
			{
				/* Data bytes */
				byte[] numberBytes;
				numberBytes.length = 8;

				/* Encode the length (Big Endian) from Little Endian */
				numberBytes[0] = *((cast(byte*)&memberCount)+7);
				numberBytes[1] = *((cast(byte*)&memberCount)+6);
				numberBytes[2] = *((cast(byte*)&memberCount)+5);
				numberBytes[3] = *((cast(byte*)&memberCount)+4);
				numberBytes[4] = *((cast(byte*)&memberCount)+3);
				numberBytes[5] = *((cast(byte*)&memberCount)+2);
				numberBytes[6] = *((cast(byte*)&memberCount)+1);
				numberBytes[7] = *((cast(byte*)&memberCount)+0);

				/* Append the length */
				reply ~= numberBytes;
			}
		}
		/* If `memberlist` command (requires: authed, client) */
		else if(command == Command.MEMBER_LIST && hasAuthed && connType == ConnectionType.CLIENT)
		{
			/* Status */
			bool status = true;

			/* Get the channel name */
			string channelName = cast(string)message.data[1..message.data.length];

			/* Get the channel */
			DChannel channel = server.getChannelByName(channelName);

			/* Encode the status */
			reply ~= [channel !is null];

			/* If the channel exists */
			if(channel)
			{
				/* Get the list of members in the channel */
				DConnection[] members = channel.getMembers();

				/* Construct a CSV string of the members */
				string memberString;

				for(ulong i = 0; i < members.length; i++)
				{
					if(i == members.length-1)
					{
						memberString ~= members[i].getUsername();
					}
					else
					{
						memberString ~= members[i].getUsername()~",";
					}
				}

				/* Encode the string into the reply */
				reply ~= cast(byte[])memberString;
			}
			/* If the channel does not exist */
			else
			{
				status = false;
			}




			


			
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
	* Get member count
	*
	* Gets the member count of a given channel
	*/
	private bool getMemberCount(string channelName, ref long count)
	{
		/* Status of operation */
		bool status;

		/* The channel */
		DChannel channel = server.getChannelByName(channelName);
		
		/* Check if the channel exists */
		if(channel)
		{
			/* Get the channel count */
			count = channel.getMemberCount();
			
		
			status = true;
		}
		/* If the channel does not exist */
		else
		{
			status = false;
		}

		return status;
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

		writeln("sendUserMessage(): ", user);

		/* If the user was found */
		if(user)
		{
			/* The protocol data to send */
			byte[] protocolData;

			/* Set the sub-type (ntype=0) */
			protocolData ~= [0];

			/* Encode the sender's length */
			protocolData ~= [cast(byte)username.length];

			/* Encode the username */
			protocolData ~= cast(byte[])username;

			/* Encode the message */
			protocolData ~= cast(byte[])message;

			/* Send the messge */
			bool sendStatus = user.writeSocket(0, protocolData);

			return sendStatus;
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
		string toStr = "["~to!(string)(connType)~" (";
		toStr ~= socket.remoteAddress.toString();

	
		toStr ~= ")]: ";
		
		
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

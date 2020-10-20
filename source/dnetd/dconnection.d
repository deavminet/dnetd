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
		SERVER_INFO,
		MOTD,
		MEMBER_INFO,
		STATUS,
		CHAN_PROP,
		SET_PROP,


		/* User property commands */
		GET_USER_PROPS,
		GET_USER_PROP,
		SET_USER_PROP,
		DELETE_USER_PROP,


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
	private string currentStatus;

	/**
	* User property support
	*
	* `properties` -  the property store
	* `propertiesMutex` - the mutex
	*/
	private string[string] properties; /* TODO: New, replace old status mechanism */
	private Mutex propertiesLock;

	/* Write lock for socket */
	/* TODO: Forgot how bmessage works, might need, might not, if multipel calls
	* then yes, if single then no as it is based off (well glibc's write)
	* thread safe code
	*/
	private Mutex writeLock;

	/**
	* Mutex to provide safe access to the status message
	*/
	private Mutex statusMessageLock;
	
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

		/* Initialize status */
		currentStatus = "available,Hey there I'm using DNET!";

		/* Start the connection handler */
		start();
	}

	/**
	* Initializes mutexes
	*/
	private void initLocks()
	{
		/* Initialize the socket write lock */
		writeLock = new Mutex();

		/* Initialize the status message lock */
		statusMessageLock = new Mutex();

		/* Initialize the properties lock */
		propertiesLock = new Mutex();
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

	private Command getCommand(ubyte commandByte)
	{
		Command command = Command.UNKNOWN;
		
		if(commandByte == 0)
		{
			command	= Command.AUTH;
		}
		else if(commandByte == 1)
		{
			command = Command.LINK;
		}
		else if(commandByte == 2)
		{
			command = Command.REGISTER;
		}
		else if(commandByte == 3)
		{
			command = Command.JOIN;
		}
		else if(commandByte == 4)
		{
			command = Command.PART;
		}
		else if(commandByte == 5)
		{
			command = Command.MSG;
		}
		else if(commandByte == 6)
		{
			command = Command.LIST;
		}
		else if(commandByte == 7)
		{
			command = Command.MSG;
		}
		else if(commandByte == 8)
		{
			command = Command.MEMBER_COUNT;
		}
		else if(commandByte == 9)
		{
			command = Command.MEMBER_LIST;
		}
		else if(commandByte == 10)
		{
			command = Command.SERVER_INFO;
		}
		else if(commandByte == 11)
		{
			command = Command.MOTD;
		}
		else if(commandByte == 12)
		{
			command = Command.MEMBER_INFO;
		}
		else if(commandByte == 13)
		{
			command = Command.STATUS;
		}
		else if(commandByte == 14)
		{
			command = Command.CHAN_PROP;
		}
		else if(commandByte == 15)
		{
			command = Command.GET_USER_PROPS;
		}
		else if(commandByte == 16)
		{
			command = Command.GET_USER_PROP;
		}
		else if(commandByte == 17)
		{
			command = Command.SET_USER_PROP;
		}
		else if(commandByte == 18)
		{
			command = Command.DELETE_USER_PROP;
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
			ubyte usernameLength = message.data[1];

			/* Get the username and password */
			string username = cast(string)message.data[2..2+cast(uint)usernameLength];
			string password = cast(string)message.data[2+cast(uint)usernameLength..message.data.length];

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

			/* Check if this connection is a DLink'd one */
			//server.getMeyer().get


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
			ubyte messageType = message.data[1];

			/* Get the location length */
			ubyte locationLength = message.data[2];

			/* Get the channel/person name */
			string destination = cast(string)message.data[3..3+cast(uint)locationLength];

			/* Get the message */
			string msg = cast(string)message.data[3+cast(uint)locationLength..message.data.length];

			/* Send status */
			bool sendStatus;

			/* If we are sending to a user */
			if(messageType == 0)
			{
				/* Send the message to the user */
				sendStatus = sendUserMessage(destination, msg);
			}
			/* If we are sending to a channel */
			else if(messageType == 1)
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
		/* If `serverinfo` command (requires: authed, !unspec) */
		else if(command == Command.SERVER_INFO && hasAuthed && connType != ConnectionType.UNSPEC)
		{
			/* Status */
			bool status = true;

			/* Get the server info */
			string serverInfo = server.getServerInfo();

			/* Encode the reply */
			reply ~= [status];
			reply ~= serverInfo;
		}
		/* If `motd` command (requires: _nothing_) */
		else if(command == Command.MOTD)
		{
			/* Status */
			bool status = true;

			/* Get the message of the day */
			string motd = server.getConfig().getGeneral().getMotd();

			/* Encode the reply */
			reply ~= [status];
			reply ~= motd;
		}
		/* If `memberinfo` command (requires: authed, client) */
		else if(command == Command.MEMBER_INFO && hasAuthed && connType == ConnectionType.CLIENT)
		{
			/* Status */
			bool status = true;

			/* TODO: Implement me */
			string user = cast(string)message.data[1..message.data.length];

			/* TODO: fetch longontime, serveron, status */
			string logontime;
			string serveron;

			/* Encode the reply */
			reply ~= [status];
			reply ~= [cast(byte)logontime.length];
			reply ~= logontime;
			reply ~= [cast(byte)serveron.length];
			reply ~= serveron;
			reply ~= server.getStatusMessage(user);
		}
		/* If `status` command (requires: authed, client) */
		else if(command == Command.STATUS && hasAuthed && connType == ConnectionType.CLIENT)
		{
			/* Get the new status line */
			string statusMessage = cast(string)message.data[1..message.data.length];

			/* Set the new status message */
			setStatusMessage(statusMessage);

			/* Encode the reply */
			reply ~= [true];
		}

		/* If `get_user_props` (requires: authed, client) */
		else if(command == Command.GET_USER_PROPS && hasAuthed && connType == ConnectionType.CLIENT)
		{
			/* Get all properties */
			string[] propertyKeys = getProperties();

			/* Encode the status */
			reply ~= [true];

			/* Encode the keys */
			for(ulong i = 0; i < propertyKeys.length; i++)
			{
				/* The data to add to the reply */
				string replyData;

				if(i == propertyKeys.length-1)
				{
					replyData = propertyKeys[i];
				}
				else
				{
					replyData = propertyKeys[i]~",";
				}

				/* Encode the `replyData` */
				reply ~= replyData;
			}

			/* Encode the number of keys (TODO: FOr now you cannot have more than 255 keys) */
			reply ~= [cast(byte)propertyKeys.length];
		}
		/* If `get_user_prop` (requires: authed, client) */
		else if(command == Command.GET_USER_PROP && hasAuthed && connType == ConnectionType.CLIENT)
		{
			/* Get the <user>,<propertyName> */
			string[] dataLine = split(cast(string)message.data[1..message.data.length],",");

			/* Get the username */
			string username = dataLine[0];

			/* Get the proerty */
			string propertyName = dataLine[1];

			/* Determine if it is a valid property */
			bool status = server.isProperty(username, propertyName);

			/* Encode the status */
			reply ~= [status];

			/* Encode the property value if one exists */
			if(status)
			{
				/* Get the property value */
				string propertyValue = server.getProperty(username, propertyName);

				/* Encode the property value */
				reply ~= propertyValue;
			}
		}
		/* If `set_user_prop` (requires: authed, client) */
		else if(command == Command.SET_USER_PROP && hasAuthed && connType == ConnectionType.CLIENT)
		{

		}
		/* If `delete_user_prop` (requires: authed, client) */
		else if(command == Command.DELETE_USER_PROP && hasAuthed && connType == ConnectionType.CLIENT)
		{

		}
		




		/* TODO: `CHAN_PROP`, `SET_PROP` */
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

	/**
	* Set the status message
	*/
	private void setStatusMessage(string statusMessage)
	{
		/* Lock the status message mutex */
		statusMessageLock.lock();

		/* Set the status message */
		currentStatus = statusMessage;

		/* Unlock the statue message mutex */
		statusMessageLock.unlock();
	}

	/**
	* Returns the current status message
	*/
	public string getStatusMessage(string username)
	{
		/* The status message */
		string statusMessage;

		writeln("hfsjkhfjsdkhfdskj");

		/* Lock the status message mutex */
		statusMessageLock.lock();

		/* Get the status message */
		statusMessage = currentStatus;

		/* Unlock the statue message mutex */
		statusMessageLock.unlock();

		return statusMessage;
	}

	/**
	* Sets a property for this user
	*/
	public void setProperty(string propertyName, string propertyValue)
	{
		/* Lock the properties store */
		propertiesLock.lock();

		/* Set the property's value */
		properties[propertyName] = propertyValue;

		/* Unlock the properties store */
		propertiesLock.unlock();
	}

	/**
	* Determines whether or not the given property
	* exists
	*/
	public bool isProperty(string propertyName)
	{
		/**
		* Whether or not the given property is a property
		* of this user
		*/
		bool status;

		/* Lock the properties store */
		propertiesLock.lock();

		/* Check for the property's existence */
		status = cast(bool)(propertyName in properties);

		/* Unlock the properties store */
		propertiesLock.unlock();

		return status;
	}

	/**
	* Returns a property
	*/
	public string getProperty(string propertyName)
	{
		/* TODO: Error handling */
		return properties[propertyName];
	}

	/**
	* Returns a list of proerties
	*/
	public string[] getProperties()
	{
		return properties.keys();
	}

	/**
	* Deletes a given proerty
	*/
	public void deleteProperty(string propertyName)
	{
		/* TODO: Implement me */
		properties.remove(propertyName);
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

/**
* DServer
*
* Represents a server instance.
*
* Holds a list of DConnections,
* configuration parameters and
* more.
*/

module dnetd.dserver;

import core.thread : Thread;
import std.socket : Address, Socket, AddressFamily, SocketType, ProtocolType;
import dnetd.dconnection;
import dnetd.dchannel;
import std.string : cmp;
import core.sync.mutex : Mutex;
import std.stdio;
import std.conv : to;
import dnetd.dconfig;
import dnetd.dlink;
import dnetd.dlistener;
import gogga;

public class DServer : Thread
{
	/* Server configuration */
	private DConfig config;

	/**
	* Connection queue
	*/
	private DConnection[] connectionQueue;
	private Mutex connectionLock;

	/**
	* Channels
	*/
	private DChannel[] channels;
	private Mutex channelLock;

	/**
	* Meyer linking subsystem
	*/
	private DMeyer meyerSS;
	
	/**
	* The listeners attached to this server
	*/
	private DListener[] listeners;

	/* TODO: Implement new constructor */
	this(DConfig config)
	{
		/* Set the function to be called on thread start */
		super(&dequeueLoop);

		/* Set the server's config */
		this.config = config;
	
		/* Construct the listeners */
		initListeners(config.getGeneral().getAddresses());

		/* Initialize the server */
		init();

		/* Start the server */
		startServer();
	}

	/**
	* Given an array of Address(es) this will construct all
	* the corresponding listsners (DListener) and append them
	* to the array
	*/
	private void initListeners(Address[] listenAddresses)
	{
		gprintln("Constructing "~to!(string)(listenAddresses.length)~" listsners...");

		foreach(Address listenAddress; listenAddresses)
		{
			gprintln("Constructing listener for address '"~to!(string)(listenAddress)~"'");

			import std.socket : AddressInfo;
			AddressInfo addrInfo;

			/* Set the address (and port) to the current one along with address family */
			addrInfo.address = listenAddress;
			addrInfo.family = listenAddress.addressFamily;
		
			/* Set standard (it will always be TCP and in stream access mode) */
			addrInfo.protocol = ProtocolType.TCP;
			addrInfo.type = SocketType.STREAM;

			/* Construct the listener */
			listeners ~= new DListener(this, addrInfo);
			gprintln("Listener for '"~to!(string)(listenAddress)~"' constructed");
		}

		gprintln("Listener construction complete.");
	}

	public DConfig getConfig()
	{
		return config;
	}

	private void init()
	{
		/* Setup queues */
		initQueues();

		/* Setup locks */
		initLocks();
	}

	/**
	* Creates all needed queues
	* and their mutexes
	*/
	private void initQueues()
	{
		/* TODO: Implement me */
	}

	private void initLocks()
	{
		/* Initialize the connection lock */
		connectionLock = new Mutex();

		/* Initialize the channel lock */
		channelLock = new Mutex();
	}
	
	public DMeyer getMeyer()
	{
		return meyerSS;
	}

	private void startServer()
	{
		/* Initialize the Meyer linking sub-system */
		meyerSS = new DMeyer(this);

		/* Start the connection dequeue thread */
		start();
	}

	public void addChannel(DConnection causer, DChannel channel)
	{
		/* Lock the channels list */
		// channelLock.lock();

		channels ~= channel;

		/* TODO: Use causer */

		/* Unlock the channels list */
		// channelLock.unlock();
	}

	public void addConnection(DConnection connection)
	{
		/* Lock the connections list */
		connectionLock.lock();

		/* Add to the connection queue */
		connectionQueue ~= connection;
		gprintln("Added connection to queue "~to!(string)(connection));

		/* Unlock the connections list */
		connectionLock.unlock();
	}

	/* TODO Remove connection */
	public void removeConnection(DConnection connection)
	{
		/* Lock the connections list */
		connectionLock.lock();

		/* The new connection queue */
		DConnection[] connectionQueueNew;

		foreach(DConnection currentConnection; connectionQueue)
		{
			if(!(currentConnection is connection))
			{
				connectionQueueNew ~= currentConnection;
			}
		}

		/* Set this as the new queue */
		connectionQueue = connectionQueueNew;

		gprintln("Removed connection from queue "~to!(string)(connection));

		/* Unlock the connections list */
		connectionLock.unlock();
	}

	/* TODO: neew method */
	public DChannel getChannel(DConnection causer, string channelName)
	{
		DChannel channel = null;
		
		channelLock.lock();

		
		foreach(DChannel currentChannel; channels)
		{
			if(cmp(currentChannel.getName(), channelName) == 0)
			{
				channel = currentChannel;
				break;
			}
		}

		if(channel)
		{
			
		}
		else
		{
			channel = new DChannel(channelName);
								
								this.addChannel(causer, channel);
		}

		channelLock.unlock();


		return channel;
	}


	public DChannel getChannelByName(string channelName)
	{
		/* The channel */
		DChannel channel = null;
		
		/* Lock the channels list */
		channelLock.lock();

		foreach(DChannel currentChannel; channels)
		{
			if(cmp(currentChannel.getName(), channelName) == 0)
			{
				channel = currentChannel;
				break;
			}
		}

		/* Unlock the channels list */
		channelLock.unlock();

		return channel;
	}

	/**
	* Returns the DConnection with the matching
	* username, null if not found
	*/
	public DConnection findUser(string username)
	{
		/* The found Connection */
		DConnection foundConnection;

		/* Lock the connections list */
		connectionLock.lock();

		/* Find the user with the matching user name */
		foreach(DConnection connection; connectionQueue)
		{
			/* The connection must be a user (not unspec or server) */
			if(connection.getConnectionType() == DConnection.ConnectionType.CLIENT)
			{
				/* Match the username */
				if(cmp(connection.getUsername(), username) == 0)
				{
					foundConnection = connection;
				}
			}
		}

		/* Unlock the connections list */
		connectionLock.unlock();

		return foundConnection;
	}

	public bool channelExists(string channelName)
	{
		/* Whether or not it exists */
		bool exists;

		/* Get all channels */
		DChannel[] currentChannels = getChannels();

		foreach(DChannel currentChannel; currentChannels)
		{
			if(cmp(currentChannel.getName(), channelName) == 0)
			{
				exists = true;
				break;
			}
		}

		return exists;
	}

	public DChannel[] getChannels()
	{
		/* The current channels list */
		DChannel[] currentChannels;
		
		/* Lock the channels list */
		channelLock.lock();

		currentChannels = channels;

		/* Unlock the channels list */
		channelLock.unlock();
		
		return currentChannels;
	}

	public string getStatusMessage(string username)
	{
		/* Lock the connections list */
		connectionLock.lock();

		/* The matching connection */
		DConnection matchedConnection;

		/* Find the connection */
		foreach(DConnection connection; connectionQueue)
		{
			if(cmp(connection.getUsername(), username) == 0)
			{
				matchedConnection = connection;
				break;
			}
		}


		/* Unlock the connections list */
		connectionLock.unlock();

		return matchedConnection.getStatusMessage(username);
	}

	/**
	* Checks whether the given user has the given
	* property
	*/
	public bool isProperty(string username, string propertyName)
	{
		/* Whether or not the user has the given property */
		bool status;

		/* Lock the connections list */
		connectionLock.lock();

		/* The matching connection */
		DConnection matchedConnection;

		/* Find the connection */
		foreach(DConnection connection; connectionQueue)
		{
			if(cmp(connection.getUsername(), username) == 0)
			{
				matchedConnection = connection;
				break;
			}
		}

		/* Unlock the connections list */
		connectionLock.unlock();

		/* Check for the user's property */
		status = matchedConnection.isProperty(propertyName);

		return status;
	}

	/* TODO: All these functions can really be re-duced, why am I not using getConnection() */

	/**
	* Checks whether the given user has the given
	* property
	*/
	public string getProperty(string username, string propertyName)
	{
		/* The retrieved property value */
		string propertyValue;

		/* Lock the connections list */
		connectionLock.lock();

		/* The matching connection */
		DConnection matchedConnection;

		/* Find the connection */
		foreach(DConnection connection; connectionQueue)
		{
			if(cmp(connection.getUsername(), username) == 0)
			{
				matchedConnection = connection;
				break;
			}
		}

		/* Unlock the connections list */
		connectionLock.unlock();

		/* Check for the user's property */
		propertyValue = matchedConnection.getProperty(propertyName);

		return propertyValue;
	}

	/**
	* Set the property of the given user to the given value
	*/
	public void setProperty(string username, string propertyName, string propertyValue)
	{
		/* Lock the connections list */
		connectionLock.lock();

		/* The matching connection */
		DConnection matchedConnection;

		/* Find the connection */
		foreach(DConnection connection; connectionQueue)
		{
			if(cmp(connection.getUsername(), username) == 0)
			{
				matchedConnection = connection;
				break;
			}
		}

		/* Unlock the connections list */
		connectionLock.unlock();

		/* Set the property's value of the user */
		matchedConnection.setProperty(propertyName, propertyValue);
	}
	

	public string getServerInfo()
	{
		/* The server information */
		string serverInfo;

		/* TODO: Fetch serverName */
		/* TODO: Fetch networkName */
		/* TODO: Fetch userCount */
		/* TODO: Fetch channelCount */


		return serverInfo;
	}
}
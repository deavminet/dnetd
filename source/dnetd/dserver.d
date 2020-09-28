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

public class DServer : Thread
{
	/* The server's socket to bind, listen and accept connections from */
	private Socket serverSocket;

	/* Bind address */
	private Address sockAddress;


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
	
	this(Address sockAddress)
	{
		/* Set the function to be called on thread start */
		super(&dequeueLoop);
	
		/* Set the listening address */
		this.sockAddress = sockAddress;

		/* Initialize the server */
		init();

		/* Start the server */
		startServer();
	}

	private void init()
	{
		/* Setup socket */
		initNetwork();

		/* Setup queues */
		initQueues();

		/* Setup locks */
		initLocks();
	}

	/**
	* Creates the socket, binds it
	* to the given address
	*/
	private void initNetwork()
	{
		/* Create the socket */
		serverSocket = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);

		/* Bind the socket to the given address */
		serverSocket.bind(sockAddress);
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
	
	private void startServer()
	{
		/* Start the connection dequeue thread */
		start();
	}

	private void dequeueLoop()
	{
		/* Start accepting-and-enqueuing connections */
		serverSocket.listen(0); /* TODO: Linux be lile, hehahahhahahah who gives one - I give zero */
		
		while(true)
		{
			/* Dequeue a connection */
			Socket socket = serverSocket.accept();

			/* Spawn a connection handler */
			DConnection connection = new DConnection(this, socket);

			/* Add to the connection queue */
			addConnection(connection);
		}
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
		writeln("Added connection to queue "~to!(string)(connection));

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

		writeln("Removed connection from queue "~to!(string)(connection));

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
		/* Get all the current connections */
		DConnection[] connections = getConnections();

		/* Find the user with the matching user name */
		foreach(DConnection connection; connections)
		{
			/* The connection must be a user (not unspec or server) */
			if(connection.getConnectionType() == DConnection.ConnectionType.CLIENT)
			{
				/* Match the username */
				if(cmp(connection.getUsername(), username) == 0)
				{
					return connection;
				}
			}
		}

		return null;
	}

	public DConnection[] getConnections()
	{
		/* The current connections list */
		DConnection[] currentConnections;
		
		/* Lock the connections list */
		connectionLock.lock();

		currentConnections = connectionQueue;

		/* Unlock the connections list */
		connectionLock.unlock();
		
		return currentConnections;
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
}
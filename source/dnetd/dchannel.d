/**
* DChannel
*
* Represents a channel and its
* associated information such
* as its name, topic, members
*/

module dnetd.dchannel;

import dnetd.dconnection : DConnection;
import core.sync.mutex : Mutex;

public class DChannel
{
	/**
	* Channel information
	*/
	private string name;
	//private string topic;

	/**
	* Users in this channel
	*/
	private DConnection[] members;
	private Mutex memberLock;

	this(string name)
	{
		/* Initialize the lock */
		memberLock = new Mutex();
	}

	public string getName()
	{
		return name;
	}

	public void join(DConnection client)
	{
		/* Lock the members list */
		memberLock.lock();

		/**
		* TODO: Error handling if the calling DConnection fails midway 
		* and doesn't unlock it
		*/

		/* Add the client */
		members ~= client;

		/* Unlock the members list */
		memberLock.unlock();
	}

	public void leave(DConnection client)
	{
		
	}

	public override string toString()
	{
		return "DChannel [Name: "~name~", Members: "~members~"]";
	}
	
}
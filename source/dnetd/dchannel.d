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
import std.conv : to;

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
		/* Lock the members list */
		memberLock.lock();

		/* TODO: Get a better implementation */

		/* Create a new list without the `client` */
		DConnection[] newMembers;
		foreach(DConnection currentMember; members)
		{
			if(!(currentMember is client))
			{
				newMembers ~= currentMember;	
			}
		}

		/* Set it as the new list */
		members = newMembers;

		/* Unlock the members list */
		memberLock.unlock();
	}

	public override string toString()
	{
		string toStr;

		/* Lock the members list */
		memberLock.lock();
		
		toStr = "DChannel [Name: "~name~", Members: "~to!(string)(members)~"]";

		/* Unlock the members list */
		memberLock.unlock();

		return toStr;
	}
	
}
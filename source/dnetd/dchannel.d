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
import std.stdio : writeln;

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

		this.name = name;
	}

	public string getName()
	{
		return name;
	}

	/**
	* Joins the given client to this channel
	*/
	public bool join(DConnection client)
	{
		/* Lock the members list */
		memberLock.lock();

		/**
		* Don't allow the user to join a channel he
		* is already in
		*/
		bool isPresent = false;
		
		foreach(DConnection member; members)
		{
			if(client is member)
			{
				isPresent = true;
				break;
			}
		}

		/**
		* TODO: Error handling if the calling DConnection fails midway 
		* and doesn't unlock it
		*/

		/* Only join channel if not already joined */
		if(!isPresent)
		{
			/* Add the client */
			members ~= client;			
		}


		/* Unlock the members list */
		memberLock.unlock();

		return isPresent;
	}

	/**
	* Returns the number of members in this channel
	*/
	public ulong getMemberCount()
	{
		/* The count of members */
		ulong memberCount;
		
		/* Lock the members list */
		memberLock.lock();

		/* Get the member count */
		memberCount = members.length;

		/* Unlock the members list */
		memberLock.unlock();

		return memberCount;
	}

	public bool isMember(DConnection client)
	{
		/* Whether or not you are a member */
		bool isMem;

		/* Lock the members list */
		memberLock.lock();

		/* CHeck if you are in this channel */
		foreach(DConnection member; members)
		{
			if(member is client)
			{
				isMem = true;
				break;
			}
		}

		/* Unlock the members list */
		memberLock.unlock();

		return isMem;
	}

	/**
	* Removes the given client from this channel
	*/
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

		/* TODO: Send left message here */

		/* Unlock the members list */
		memberLock.unlock();
	}

	public bool sendMessage(DConnection sender, string message)
	{
		bool status;

		/* The protocol data to send */
		byte[] msg;

		/* Set the notificaiton type */
		msg ~= [0];

		/**
		* Format
		* 0 - dm
		* 1 - channel (this case)
		* byte length of name of channel/person (dm case)
		* message-bytes
		*/
		msg ~= [cast(byte)1,(cast(byte)sender.getUsername().length)]~cast(byte[])sender.getUsername()~cast(byte[])message;
		
		/* Send the message to everyone else in the channel */
		foreach(DConnection member; members)
		{
			/* Skip sending to self */
			if(!(member is sender))
			{
				/* Send the message */
				writeln("Delivering message '"~message~"' for channel '"~name~"' to user '"~member.getUsername()~"'...");
				status = member.writeSocket(0, msg);
				writeln("Delivered message '"~message~"' for channel '"~name~"' to user '"~member.getUsername()~"'!");

				/* TODO: Errors from status */
			}
		}


		return status;
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
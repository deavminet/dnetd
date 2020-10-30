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
import gogga;

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
		/* Send a message stating the user has joined (TODO: This should be done later, possibly, how defensive should we program) */
		broadcastJoin(client);

		/* Lock the members list */
		gprintln("join: mutex lock (about to call)");
		memberLock.lock();
		gprintln("join: mutex lock (completed)");

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
		gprintln("join: mutex unlock (about to call)");
		memberLock.unlock();
		gprintln("join: mutex unlock (completed)");

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

		/* Unlock the members list */
		memberLock.unlock();

		/* Send broadcast leave message */
		broadcastLeave(client);
	}

	/**
	* Sends a message to all users of this
	* channel that the given user has left
	*/
	private void broadcastLeave(DConnection left)
	{
		/* Lock the members list */
		memberLock.lock();
		
		/* Send left message here */
		foreach(DConnection currentMember; members)
		{
			sendLeaveMessage(currentMember, left);
		}

		/* Unlock the members list */
		memberLock.unlock();
	}

	/**
	* Sends a message to the user stating the given
	* (other) user has left the channel
	*/
	private void sendLeaveMessage(DConnection member, DConnection left)
	{
		/* The protocol data to send */
		byte[] protocolData;

		/* Set the notificaiton type to `channel status` */
		protocolData ~= [1];

		/* Set the sub-type to leave */
		protocolData ~= [0];

		/* Set the channel notificaiton type to `member leave` */

		/* LeaveInfo: <channel>,<username> */
		string leaveInfo = name~","~left.getUsername();
		protocolData ~= cast(byte[])leaveInfo;

		/* Write the notification */
		member.writeSocket(0, protocolData);
	}

	/**
	* Sends a message to all users of this
	* channel that the given user has joined
	*/
	private void broadcastJoin(DConnection joined)
	{
		/* Lock the members list */
		memberLock.lock();
		
		/* Send join message here */
		foreach(DConnection currentMember; members)
		{
			sendJoinMessage(currentMember, joined);
		}

		/* Unlock the members list */
		memberLock.unlock();
	}

	/**
	* Sends a message to the user stating the given
	* (other) user has joined the channel
	*/
	private void sendJoinMessage(DConnection member, DConnection joined)
	{
		/* The protocol data to send */
		byte[] protocolData;

		/* Set the notificaiton type to `channel status` */
		protocolData ~= [1];

		/* Set the sub-type to join */
		protocolData ~= [1];

		/* Set the channel notificaiton type to `member join` */

		/* JoinInfo: <channel>,<username> */
		string joinInfo = name~","~joined.getUsername();
		protocolData ~= cast(byte[])joinInfo;

		/* Write the notification */
		member.writeSocket(0, protocolData);
	}



	public bool sendMessage(DConnection sender, string message)
	{
		bool status;

		/* The protocol data to send */
		byte[] msg;

		/* Set the notificaiton type to `message notification` */
		msg ~= [0];

		/**
		* Format
		* 0 - dm
		* 1 - channel (this case)
		* byte length of name of channel/person (dm case)
		* message-bytes
		*/

		/* Set mode to channel message */
		msg ~= [cast(byte)1];
		
		/* Encode the [usernameLength, username] */
		msg ~= [(cast(byte)sender.getUsername().length)];
		msg ~= cast(byte[])sender.getUsername();
		
		/* Encode the [channelLength, channel] */
		msg ~= [(cast(byte)name.length)];
		msg ~= cast(byte[])name;

		/* Encode the message */
		msg ~= cast(byte[])message;
		
		/* Send the message to everyone else in the channel */
		foreach(DConnection member; members)
		{
			/* Skip sending to self */
			if(!(member is sender))
			{
				/* Send the message */
				gprintln("Delivering message '"~message~"' for channel '"~name~"' to user '"~member.getUsername()~"'...");
				status = member.writeSocket(0, msg);

				if(status)
				{
					gprintln("Delivered message '"~message~"' for channel '"~name~"' to user '"~member.getUsername()~"'!");	
				}
				else
				{
					gprintln("Failed to deliver message '"~message~"' for channel '"~name~"' to user '"~member.getUsername()~"'!", DebugType.ERROR);	
				}
			}
		}


		/* TODO: Don't, retur true */
		return true;
	}

	/**
	* Returns a list of all the members
	*/
	public DConnection[] getMembers()
	{
		/* Members list */
		DConnection[] memberList;

		/* Lock the members list */
		memberLock.lock();
		
		memberList = members;

		/* Unlock the members list */
		memberLock.unlock();

		return memberList;
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
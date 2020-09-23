/**
* DChannel
*
* Represents a channel and its
* associated information such
* as its name, topic, members
*/

module dnetd.dchannel;

import dnetd.dconnection : DConnection;

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

	this(string name)
	{
		
	}

	public string getName()
	{
		return name;
	}

	public void join(DConnection client)
	{
		
	}
	
}
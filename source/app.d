import std.stdio;
import std.socket : parseAddress;
import dnetd.dserver : DServer;

void main()
{
	/* TODO: Args for bind */

	          
	DServer dserver = new DServer(parseAddress("0.0.0.0", 7777));
	

}
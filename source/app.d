import std.stdio;
import std.socket : parseAddress;
import dnetd.dserver : DServer;
import dnetd.dconfig : DGeneralConfig, DLinkConfig;
import std.json;
import std.exception;
import gogga;
import dnetd.dlink : DLink, DMeyer;

void main(string[] args)
{
	/* Configuration file */
	string configFilename;
	
	/* If there are no arguments */
	if(args.length == 1)
	{
		/* Use the default file */
		configFilename = "config.json";
	}
	/* If there is one argument */
	else if(args.length == 2)
	{
		/* use the specified one */
		configFilename = args[1];
	}
	/* Illegal amount of guns in one household (no such thing) */
	else
	{
		gprintln("Invalid number of arguments", DebugType.ERROR);
		return;
	}
	
	/* Configuration file contents */
	byte[] data;

	try
	{
		/* Open the file for reading */
		File config;
		config.open(configFilename, "r");

		/* Read the configuration file data */
		data.length = config.size();
		data = config.rawRead(data);
		config.close();
	}
	catch(ErrnoException e)
	{
		gprintln("Failure to use configuration file'"~configFilename~"' with error:\n\n"~e.toString(), DebugType.ERROR);
		return;
	}

	

	try
	{
		/* The JSON */
		JSONValue json;

		/* Parse the configuration file */
		json = parseJSON(cast(string)data);

		/* Create a new configuration file and check configuration parameters */
		DGeneralConfig config = DGeneralConfig.getConfig(json["general"]);

		/* Create a new server */
		DServer dserver = new DServer(config);

		/* Now configure the the linking */
		DLinkConfig linkConfig = DLinkConfig.getConfig(dserver, json["links"]);

		/* Get all server links */
		DLink[] serverLinks = linkConfig.getLinks();

		/* Create a new Meyer (link manager) and attach the links to it */
		DMeyer meyer = new DMeyer(dserver, serverLinks);
		
		/* Attach the Meyer to the server */
		dserver.attachLinkManager(meyer);

		/* Start the server (TODO: This should start Meyer) */
		dserver.startServer();

	}
	catch(JSONException e)
	{
		gprintln("Failure to parse configuration file'"~configFilename~"' with error:\n\n"~e.toString(), DebugType.ERROR);
		return;
	}
}
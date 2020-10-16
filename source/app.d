import std.stdio;
import std.socket : parseAddress;
import dnetd.dserver : DServer;
import dnetd.dconfig : DConfig;
import std.json;
import std.exception;

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
		writeln("Invalid number of arguments");
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
		writeln("Failure to use configuration file'"~configFilename~"' with error:\n\n"~e.toString());
		return;
	}

	/* The JSON */
	JSONValue json;

	try
	{
		/* Parse the configuration file */
		json = parseJSON(cast(string)data);
	}
	catch(JSONException e)
	{
		writeln("Failure to parse configuration file'"~configFilename~"' with error:\n\n"~e.toString());
		return;
	}

	/* Create a new configuration file and check configuration parameters */
	DConfig config = DConfig.getConfig(json);

	/* If the configuration reading was successful (valid JSON) */
	if(config)
	{
		/* Start the server */
		DServer dserver = new DServer(config);
	}
	else
	{
		writeln("Failure to read a valid dnetd configuration file'"~configFilename~"'");	
	}
	
	

}
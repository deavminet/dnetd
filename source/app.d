import std.stdio;
import std.json;
import std.exception;
import dnetd.server;

void main(string[] args)
{
    /* TODO: Use jcli */

    if(args.length == 2)
    {
        startServer(args[1]);
    }
    else
    {
        writeln("error no args");
    }
}

private void startServer(string configPath)
{
    /* Config file data */
    string configFileData;

    try
    {
        configFileData = readConfig(configPath);
    }
    catch(ErrnoException e)
    {
        writeln("error file read");
        return;
    }

    /* Parse JSON */
    JSONValue configJSON;

    try
    {
        configJSON = parseJSON(configFileData);
    }
    catch(JSONException)
    {
        writeln("config parse error");
        return;
    }

    /* Get server config */
    ServerConfig config = getServerConfig(configJSON);

    /* Create a new Server */
    Server server = new Server(config);
}

private ServerConfig getServerConfig(JSONValue jsonConfig)
{
    /* TODO: Implement me */
    ServerConfig config;


    return config;
}

private string readConfig(string configPath)
{
    File configFile;

    
        configFile.open(configPath);
        ulong configSize = configFile.size();

        byte[] data;
        data.length = configSize;
        configFile.rawRead(data); /* TODO: No case where the size returned is smaller seeing that we have the exact file size */


    
    
    return cast(string)data;
}
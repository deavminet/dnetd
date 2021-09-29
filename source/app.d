import std.stdio;
import std.json;
import std.exception;
import dnetd.server;
import std.conv;
import std.socket : parseAddress, Address;
import dnetd.listener : Listener;
import gogga;

void main(string[] args)
{
    /* TODO: Use jcli */

    if(args.length == 2)
    {
        startServer(args[1]);
    }
    else
    {
        gprintln("error no args", DebugType.ERROR);
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
        gprintln("error file read", DebugType.ERROR);
        return;
    }

    /* Parse JSON */
    JSONValue configJSON;

    try
    {
        configJSON = parseJSON(configFileData);
    }
    catch(ConvException)
    {
        gprintln("config parse error", DebugType.ERROR);
        return;
    }
    catch(JSONException)
    {
        gprintln("config parse error", DebugType.ERROR);
        return;
    }

    /* Get server config */
    ServerConfig config;

    try
    {
       config = getServerConfig(configJSON);
    }
    catch(JSONException e)
    {
        gprintln("Config bad", DebugType.ERROR);
        return;
    }

    /* Create a new Server */
    Server server = new Server(config);




    gprintln("good");
}

private ServerConfig getServerConfig(JSONValue jsonConfig)
{
    /* TODO: Implement me */
    ServerConfig config;

    JSONValue generalBlock = jsonConfig["general"];

    /* Get bind block */
    JSONValue[] binds = generalBlock["binds"].array();
    Listener[] listeners;
    foreach(JSONValue bindDeclaration; binds)
    {
        string address = bindDeclaration["address"].str();
        string port = bindDeclaration["port"].str();

        Address lAddr = parseAddress(address, to!(ushort)(port));
        Listener listener = new Listener(lAddr);
        listeners ~= listener;
    }


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
/**
* DConfig
*
* Represents all configuration parameters
*/
module dnetd.dconfig;

import std.json;
import std.conv;
import std.socket : Address, parseAddress;
import gogga;
import dnetd.dlink : DLink;
import dnetd.dserver : DServer;

public final class DConfig
{
    /* General configuration */
    private DGeneralConfig generalConfig;

    /* Link configuration */
    private DLinkConfig linksConfig;

    private this()
    {
        /* TODO: */
    }

    public DGeneralConfig getGeneral()
    {
        return generalConfig;
    }

    public DLinkConfig getLinks()
    {
        return linksConfig;
    }

    public static DConfig getConfig(JSONValue json)
    {
        /* The newly created configuration */
        DConfig config = new DConfig();

        try
        {
            /* TODO: Parse */

            /* Get the `general` block */
            JSONValue generalBlock = json["general"];
            config.generalConfig = DGeneralConfig.getConfig(generalBlock);

            /* Get the `links` block */
            JSONValue linksBlock = json["links"];
            config.linksConfig = DLinkConfig.getConfig(linksBlock);
        }
        catch(JSONException e)
        {
            /* Set config to null (signals an error) */
            config = null;
        }

        return config;
    }

    public JSONValue saveConfig()
    {
        JSONValue config;


        return config;
    }
}

public final class DGeneralConfig
{
    /* Addresses to bind sockets to */
    private Address[] addresses;
    private ushort port;

    /* Server information */
    private string network;
    private string name;
    private string motd;

    public static DGeneralConfig getConfig(JSONValue generalBlock)
    {
        /* The generated general config */
        DGeneralConfig config = new DGeneralConfig();
        gprintln("Reading config:\n"~generalBlock.toPrettyString());

        try
        {
            /* Set the addresses to bind to */
            foreach(JSONValue bindBlock; generalBlock["binds"].array())
            {
                /* Get the address */
                string address = bindBlock["address"].str();

                /* Get the port */
                ushort port = to!(ushort)(bindBlock["port"].str());

                /* Add the address and port tuple to the list of addresses to bind to */
                config.addresses ~= parseAddress(address, port);
            }

            /* Set the network name */
            config.network = generalBlock["network"].str();

            /* Set the server name */
            config.name = generalBlock["name"].str();

            /* Set the message of the day */
            config.motd = generalBlock["motd"].str();
        }
        catch(JSONException e)
        {
            /* Set the config to null (signals an error) */
            config = null;
        }

        return config;
    }

    public string getMotd()
    {
        return motd;
    }

    public Address[] getAddresses()
    {
        return addresses;
    }
}

public final class DLinkConfig
{
    /* Server links */
    private DLink[] links;

    public static DLinkConfig getConfig(DServer dserver, JSONValue linksBlock)
    {
        DLinkConfig dlinkConfig = new DLinkConfig();

        /* Get the active servers */
        string[] activeServers;
        JSONValue[] serversActive = linksBlock["active"].array();
        foreach(JSONValue activeServer; serversActive)
        {
            string server = activeServer.str();
            gprintln("Found active server to be linked with \""~server~"\"");
            activeServers ~= server;
        }

        /* Parse each link and add it to the link-list */
        foreach(string server; activeServers)
        {
            /* Get the peer block */
            JSONValue peerBlock = linksBlock[server];

            /* Get the name */
            string name = peerBlock["name"].str();

            /* Get the address */
            string address = peerBlock["address"].str();

            /* Get the port */
            ushort port = to!(ushort)(peerBlock["port"].str());

            /* Add the address and port tuple to the list of addresses to bind to */
            dlinkConfig.links ~= new DLink(server, name, parseAddress(address, port));
        }

        return dlinkConfig;
    }

    public DLink[] getLinks()
    {
        return links;
    }
}
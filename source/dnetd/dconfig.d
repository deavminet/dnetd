/**
* DConfig
*
* Represents all configuration parameters
*/
module dnetd.dconfig;

import std.json;
import std.conv;
import std.socket : Address, parseAddress;

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
            //config.linksConfig = DLinkConfig.getConfig(linksBlock);
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
    private string[] addresses;
    private ushort port;

    /* Server information */
    private string network;
    private string name;
    private string motd;

    private this()
    {

    }

    public static DGeneralConfig getConfig(JSONValue generalBlock)
    {
        /* The generated general config */
        DGeneralConfig config = new DGeneralConfig();

        try
        {
            /* Set the addresses */
            foreach(JSONValue address; generalBlock["addresses"].array())
            {
                config.addresses ~= [address.str()];
            }
            
            /* Set the ports */
            config.port = to!(ushort)(generalBlock["port"].str());

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

    public Address getAddress()
    {
        /* TODO: Add multi address support later */
        return parseAddress(addresses[0], port);
    }
}

public final class DLinkConfig
{

}
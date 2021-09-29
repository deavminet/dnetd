module dnetd.server;

import dnetd.listener;

public struct ServerConfig
{
    Listener[] listeners;

    string serverName;
    string networkName;
    ubyte serverID;
    string motd;

}

public class Server
{
    /* FIXME: Use DList for this */
    private Listener[] listeners;
    /* TODO: Latwr add mutex for managing lusteners if we do multi thread removal */

    this(ServerConfig config)
    {
        /* Set the listeners configured */
        listeners = config.listeners;

        /* Configure all listeners to use this server instance */
        Listener.server = this;
    }

    public void run()
    {
        /* Start all listeners */
        startListeners();
    }

    private void startListeners()
    {
        foreach(Listener listener; listeners)
        {
            listener.start();
        }
    }

}
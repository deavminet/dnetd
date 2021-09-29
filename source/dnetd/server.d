module dnetd.server;

import dnetd.listener;

public struct ServerConfig
{
    Listener[] listeners;

}

public class Server
{
    /* FIXME: Use DList for this */
    private Listener[] listeners;

    this(ServerConfig config)
    {
        /* Set the listeners configured */
        listeners = config.listeners;

        /* Configure all listeners to use this server instance */
        Listener.server = this;
    }

}
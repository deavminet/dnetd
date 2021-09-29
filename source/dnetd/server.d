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
        listeners = config.listeners;
    }

}
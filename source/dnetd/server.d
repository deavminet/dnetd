module dnetd.server;

import dnetd.listener;
import dnetd.connection;
import std.container.dlist;
import core.sync.mutex;

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

    private DList!(Connection) connQueue;
    private Mutex connQueueLock;

    this(ServerConfig config)
    {
        /* Set the listeners configured */
        listeners = config.listeners;

        /* Configure all listeners to use this server instance */
        Listener.server = this;

        /* Configure all Connection's to use this Server */
        Connection.server = this;

        /* Initialize all mutexes */
        connQueueLock = new Mutex();
    }

    public void addConnection(Connection connection)
    {
        /* Lock the queue */
        connQueueLock.lock();

        /* Append the connection to the queue */
        connQueue ~= connection;

        /* Unlock the queue */
        connQueueLock.unlock();
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
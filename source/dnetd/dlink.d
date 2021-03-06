module dnetd.dlink;

import dnetd.dconnection;
import core.sync.mutex : Mutex;
import std.stdio;
import std.conv;
import dnetd.dserver;

/**
* DLink
*
* Couples a DConneciton (direct peer)
* with information about what this link
* knows and can tell us
*/
public final class DLink
{
    /* The directly attached peer */
    private DConnection directPeer;

    /* Servers (by name) this server is aware of */
    private string[] knowledgeList;

    this(DConnection directPeer)
    {
        this.directPeer = directPeer;
    }

    /* Call this to update list */
    public void updateKB()
    {
        /* TODO: Ask DConneciton here for the servers he knows */
    }
}

public final class DMeyer
{
    /* List of links (direct peers + additional information) */
    private DLink[] links;
    private Mutex linksMutex;

    private DServer server;

    this(DServer server)
    {
        this.server = server;
        linksMutex = new Mutex();
    }

    /* Attach a direct peer */
    public void attachDirectPeer(DConnection peer)
    {
        /* TODO: Add to `directPeers` */
        linksMutex.lock();

        links ~= new DLink(peer);
        writeln("Attached direct peer: "~to!(string)(peer));

        linksMutex.unlock();
    }

    /* Get a list of all servers we know of */


    public DLink getLink(DConnection peer)
    {
        DLink link;

        linksMutex.lock();

        

        linksMutex.unlock();

        return link;
    }

}

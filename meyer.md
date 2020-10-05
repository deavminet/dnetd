Meyer link protocol
===================

This document describes the Meyer linking protocol which is used to maintain server links in the dnet network and deliver data across the links.

## Protocol

Every server maintains a list of connections (server, clients and unspec), this is the `DConnection[]` array. What we are concerned with here is the subset of that array which has `ConnectionType.SERVER` (so all servers).

We also maintain a list of all servers that we know of via links, this is called `sl` and normally written in the notation of `sl=[]`. Some of these elements will be servers in `DConnection[]` (direct) however not all will be (indirect).

### Link request

A link request is when Server B makes a request to Server A to link up (`Server B -> Server A`) then the following happens.

Server A checks its `sl=[]` and checks if the announced server name by Server B is in it, if so it closes the request as they must be linked already directly or indirectly.

However, if not then it will add `B` to its `sl=[]`, so now it is `sl=[B]`. Another thing to note is when Server B makes the request (regardless of if it will go through or not), it will 


WHen a server wants to link with another it sends a lin request containing:

1. it's server name
2. a list of the links it has (direct and indirect)

The receiving server checks first of all if 
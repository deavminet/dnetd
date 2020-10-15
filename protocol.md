# Protocol

This page describes the dnet protocol, from user messaging all the way to inter-server communication.

## Server-side

The server expects a TCP connection on a given port, so far there is no multiple listener support that would allow for binding to IPv6 and IPv4 at the same time or to other address families such as UNIX domain sockets (this will be a feature in the near future).

### Commands

Every command starts with a 1 byte code specifying the command.

```
|-- command (1 byte) --|-- dependant on command (n bytes) --|
```

---

#### `auth`

Sets this connection's connection mode to that of _Client_ and attempts to login with the provided credentials. Setting this mode means that the **_auth_** and **_link_** commands will no longer be available and only the commands that a _Client_ may use will be allowed to execute.

**Request format:**

```
|-- 0 --|-- usernameLength (1 byte) --|-- username --|-- password --|
```

**Reply format:**

```
|-- status (1 byte) --|
```

---

#### `link`

**Request format:**

```
|-- 1 --|-- todo
```

**Reply format:**

---

#### `reg`

**Request format:**

2

**Reply format:**

---

#### `join`

Joins the given channel.

**Request format:**

```
|-- 3 --|-- channelToJoin(CSV) --|
```

**Reply format:**

```
|-- status (1 byte) --|
```

TODO: Support redirects?

---

#### `part`

Leaves the given channel.

**Request format:**

```
|-- 4 --|-- channelToPart(CSV) --|
```

**Reply format:**

```
|-- status (1 byte) --|
```

---

#### `msg`

Sends a message to either a channel or a user.

**Request format:**

```
|-- 5 --|-- type (1 byte) --|-- locationSize (1 byte) --|-- location (n-bytes) --|-- message (n-bytes) --|
```

* The **_type_** field specifies whether the message is to be sent to a user or channel
	* **0** - this is for a **user** as the destination
	* **1** - this is for a **channel** as the destination

**Reply format:**

```
|-- status (1 byte) --|
```

---

#### `list`

Retrieves a list of all channels on the server.

**Request format:**

```
|-- 6 --|
```

**Reply format:**

```
|-- status (1 byte) --|-- channelnames(CSV) --|
```

---

#### `membercount`

Returns the number of people in the given channel.

**Request format:**

```
|-- 8 --|-- channel --|
```

**Reply format:**

```
|-- status (1 byte) --|-- member count (4 bytes - big endian) --|
```

---

#### `memberlist`

Retrieve a list of all the users in the given channel.

**Request format:**

```
|-- 9 --|-- channel --|
```

**Reply format:**

```
|-- status (1 byte) --|-- channel members (CSV) --|
```

---

#### `serverinfo`

Returns server information.

**Request format:**

```
|-- 10 --|
```

**Reply format:**

```
|-- status (1 byte) --|-- server info(CSV) --|
```

##### Format of server info (CSV)

```
<serverName>,<networkName>,<userCount>,<channelCount>
```

---

#### `motd`

Retrieves the server's _message-of-the-day_.

**Request format:**

```
|-- 11 --|
```

**Reply format:**

```
|-- status (1 byte) --|-- motd --|
```

---

#### `memberinfo`

**TODO: This is still a work in progress**

Retrieves informaiton for the given member.

**Request format:**

```
|-- 12 -- |-- username --|
```

**Reply format:**

```
|-- status (1 byte) --|-- logonTime --|-- serverOn --|-- <status> (CSV) --|
```

---

#### `status`

Sets your _status_. The concept of a status on dnet is simply a comma-seperated (CSV) string of attribute values, however there is no particular format with regards to what it should contain or what the ordering of elements should be, therefore it is up to the clinets to decide on which information makes it into the status message.

A simple example of a usaeful status message could be something like:

```
<availability (available/busy/away)>,<message>
```

**Request format:**

```
|-- 13 -- |-- username --|
```

**Reply format:**

```
|-- status (1 byte) --|
```

---

#### `chanprop`

Returns the property line of the given channel. Like the concept of a user's _status_, the channel's _properties_ plays a similiar role in the sense that arbitrary comma-seperated values can be placed into it.

A traditional usage for the channel property field could be something that throws us back to the IRC days such as for a channel's topic:

```
<topic>
```

Although we could add more onto this if one wanted.

**Request format:**

```
|-- 14 -- |-- channelName --|
```

**Reply format:**

```
|-- status (1 byte) --|-- channel property (CSV) --|
```

---

#### `setprop`

Sets the given channel's property.

**Request format:**

```
|-- 15 -- |-- channelName (1 byte) --|-- property line (CSV) --|
```

**Reply format:**

```
|-- status (1 byte) --|
```

---

#### Unknown commands

Anything that isn't a command above will return with **2** which means _unknown command_.
**1** generally means that everything went well but commands can send more data after it,
it depends, and **0** means error - also more data may follow.

---

## notifications

We know as tristanable tag 1, but then _types_ of notifications is the important factor described here.

```
|-- notifyTYpe (1 byte) --|-- ..
```

### TODO: message receive format (`notifyType=0`)

For a normal channel message or direct message

TODO

### TODO: channel status message (`notifyType=1`)

types within:

1. `0` - 1 byte: Member leave
2. `1` - 1 byte: Member join
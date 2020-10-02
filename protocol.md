dnet protocol specification
===========================

## Preamble

Every command starts with a 1 byte code specifying the command.

```
|-- command (1 byte) --|-- dependant on command (n bytes) --|
```

## Command listing (client/server->server)

1. `auth` - authenticate a new client
2. `link` - authenticate a new server

## Client/Server types (server->server/client)

1. `msg` - new message

## Commands

### `auth`

Request format:

```
|-- 0 --|-- usernameLength (1 byte) --|-- username --|-- password --|
```

Reply format:

```
|-- status (1 byte) --|
```

### `link`

```
|-- 1 --|-- todo
```

### `reg`

2

### `join`

Request format:

TODO: Allow multiple joins

```
|-- 3 --|-- channelToJoin(CSV) --|
```

Reply format:

```
|-- status (1 byte) --|
```

TODO: Support redirects?

### `part`

Request format:

```
|-- 4 --|-- channelToPart(CSV) --|
```

Reply format:

```
|-- status (1 byte) --|
```

### `msg`

Request format:

```
|-- 5 --|-- type (1 byte) --|-- locationSize (1 byte) --|-- location (n-bytes) --|-- message (n-bytes) --|
```

* The `type` field specifies whether the message is to be sent to a user or channel
	1. `0` - this is for a **user** as the destination
	2. `1` - this is for a **channel** as the destination

Reply format:

```
|-- status (1 byte) --|
```

### `list`

Request format:

```
|-- 6 --|
```

Reply format:

```
|-- status (1 byte) --|-- channelnames(CSV) --|
```

### `msg`

Request format:

```
|-- 7 --|-- type (1 byte) --|-- channel/person name (null terminated) --|-- message --|
```

* `type`, `0` - to user, `1` to channel

Reply format *TODO*


### `membercount`

Request format: 

```
|-- 8 --|-- channel --|
```

Reply format:

```
|-- status (1 byte) --|-- member count (4 bytes - big endian) --|
```

### `memberlist`

Request format: 

```
|-- 9 --|-- channel --|
```

Reply format:

```
|-- status (1 byte) --|-- channel members (CSV) --|
```

### `serverinfo`

Request format: 

```
|-- 10 --|
```

Reply format:

```
|-- status (1 byte) --|-- server info(CSV) --|
```

#### Format of server info (CSV)

```
<serverName>,<networkName>,<userCount>,<channelCount>
```

### `motd`

Request format: 

```
|-- 11 --|
```

Reply format:

```
|-- status (1 byte) --|-- motd --|
```

### `chanprop`


---

Anything that isn't a command above will return with `2` which means _unknown command_.
`1` generally means that everything went well but commands can send more data after it,
it depends, and `0` means error - also more data may follow.

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
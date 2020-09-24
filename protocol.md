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
5

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

### `chanprop`


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
|-- 1 --|-- status (1 byte) --|
```

### `link`

```
|-- 2 --|-- todo
```


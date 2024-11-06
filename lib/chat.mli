val client_string_id : string
val server_string_id : string

type message =
  | MsgAck of string
  | StdinRead of string
  | Mtime_clock of Mtime_clock.counter

exception SocketClosed

val handle_unexpected_socket_close : [> `Close ] Eio.Resource.t -> 'a

val read_from_socket_loop :
  string ->
  message Domainslib.Chan.t ->
  [> `Close | `Flow | `R ] Eio.Resource.t ->
  bool Atomic.t ->
  unit

val read_from_stdin_loop : message Domainslib.Chan.t -> bool Atomic.t -> unit

val write_to_socket_endline :
  [> `Close | `Flow | `W ] Eio.Resource.t -> string -> bool Atomic.t -> unit

val process_message_channel_and_write_to_socket_loop :
  string ->
  message Domainslib.Chan.t ->
  [> `Close | `Flow | `W ] Eio.Resource.t ->
  bool Atomic.t ->
  'a

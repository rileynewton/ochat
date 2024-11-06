module Chat = Chat

val run_fn_in_new_domain :
  [> Eio.Domain_manager.ty ] Eio.Resource.t -> (unit -> 'a) -> 'a

val chan : Chat.message Domainslib.Chan.t
val socket_closed_unexpectedly : bool Atomic.t

val run_chat_loop :
  string ->
  [> Eio.Domain_manager.ty ] Eio.Resource.t ->
  [> `Close | `Flow | `R | `W ] Eio.Resource.t ->
  unit

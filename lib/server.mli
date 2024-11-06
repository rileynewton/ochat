module Chat_loop = Chat_loop

val string_id : string

val handle_connection_from_client :
  string ->
  [> Eio.Domain_manager.ty ] Eio.Resource.t ->
  [> `Close | `Flow | `R | `W ] Eio.Resource.t ->
  [< Eio.Net.Sockaddr.t ] ->
  unit

val handle_error : exn -> unit

val run_server :
  net:[> [> `Generic ] Eio.Net.ty ] Eio.Resource.t ->
  port:int ->
  domain_mgr:[> Eio.Domain_manager.ty ] Eio.Resource.t ->
  'a

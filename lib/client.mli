module Chat_loop = Chat_loop
module Chat = Chat

val string_id : string

val connect_to_server :
  net:[> 'a Eio.Net.ty ] Eio.Resource.t ->
  host:string ->
  port:string ->
  domain_mgr:[> Eio.Domain_manager.ty ] Eio.Resource.t ->
  unit

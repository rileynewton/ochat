open Eio.Std
module Chat_loop = Chat_loop

(* identifying string in the chat *)
let string_id = Chat.server_string_id

(** [handle_connection_from_client (string_id pool flow addr)] Runs the task pool that kicks off the chat loop.
    The chat loop is intended to be run anew each time a connection is established. *)
let handle_connection_from_client string_id domain_mgr flow addr =
  traceln "%s accepted connection from %a" string_id Eio.Net.Sockaddr.pp addr;
  Chat_loop.run_chat_loop string_id domain_mgr flow;
  traceln "Closing connection from %a." Eio.Net.Sockaddr.pp addr

let handle_error ex =
  traceln "%s error: %a" string_id Fmt.exn ex;
  let backtrace = Printexc.get_backtrace () in
  if String.length backtrace > 0 then traceln "Backtrace%s\n" backtrace

(** [run_server (~net ~port)] sets up Task pool for executing chat loop and continously running Eio.Net server.
    Each new connection calls handle_connection which starts the chat loop. *)
let run_server ~net ~port ~domain_mgr =
  Switch.run ~name:"ochat_server" @@ fun sw ->
  let socket =
    Eio.Net.listen ~sw ~reuse_addr:true ~reuse_port:true ~backlog:10 net
      (`Tcp (Eio.Net.Ipaddr.V4.loopback, port))
  in
  traceln "Server listening on port %d." port;
  Eio.Net.run_server socket ~sw ~additional_domains:(domain_mgr, 3)
    ~on_error:handle_error
    ~max_connections:20
      (* even though only one connection is intended, in practice
         this can be a bottleneck where the server seems to fail on
         accepting new connections after several connect/disconnects
         if the limit is too low *)
    (handle_connection_from_client string_id domain_mgr)

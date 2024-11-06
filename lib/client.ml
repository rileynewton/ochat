open Eio.Std
open Stdlib
module Chat_loop = Chat_loop
module Chat = Chat

(* identifying string in the chat *)
let string_id = Chat.client_string_id

let connect_to_server ~net ~host ~port ~domain_mgr =
  traceln "%s connecting to server at %s:%s" string_id host port;
  try
    Eio.Net.with_tcp_connect ~host ~service:port net (fun flow ->
        traceln "%s connected to server at %s:%s" string_id host port;
        Chat_loop.run_chat_loop string_id domain_mgr flow;
        traceln "%s exiting." string_id)
  with
  | End_of_file -> traceln "Server closed the connection."
  | ex ->
      traceln "%s error: %a" string_id Fmt.exn ex;
      let backtrace = Printexc.get_backtrace () in
      if String.length backtrace > 0 then traceln "Backtrace%s\n" backtrace

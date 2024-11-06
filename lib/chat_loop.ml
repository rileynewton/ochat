module Chat = Chat

let run_fn_in_new_domain domain_mgr fn = Eio.Domain_manager.run domain_mgr fn

(* Separate channel from chat loop in to be able to queue messages after disconnection *)
let chan = Domainslib.Chan.make_unbounded ()

(* a simple flag, only changed to true if socket is unexpectedly closed in order
   to coordinate between domains to not attempt operations on a closed socket *)
let socket_closed_unexpectedly = Atomic.make false

(** [run_chat_loop (string_id domain_mgr flow)] runs and manages the three parallel loops composing the chat application:
     1) stdin read 2) socket read and 3) process message channel/socket write (each running in their own domain). *)
let run_chat_loop string_id domain_mgr flow =
  (* begin assuming a healthy socket state as Eio should fail easily if socket can't initially be established
     the harder case is when socket is closed in the middle of an operation *)
  Atomic.set socket_closed_unexpectedly false;

  Eio.Fiber.any
    [
      (* Run each loop in a new domain using Fiber.any as we want the whole loop to fail (for a new connection)
         if one of these fns fails, this is also why exceptions in the loops have
         to be handled very particularly *)
      (fun () ->
        run_fn_in_new_domain domain_mgr (fun () ->
            Chat.read_from_socket_loop string_id chan flow
              socket_closed_unexpectedly));
      (fun () ->
        run_fn_in_new_domain domain_mgr (fun () ->
            Chat.read_from_stdin_loop chan socket_closed_unexpectedly));
      (fun () ->
        run_fn_in_new_domain domain_mgr (fun () ->
            Chat.process_message_channel_and_write_to_socket_loop string_id chan
              flow socket_closed_unexpectedly));
    ]

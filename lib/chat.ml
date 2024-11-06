open Domainslib

let client_string_id = "Client"
let server_string_id = "Server"

type message =
  | MsgAck of string
  | StdinRead of string
  | Mtime_clock of Mtime_clock.counter

exception SocketClosed

let handle_unexpected_socket_close flow =
  Eio.Flow.close flow;
  raise SocketClosed

(** [read_from_socket_loop (string_id chan flow socket_closed_unexpectedly)] infinite loop that reads continuously from established socket.
    Sending regular and ACK messages received from peer to channel. *)
let read_from_socket_loop string_id chan flow socket_closed_unexpectedly =
  try
    while true do
      if Atomic.get socket_closed_unexpectedly then
        handle_unexpected_socket_close flow;
      (* reader with internal buffer for efficient reads, its ~initial_size
         is 4096 by not specifying here but ~max_size can essentially be unbounded *)
      let buf_read = Eio.Buf_read.of_flow flow ~max_size:10000000 in
      let line = Eio.Buf_read.line buf_read in
      if String.starts_with ~prefix:"ACK>" line then
        let acknowledgement = String.sub line 4 (String.length line - 4) in
        Eio.Std.traceln "%s" acknowledgement
      else (
        print_endline line;
        Chan.send chan (MsgAck ("ACK>" ^ string_id ^ " says message received.")))
    done
  with End_of_file ->
    Atomic.set socket_closed_unexpectedly true;
    if string_id = client_string_id then (
      Eio.Std.traceln "Server disconnected.";
      Eio.Flow.close flow;
      exit 1)
    else (
      Eio.Std.traceln "Client disconnected.";
      Eio.Flow.close flow
      (* let the server close the connection as this fiber returns *))

(** [read_from_stdin_loop (chan)] infinite loop that reads continuously from stdin. *)
let read_from_stdin_loop chan socket_closed_unexpectedly =
  if Atomic.get socket_closed_unexpectedly then failwith "SOCKETCLOSED";
  while true do
    let line = read_line () in
    (* Send to message channel for writing to peer *)
    Chan.send chan (StdinRead line)
  done

(** [write_to_socket_endline (flow line)] writes `line` to flow with added endline. *)
let write_to_socket_endline flow line socket_closed_unexpectedly =
  if Atomic.get socket_closed_unexpectedly then
    handle_unexpected_socket_close flow;
  Eio.Buf_write.with_flow flow (fun writer ->
      Eio.Buf_write.string writer (line ^ "\n"))

(** [process_message_channel_and_write_to_socket_loop (string_id chan flow)] infinite loop that continually 
    processes the messages stored in the message channel, writes messages over the socket to peer,
    handles the cases of ACK messages and calculating round trip time for a message. *)
let process_message_channel_and_write_to_socket_loop string_id chan flow
    socket_closed_unexpectedly =
  let rec message_channel_loop () =
    if Atomic.get socket_closed_unexpectedly then
      handle_unexpected_socket_close flow;
    let chan_message = Chan.recv chan in
    match chan_message with
    | Mtime_clock time_counter ->
        let time_mtime_span = Mtime_clock.count time_counter in
        let time_int64 = Mtime.Span.to_uint64_ns time_mtime_span in
        Eio.Std.traceln "RTT for message: %Ld ns" time_int64;
        message_channel_loop ()
    | MsgAck line ->
        write_to_socket_endline flow line socket_closed_unexpectedly;
        message_channel_loop ()
    | StdinRead line ->
        let message_with_string_id = string_id ^ "> " ^ line in
        write_to_socket_endline flow message_with_string_id
          socket_closed_unexpectedly;
        let time_counter = Mtime_clock.counter () in
        Chan.send chan (Mtime_clock time_counter);
        message_channel_loop ()
  in
  message_channel_loop ()

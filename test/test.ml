open OUnit2
open Stdlib
module Server = Ochat.Server
module Client = Ochat.Client
module Testutils = Testutils

let assert_contains ~msg ~substr ~str =
  assert_bool msg
    (try
       ignore (Str.search_forward (Str.regexp_string substr) str 0);
       true
     with Not_found -> false)

let test_run_server _ =
  Testutils.log_message "Starting test_run_server";
  Testutils.with_process ~command:"./ochat --port=8081"
    (fun (_pid, output_file) ->
      Unix.sleep 1;
      let process_output = Testutils.read_file output_file in
      assert_contains
        ~msg:"Server output should contain 'Server listening on port 8081'"
        ~substr:"Server listening on port 8081" ~str:process_output)

let test_run_client_with_server _ =
  Testutils.log_message "Starting test_run_client";
  Testutils.with_process ~command:"./ochat --port 8080"
    (fun (_pid, _server_output_file) ->
      Unix.sleep 1;
      Testutils.with_process ~command:"./ochat --connect=localhost"
        (fun (_, client_output_file) ->
          Unix.sleep 1;
          let output = Testutils.read_file client_output_file in
          assert_contains
            ~msg:
              "Client output should contain 'connecting to server at \
               localhost:8080'"
            ~substr:"connecting to server at localhost:8080" ~str:output))

let test_send_and_receive_message _ =
  try
    Testutils.log_message "Starting test_send_and_receive_message";
    let server_message = "Hello!" in
    Testutils.with_process ~command:"./ochat --port=8081"
      ~stdin_input:[ server_message ] (fun (_, server_output) ->
        Unix.sleep 1;
        let client_messages = [ "Hello remote!"; "Nice seeing you here" ] in
        Testutils.with_process
          ~command:"./ochat --connect=localhost --port=8081"
          ~stdin_input:client_messages (fun (_, client_output) ->
            Unix.sleep 2;
            let server_output_content = Testutils.read_file server_output in
            let client_output_content = Testutils.read_file client_output in

            assert_contains
              ~msg:"Server output should contain the message from the client"
              ~substr:(List.hd client_messages) ~str:server_output_content;
            assert_contains
              ~msg:"Client output should contain the message from the server"
              ~substr:server_message ~str:client_output_content;
            assert_contains
              ~msg:"Server output should contain client ACK message"
              ~substr:"Client says message received" ~str:server_output_content;
            assert_contains
              ~msg:"Client output should contain server ACK message"
              ~substr:"Server says message received" ~str:client_output_content;
            assert_contains
              ~msg:"Server output should contain server RTT message"
              ~substr:"RTT for message:" ~str:server_output_content;
            assert_contains
              ~msg:"Client output should contain server RTT message"
              ~substr:"RTT for message:" ~str:client_output_content))
  with ex -> Testutils.log_message (Printexc.to_string ex)

let test_sigint_and_reconnect _ =
  Testutils.log_message "Starting test_sigint_and_reconnect";
  Testutils.with_process ~command:"./ochat --port=8080"
    (fun (_, server_output) ->
      Unix.sleep 1;
      Testutils.with_process ~command:"./ochat --connect=localhost"
        ~stdin_input:[ "Hello remote!" ] (fun (_, _client_output) ->
          Unix.sleep 1;
          Testutils.log_message "Sending SIGINT to client");

      Testutils.log_message "Client process terminated, starting reconnection";
      Testutils.with_process ~command:"./ochat --connect=localhost"
        ~stdin_input:[ "Hello again remote!" ] (fun (_, reconnect_output) ->
          Unix.sleep 2;
          let server_output_content = Testutils.read_file server_output in
          let reconnect_output_content = Testutils.read_file reconnect_output in

          assert_contains
            ~msg:
              "Server output should contain initial message from Alice to Bob"
            ~substr:"Hello remote!" ~str:server_output_content;
          assert_contains
            ~msg:
              "Server output should should contain message sent after \
               reconnection"
            ~substr:"Hello again remote!" ~str:server_output_content;
          assert_contains ~msg:"Reconnect output should confirm reconnection"
            ~substr:"Client connected to server at localhost:8080"
            ~str:reconnect_output_content))

let suite =
  "Ochat Tests"
  >::: [
         "run server" >:: test_run_server;
         "run client with server" >:: test_run_client_with_server;
         "send and receive message" >:: test_send_and_receive_message;
         "SIGINT and reconnect" >:: test_sigint_and_reconnect;
       ]

let () = run_test_tt_main suite

open OUnit2
open Unix
module Server = Ochat.Server
module Client = Ochat.Client

(* ran out of time to get this working, idea was to add unit tests here
   let test_connect_to_server =
     Eio_mock.Backend.run @@ fun () ->
     let mock_net = Eio_mock.Net.make "mocknet" in
     let mock_flow = Eio_mock.Flow.make "flow" in
     Eio_mock.Net.on_connect mock_net [ `Return mock_flow ];
     Eio_mock.Flow.on_read mock_flow
       [
         `Return "(packet 1)";
         `Yield_then (`Return "(packet 2)");
         `Raise End_of_file;
       ];
     (* let addr = `Tcp (Eio.Net.Ipaddr.V4.loopback, 8080)  *)
     let host = "localhost" in
     let port = "8080" in
     let mock_domain_mgr = Eio_mock.Domain_manager.create () in
     (* let buffer = Buffer.create 4096 in *)
     (* Client.connect_to_server (Eio.Flow.buffer_sink buffer); *)
     (* traceln "Main would print %S" (Buffer.contents buffer);; *)
     traceln "Mock client: connecting to server";
     Client.connect_to_server ~net:mock_net ~host ~port ~domain_mgr:mock_domain_mgr

   (* let test_chat_loop =
      Chat_loop.read_from_socket_loop *)
   let suite =
     "Client tests" >::: [ "connect_to_server" >:: test_connect_to_server ]

   let () = run_test_tt_main suite
*)

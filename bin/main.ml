module Server = Ochat.Server
module Client = Ochat.Client
module Cli = Ochat.Cli

(** [ochat (maybe_server_host maybe_server_port)] entry point for the ochat program, 
    sets up Eio event loop and environment and passes arguments if specified on the command line. *)
let ochat maybe_server_host maybe_server_port =
  let server_port = Option.value maybe_server_port ~default:"8080" in
  Eio_main.run @@ fun env ->
  let domain_mgr = Eio.Stdenv.domain_mgr env in
  let net = Eio.Stdenv.net env in

  let system_recommended_domain_count = Domain.recommended_domain_count () in
  if system_recommended_domain_count < 4 then
    Eio.Std.traceln
      "Warning: this application depends on having 4 cores. Recommended domain \
       (core) count for your system is: %d"
      system_recommended_domain_count;

  match maybe_server_host with
  | None ->
      Eio.Std.traceln "Running OChat in server mode.";
      Server.run_server ~net ~port:(int_of_string server_port) ~domain_mgr
  | Some maybe_server_host ->
      Eio.Std.traceln "Running OChat in client mode.";
      Client.connect_to_server ~net ~host:maybe_server_host ~port:server_port
        ~domain_mgr

let () = exit (Cli.run_cmd ochat)

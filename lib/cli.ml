open Cmdliner

(** Cmdliner bits to parse the command line arguments *)
let maybe_server_arg =
  let doc =
    "Connect to server specified by IP address or hostname. Port defaults to \
     8080 if not specified."
  in
  let env = Cmd.Env.info "OCHAT_SERVER" ~doc in
  let arg_info =
    Arg.info
      [ "s"; "c"; "connect"; "server" ]
      ~env ~docv:"OCHAT_SERVER_HOST" ~doc
  in
  Arg.value (Arg.opt (Arg.some Arg.string) None arg_info)

let maybe_port_arg =
  let doc = "Connect to server at specified port." in
  let env = Cmd.Env.info "OCHAT_PORT" ~doc in
  let arg_info = Arg.info [ "p"; "port" ] ~env ~docv:"OCHAT_SERVER_PORT" ~doc in
  Arg.value (Arg.opt (Arg.some Arg.string) None arg_info)

let create_cmd run_fn =
  let doc = "a simple one on one chat application" in
  let man =
    [ `S Manpage.s_bugs; `P "Email bug reports to <ilswyn@gmail.com>." ]
  in
  let info = Cmd.info "ochat" ~version:"0.3" ~doc ~man in
  Cmd.v info Term.(const run_fn $ maybe_server_arg $ maybe_port_arg)

let run_cmd run_fn =
  let cmd_with_run_fn = create_cmd run_fn in
  Cmd.eval cmd_with_run_fn

open Unix

let log_message message = Printf.printf "%s\n." message
let log_exception ex = log_message (Printexc.to_string ex)

let log_unix_error errno fn arg =
  log_message
    ("Unix error: " ^ Unix.error_message errno ^ " in " ^ fn ^ " with arg "
   ^ arg)

let read_file filename =
  try In_channel.with_open_bin filename In_channel.input_all
  with Sys_error err -> failwith ("Error reading file: " ^ err)

let send_sigint pid =
  try Unix.kill pid Sys.sigint with
  | Unix.Unix_error (errno, fn, arg) -> log_unix_error errno fn arg
  | e -> log_exception e

let safe_waitpid pid =
  try ignore (Unix.waitpid [] pid) with
  | Unix.Unix_error (errno, fn, arg) -> log_unix_error errno fn arg
  | e -> log_exception e

let run_command_and_capture_output command =
  let output_file, output_oc = Filename.open_temp_file "ochat_test" ".txt" in
  close_out output_oc;
  (* using output_file instead *)
  let stdin_read, stdin_write = pipe () in

  match fork () with
  (* child process *)
  | 0 -> (
      try
        (* redirect stdin_read to pipe *)
        close stdin_write;
        dup2 stdin_read stdin;
        close stdin_read;

        (* redirect output to output file*)
        let output_fd =
          openfile output_file [ O_WRONLY; O_CREAT; O_TRUNC ] 0o666
        in
        dup2 output_fd stdout;
        dup2 output_fd stderr;
        close output_fd;

        (* execute command *)
        let command_array =
          Str.split (Str.regexp " +") command |> Array.of_list
        in
        Unix.execvp command_array.(0) command_array
      with
      | Unix.Unix_error (errno, fn, arg) ->
          log_unix_error errno fn arg;
          exit 1
      | e ->
          log_message ("Unexpected error in child: " ^ Printexc.to_string e);
          exit 1)
  (* parent process *)
  | pid ->
      close stdin_read;
      let proc_out = out_channel_of_descr stdin_write in
      (pid, proc_out, output_file)
  | exception Unix.Unix_error (errno, fn, arg) ->
      log_unix_error errno fn arg;
      exit 1

let with_process ~command ?(stdin_input = []) run_fn =
  let pid, proc_out, output_file = run_command_and_capture_output command in

  let send_input () =
    List.iter (fun line -> output_string proc_out (line ^ "\n")) stdin_input;
    flush proc_out;
    Unix.sleep 1
  in

  let execute_callback_fn_with_output_file () =
    run_fn (pid, output_file);
    Unix.sleep 1;
    send_sigint pid;
    safe_waitpid pid;
    close_out_noerr proc_out
  in

  let cleanup () =
    send_sigint pid;
    safe_waitpid pid;
    close_out_noerr proc_out
  in

  try
    if not (List.is_empty stdin_input) then send_input ();
    execute_callback_fn_with_output_file ()
  with
  | Unix.Unix_error (errno, fn, arg) ->
      log_unix_error errno fn arg;
      cleanup ()
  | e ->
      log_exception e;
      cleanup ()

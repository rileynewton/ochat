val log_message : string -> unit
val log_exception : exn -> unit
val log_unix_error : Unix.error -> string -> string -> unit
val read_file : string -> string
val send_sigint : int -> unit
val safe_waitpid : int -> unit
val run_command_and_capture_output : string -> int * out_channel * string

val with_process :
  command:string -> ?stdin_input:string list -> (int * string -> unit) -> unit

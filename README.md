Some upfront notes on project effort / design choices:

* There were a number of tradeoffs made due to the limited amount of time / amount of learning needed to achieve this project. I didn't know any Ocaml to begin with and hadn't done any ground up networking programming since my CS degree 6-7 years ago.
* At first I started using Jane Street's Async library as that is what is mentioned in books like Real World Ocaml, then switched to Eio in the Ocaml multicore project as it effectively replaces the old use of "fake async" via monads and essentially deprecates the lwt & Jane Street Async libraries.
* Eio turned out to be a pretty opaque library with little documentation. Using it cost the most time. Doing this in the typical UNIX fashion would have been much easier.
* I wrote the application at first using only concurrency in a single domain via Eio.Net fibers, it worked very poorly (messages were not even close to real time, had to hit enter to receive etc. etc.) parallelism which works very well comparatively.
* Parallelism of course has many benefits depending on the vector of scalability and can be argued for here (though with the cost that the cores have to do this passing of messages with each other), I just wanted to explain my choices here. Adding an educational dimension to this project I am glad to have explored all that I did.

# Architecture

Both Server and Client run three parallel domains, each with continuously running loops:

###                            Server
```stdin loop            read socket loop       print messages/write to socket loop```

###                            Client
```stdin loop            read socket loop       print messages/write to socket loop```

# Known issues/improvements

* RTT time calculation is incorrect.
* Not truly agnostic to content type for input? Relies on reading one line from the user instead of multiple.
* Shouldn't there be a Eio library method of handling socket_closed_unexpectedly instead of introducing an atomic?
* Tests - I ran out of time here, got basic UNIX program tests working in test_ochat.ml. Didn't get the eio mocking working in test_eio.ml. I wanted to do some attempt at testing even if incomplete, of course this self contained program can be manually tested pretty easily, what I wrote is at least the beginning of a test framework.
* Handling Ctrl-C.

(* tried to have a coordinated SIGINT handling across domains but didn't have time to get it working properly

main.ml:
(* SIGINT handling *)
  (* let interrupted = Eio.Condition.create () in
  let handle_signal (_signum : int) =
    Eio.Condition.broadcast interrupted
  in
  Sys.set_signal Sys.sigint (Signal_handle handle_signal); *)

chat_loop fiber:
let clean_exit_on_interrupt string_id flow interrupted =
  Eio.Condition.loop_no_mutex interrupted (fun () ->
  Atomic.set socket_closed_unexpectedly true;
  Eio.Std.traceln "Caught SIGINT from %s. Exiting." string_id;
  Eio.Flow.close flow;
  exit 1) *)

  (* start fiber to watch for SIGINT *)
  Eio.Switch.run ~name:"watch_for_interrupt" @@ fun sw ->
  Eio.Fiber.fork ~sw (fun () -> run_fn_in_new_domain domain_mgr (fun () -> clean_exit_on_interrupt string_id flow interrupted));

# Typical README

### Requirements

`ochat` is a multicore application and cannot be run on single-core devices. As these devices are pretty much limited to embedded systems these days this seems a reasonable limitation. `ochat` expects three cores.

Runs in a UNIX shell (zsh, bash, etc.). Depends on having `opam` and `dune` installed as well as library dependencies listed in dune files (`eio` `eio_main` `cmdliner`). Ocaml 5.1 is needed for Eio.

To build: `make` or `opam exec -- dune build`
To build test executable: `make test`
To run test executable: `./ochat-test`
To run in server mode: `./ochat`
To run in client mode: `./ochat -s localhost`

Full command documentation with `--help`:
```
OCHAT(1)                         Ochat Manual                         OCHAT(1)

NAME
       ochat - a simple one on one chat application

SYNOPSIS
       ochat [--port=OCHAT_SERVER_PORT] [--connect=OCHAT_SERVER_HOST]
       [OPTION]…

OPTIONS
       -p OCHAT_SERVER_PORT, --port=OCHAT_SERVER_PORT (absent OCHAT_PORT env)
           Connect to server at specified port.

       -s OCHAT_SERVER_HOST, -c OCHAT_SERVER_HOST, --server=OCHAT_SERVER_HOST,
       --connect=OCHAT_SERVER_HOST (absent OCHAT_SERVER env)
           Connect to server specified by IP address or hostname. Port
           defaults to 8080 if not specified.

COMMON OPTIONS
       --help[=FMT] (default=auto)
           Show this help in format FMT. The value FMT must be one of auto,
           pager, groff or plain. With auto, the format is pager or plain
           whenever the TERM env var is dumb or undefined.

       --version
           Show version information.

EXIT STATUS
       ochat exits with:

       0   on success.

       123 on indiscriminate errors reported on standard error.

       124 on command line parsing errors.

       125 on unexpected internal errors (bugs).

ENVIRONMENT
       These environment variables affect the execution of ochat:

       OCHAT_PORT
           Connect to server at specified port.

       OCHAT_SERVER
           Connect to server specified by IP address or hostname. Port
           defaults to 8080 if not specified.

BUGS
       Email bug reports to <ilswyn@gmail.com>.

Ochat 0.8                                                             OCHAT(1)
```

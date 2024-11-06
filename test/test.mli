module Server = Ochat.Server
module Client = Ochat.Client
module Testutils = Testutils

val assert_contains : msg:string -> substr:string -> str:string -> unit
val test_run_server : 'a -> unit
val test_run_client_with_server : 'a -> unit
val test_send_and_receive_message : 'a -> unit
val test_sigint_and_reconnect : 'a -> unit
val suite : OUnitTest.test

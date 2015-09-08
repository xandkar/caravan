caravan
=======

A framework for black-box testing of arbitrary systems, in OCaml. Inspired by
Erlang/OTP's ["Common Test"][].

["Common Test"]: http://www.erlang.org/doc/apps/common_test/basics_chapter.html

Example
-------

Simple example, from [examples/hello](examples/hello), which does not actually
use state or does any IO; for an example that does - see:
[examples/riak_crud](examples/riak_crud).

A test case fails if it raises any exception. Log messages with level `info`
are always reported, while debug messages only show-up if the test case fails.

```ocaml
open Core.Std
open Async.Std

module Log  = Caravan.Log
module Test = Caravan.Test

let test_hello_pass =
  let case () ~log =
    Log.info  log "Info level is always reported.";
    Log.debug log "Asserting 2 + 2 = 4";
    assert (2 + 2 = 4);
    return ()
  in
  {Test.id = "test_hello_pass"; case; children = []}

let test_hello_fail =
  let case () ~log =
    Log.debug log "Asserting 2 + 2 = 5";
    assert (2 + 2 = 5);
    return ()
  in
  {Test.id = "test_hello_fail"; case; children = []}

let main () =
  let tests =
    [ test_hello_pass
    ; test_hello_fail
    ]
  in
  Caravan.run ~tests ~init_state:()

let () =
  don't_wait_for (main ());
  never_returns (Scheduler.go ())
```

![1 pass, 1 fail](screenshot.png)

open Core.Std
open Async.Std

module Test : sig
  type meta =
    { name        : string
    ; description : string
    }

  type 'state t =
    { meta : meta
    ; case : 'state -> 'state Deferred.t
    }
end

val run
  :  tests      : 'state Test.t list
  -> init_state : 'state
  -> unit Deferred.t

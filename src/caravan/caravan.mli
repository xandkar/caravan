open Core.Std
open Async.Std

module Log : sig
  type t

  val post : t -> msg:string -> unit
end

module Test : sig
  type meta =
    { name        : string
    ; description : string
    }

  type 'state t =
    { meta     : meta
    ; case     : 'state -> log:Log.t -> 'state Deferred.t
    ; children : 'state t list
    }
end

val run
  :  tests      : 'state Test.t list
  -> init_state : 'state
  -> unit Deferred.t

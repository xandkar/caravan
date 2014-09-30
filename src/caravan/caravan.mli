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

  type 'state add_children =
       'state t
    -> 'state t list
    -> 'state t

  val add_children : 'state add_children

  val (+) : 'state add_children
end

val run
  :  tests      : 'state Test.t list
  -> init_state : 'state
  -> unit Deferred.t

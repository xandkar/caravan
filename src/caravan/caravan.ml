open Core.Std
open Async.Std


module Test = struct
  type meta =
    { name        : string
    ; description : string
    }

  type 'state t =
    { meta : meta
    ; case : 'state -> 'state Deferred.t
    }

  type 'state result =
    { meta   : meta
    ; time   : float
    ; output : ('state, exn) Result.t
    }
end


let post_progress = function
  | Ok    _ -> printf "."
  | Error _ -> printf "F"

let reporter ~results_r =
  let report results =
    let module C = Textutils.Ascii_table.Column in
    let module T = Test in
    let rows = List.rev results in
    let columns =
      [ C.create_attr
          "Status"
          ( function
          | {T.output = Ok    _; _} -> [`Bright; `White; `Bg `Green], " PASS "
          | {T.output = Error _; _} -> [`Bright; `White; `Bg `Red  ], " FAIL "
          )
      ; C.create "Name"  (fun {T.meta={T.name; _}; _} -> name)
      ; C.create "Time"  (fun {T.time            ; _} -> sprintf "%.2f" time)
      ; C.create
          "Error"
          ~show:`If_not_empty
          ( function
          | {T.output = Ok    _; _} -> ""
          | {T.output = Error e; _} -> Exn.to_string e
          )
      ]
    in
    let table =
      Textutils.Ascii_table.to_string
        ~display:Textutils.Ascii_table.Display.tall_box
        ~bars:`Unicode
        columns
        rows
    in
    print_endline table;
    return ()
  in
  let rec gather results total_failures =
    Pipe.read results_r
    >>= function
      | `Eof  -> printf "\n\n%!";
                 return (results, total_failures)
      | `Ok r -> post_progress r.Test.output;
                 let total_failures =
                   match r.Test.output with
                   | Ok    _ ->      total_failures
                   | Error _ -> succ total_failures
                 in
                 gather (r :: results) total_failures
  in
  gather [] 0    >>= fun (results, total_failures) ->
  report results >>| fun () ->
  total_failures

let runner ~tests ~init_state:init ~results_w =
  let run state1 {Test.meta; Test.case} =
    let time_started = Unix.gettimeofday () in
    try_with ~extract_exn:true (fun () -> case state1)
    >>= fun output ->
    let result =
      let time = Unix.gettimeofday () -. time_started in
      {Test.meta; time; output}
    in
    Pipe.write_without_pushback results_w result;
    match output with
    | Ok state2 -> return state2
    | Error _   -> return state1
  in
  Deferred.List.fold tests ~init ~f:run >>| fun _state ->
  Pipe.close results_w

let run ~tests ~init_state =
  let results_r, results_w = Pipe.create () in
  don't_wait_for (runner   ~results_w ~tests ~init_state);
                  reporter ~results_r
  >>= fun total_failures ->
  exit total_failures

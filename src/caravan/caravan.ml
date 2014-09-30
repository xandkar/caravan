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
    let rows =
      let f2s = sprintf "%.2f" in
      let e2s = Exn.to_string in
      List.map (List.rev results) ~f:(function
      | {Test.meta={Test.name; _}; time; output = Ok _   } -> (`Pass, name, (f2s time), "")
      | {Test.meta={Test.name; _}; time; output = Error e} -> (`Fail, name, (f2s time), (e2s e))
      );
    in
    let module Table = Textutils.Ascii_table in
    let columns =
      [ Table.Column.create_attr
          "Status"
          ( function
          | `Pass, _, _, _ -> [`Bright; `White; `Bg `Green], " PASS "
          | `Fail, _, _, _ -> [`Bright; `White; `Bg `Red  ], " FAIL "
          )
      ; Table.Column.create "Name"  (fun (_, n,  _, _) -> n)
      ; Table.Column.create "Time"  (fun (_, _, tm, _) -> tm)
      ; Table.Column.create "Error" (fun (_, _,  _, e) -> e) ~show:`If_not_empty
      ]
    in
    let table =
      Table.to_string
        ~display:Table.Display.tall_box
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

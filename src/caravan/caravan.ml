open Core.Std
open Async.Std


module Test = struct
  type meta =
    { title       : string
    ; description : string
    }

  type 'state t =
    { meta : meta
    ; case : 'state -> 'state Deferred.t
    }

  type 'state result =
    | Pass of meta * float * 'state
    | Fail of meta * float * exn
end


let post_progress = function
  | Test.Pass _ -> printf "."
  | Test.Fail _ -> printf "F"

let reporter ~results_r =
  let report results =
    let rows =
      let f2s = sprintf "%.2f" in
      let e2s = Exn.to_string in
      List.map (List.rev results) ~f:(function
      | Test.Pass ({Test.title; _}, tm, _) -> (`Pass, title, (f2s tm), "")
      | Test.Fail ({Test.title; _}, tm, e) -> (`Fail, title, (f2s tm), (e2s e))
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
      ; Table.Column.create "Title" (fun (_, t,  _, _) -> t)
      ; Table.Column.create "Time"  (fun (_, _, tm, _) -> tm)
      ; Table.Column.create "Debug" (fun (_, _,  _, e) -> e) ~show:`If_not_empty
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
      | `Ok r -> post_progress r;
                 let total_failures =
                   match r with
                   | Test.Pass _ ->      total_failures
                   | Test.Fail _ -> succ total_failures
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
    >>| begin fun result ->
      let time_elapsed = Unix.gettimeofday () -. time_started in
      match result with
      | Ok state2 -> Test.Pass (meta, time_elapsed, state2)
      | Error exn -> Test.Fail (meta, time_elapsed, exn)
    end
    >>| fun result ->
    Pipe.write_without_pushback results_w result;
    match result with
    | Test.Pass (_, _, state2) -> state2
    | Test.Fail (_, _,      _) -> state1
  in
  Deferred.List.fold tests ~init ~f:run >>| fun _state ->
  Pipe.close results_w

let run ~tests ~init_state =
  let results_r, results_w = Pipe.create () in
  don't_wait_for (runner   ~results_w ~tests ~init_state);
                  reporter ~results_r
  >>= fun total_failures ->
  exit total_failures

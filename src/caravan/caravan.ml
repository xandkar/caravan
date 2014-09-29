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
    | Pass of meta * 'state
    | Fail of meta * exn
end


let post_progress =
  function
  | Test.Pass _ -> printf "."
  | Test.Fail _ -> printf "F"

let reporter ~results_r =
  let report results =
    let rows =
      List.map (List.rev results) ~f:(function
      | Test.Pass ({Test.title; _}, _) -> ("PASS", title, "")
      | Test.Fail ({Test.title; _}, e) -> ("FAIL", title, (Exn.to_string e))
      );
    in
    let module Table = Textutils.Ascii_table in
    let columns =
      [ Table.Column.create "Status"    (fun (s, _, _) -> s)
      ; Table.Column.create "Title"     (fun (_, t, _) -> t)
      ; Table.Column.create "Exception" (fun (_, _, e) -> e)
      ]
    in
    Table.output
      ~oc:stdout
      ~display:Table.Display.tall_box
      ~bars:`Unicode
      columns
      rows
  in
  let rec gather results =
    Pipe.read results_r
    >>= function
      | `Eof  -> printf "\n\n%!";
                 return results
      | `Ok r -> post_progress r;
                 gather (r :: results)
  in
  gather [] >>| fun results ->
  report results

let runner ~tests ~init_state:init ~results_w =
  let run state1 {Test.meta; Test.case} =
    try_with ~extract_exn:true (fun () -> case state1)
    >>| begin function
      | Ok state2 -> Test.Pass (meta, state2)
      | Error exn -> Test.Fail (meta, exn)
    end
    >>| fun result ->
    Pipe.write_without_pushback results_w result;
    match result with
    | Test.Pass (_, state2) -> state2
    | Test.Fail (_,      _) -> state1
  in
  Deferred.List.fold tests ~init ~f:run >>| fun _state ->
  Pipe.close results_w

let run ~tests ~init_state =
  let results_r, results_w = Pipe.create () in
  don't_wait_for (runner   ~results_w ~tests ~init_state);
                  reporter ~results_r

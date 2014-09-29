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
      | Test.Pass ({Test.title; _}, _) -> (`Pass, title, "")
      | Test.Fail ({Test.title; _}, e) -> (`Fail, title, (Exn.to_string e))
      );
    in
    let module Table = Textutils.Ascii_table in
    let columns =
      [ Table.Column.create_attr
          "Status"
          ( function
          | `Pass, _, _ -> [`Bright; `White; `Bg `Green], " PASS "
          | `Fail, _, _ -> [`Bright; `White; `Bg `Red  ], " FAIL "
          )
      ; Table.Column.create "Title"     (fun (_, t, _) -> t)
      ; Table.Column.create "Exception" (fun (_, _, e) -> e)
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
  >>= fun total_failures ->
  exit total_failures

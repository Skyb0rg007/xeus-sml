
(* Useful type definitions and default handler functions *)
structure Xeus =
struct

  (* Raise this error if you want to signal an error *)
  exception KernelError of { name : string, message : string }

  (* TODO
  structure Input =
  struct

  end
  *)

  structure Configure =
  struct
    val default : unit -> unit = fn () => ()
  end

  structure Shutdown =
  struct
    val default : unit -> unit = fn () => ()
  end

  structure Execute =
  struct
    (* Raise 'KernelError' for an error response *)
    type request =
      { execution_counter : int
      , code : string
      , silent : bool
      , store_history : bool
      , user_expressions : string (* Provided, but not used 99% of the time *)
      , allow_stdin : bool
      }
    type reply =
      { publish : (string * string) list (* mime-type * value *)
      }
    val default : request -> reply = fn _ => { publish = [] }
  end

  structure Complete =
  struct
    (* Raise 'KernelError' for error response *)
    type request =
      { code : string
      , cursor_pos : int
      }
    type reply =
      { matches : string list (* List of all possible matches *)
      (* Range of text replaced when match is accepted *)
      , cursor_start : int
      , cursor_end : int (* Normally same as cursor_pos *)
      }
    val default : request -> reply = fn { code, cursor_pos } => { matches = [], cursor_start = cursor_pos, cursor_end = cursor_pos }
  end

  structure Inspect =
  struct
    (* Rase 'KernelError' for error response *)
    datatype detail_level = Normal | Verbose
    type request =
      { code : string
      , cursor_pos : int
      , detail_level : detail_level
      }
    type reply =
      { data : (string * string) list
      }

    val default : request -> reply = fn _ => { data = [] }
  end

  structure KernelInfo =
  struct
    type request = unit
    type reply =
      { implementation : string
      , implementation_version : string
      , banner : string
      , help_links : { text : string, url : string } list
      , language_info :
        { name : string
        , version : string
        , mimetype : string
        , file_extension : string
        , pygments_lexer : string
        , codemirror_mode : string
        , nbconvert_exporter : string
        }
      }
    (* No default: implement yourself :) *)
  end

end

signature XEUS_KERNEL =
sig
  val configure : unit -> unit
  val shutdown : unit -> unit
  val execute : Xeus.Execute.request -> Xeus.Execute.reply
  val kernel_info : Xeus.KernelInfo.request -> Xeus.KernelInfo.reply
end



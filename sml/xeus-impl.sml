
(* Implementation details *)
structure XeusImpl =
struct

  fun json_escape str =
    String.translate
    (fn #"\b" => "\\b"
      | #"\f" => "\\f"
      | #"\n" => "\\n"
      | #"\r" => "\\r"
      | #"\t" => "\\t"
      | #"\"" => "\\\""
      | #"\\" => "\\\\"
      | c => String.str c)
    str

  fun error_status (exn as Xeus.KernelError { name, message }) =
        let
          val traceback =
            String.concatWith ","
            (List.map
            (fn s => "\""^json_escape s^"\"")
            (MLton.Exn.history exn))
        in
          Primitive.NullString8.fromString
          (String.concat
          [ "{\"status\":\"error\","
          , "\"ename\": \"" ^ json_escape name ^ "\","
          , "\"evalue\": \"" ^ json_escape message ^ "\","
          , "\"traceback\": [" ^ traceback ^ "]"
          , "}\000"
          ])
        end
    | error_status exn = error_status (Xeus.KernelError { name = exnName exn, message = exnMessage exn })

  val run = _import "xeus_sml_run" : Primitive.NullString8.t -> unit;

  structure MIME =
  struct
    fun validate [] = ()
      | validate ((k, v)::rest) =
          if List.exists (fn (k', _) => k = k') rest
          then raise Xeus.KernelError {name = "xeus-sml", message = "Repeating key \"" ^ String.toString k ^ "\" in mime-type"}
          else validate rest
    fun toJSON data =
      let
        fun field (k, v) =
          "\""^json_escape k^"\": \""^json_escape v^"\""
      in
        "{"^String.concatWith "," (List.map field data)^"}"
      end
  end

  structure Configure =
  struct
    val register = _export "xeus_sml_configure" : (unit -> unit) -> unit;
  end

  structure Shutdown =
  struct
    val register = _export "xeus_sml_shutdown" : (unit -> unit) -> unit;
  end

  structure Execute =
  struct
    type request = Xeus.Execute.request
    type reply = Xeus.Execute.reply
    type raw_request = int * CUtil.C_String.t * bool * bool * CUtil.C_String.t * bool
    type raw_reply = Primitive.NullString8.t

    val raw_register = _export "xeus_sml_execute" : (raw_request -> raw_reply) -> unit;

    fun wrap (f : request -> reply) : raw_request -> raw_reply =
      fn ( execution_counter, code, silent, store_history, user_expressions, allow_stdin ) =>
      let
        val req : request =
          { execution_counter = execution_counter
          , code = CUtil.C_String.toString code
          , silent = silent
          , store_history = store_history
          , user_expressions = CUtil.C_String.toString user_expressions
          , allow_stdin = allow_stdin
          }
        val { publish } : reply = f req
        val () = MIME.validate publish
      in
        Primitive.NullString8.fromString
        ("{ \"status\": \"ok\", \"publish\": " ^ MIME.toJSON publish ^ " }\000")
      end
      handle err => error_status err

    val register : (request -> reply) -> unit = raw_register o wrap
  end

  structure KernelInfo =
  struct

    type request = Xeus.KernelInfo.request
    type reply = Xeus.KernelInfo.reply
    type raw_request = unit
    type raw_reply = Primitive.NullString8.t

    val raw_register = _export "xeus_sml_kernel_info" : (raw_request -> raw_reply) -> unit;

    fun wrap (f : request -> reply) : raw_request -> raw_reply =
      fn () =>
      let
        val { implementation, implementation_version, banner, help_links, language_info = { name, version, mimetype, file_extension, pygments_lexer, codemirror_mode, nbconvert_exporter } } : reply = f ()
        val help_links =
          "["^
          String.concatWith "," (List.map (fn {text,url} => "{\"text\":\""^json_escape text^"\",\"url\":\""^url^"\"}") help_links)
          ^"]"
        val language_info = 
          String.concat
          [ "{"
          ,   "\"name\": \"" ^ json_escape name ^ "\","
          ,   "\"version\": \"" ^ json_escape version ^ "\","
          ,   "\"mimetype\": \"" ^ json_escape mimetype ^ "\","
          ,   "\"file_extension\": \"" ^ json_escape file_extension ^ "\","
          ,   "\"pygments_lexer\": \"" ^ json_escape pygments_lexer ^ "\","
          ,   "\"codemirror_mode\": \"" ^ json_escape codemirror_mode ^ "\","
          ,   "\"nbconvert_exporter\": \"" ^ json_escape nbconvert_exporter ^ "\""
          , "}"
          ]
      in
        Primitive.NullString8.fromString
        (String.concat
        [ "{"
        ,   "\"implementation\": \"" ^ json_escape implementation ^ "\","
        ,   "\"implementation_version\": \"" ^ json_escape implementation_version ^ "\","
        ,   "\"banner\": \"" ^ json_escape banner ^ "\","
        ,   "\"help_links\": " ^ help_links ^ ","
        ,   "\"language_info\": " ^ language_info
        , "}\000"
        ])
      end
      handle err => error_status err

    val register : (request -> reply) -> unit = raw_register o wrap

  end

end

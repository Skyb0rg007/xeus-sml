(* vim: set ft=sml: *)

functor XeusKernelFn(Kernel : XEUS_KERNEL) :>
sig
  (* Run using command-line args, assuming the second arg is the connection file *)
  val run : unit -> unit
  (* Run using a specific connection file *)
  val run_with_configfile : string -> unit
end =
struct

  fun register () =
    ( XeusImpl.Configure.register Kernel.configure
    ; XeusImpl.Shutdown.register Kernel.shutdown
    ; XeusImpl.Execute.register Kernel.execute
    ; XeusImpl.KernelInfo.register Kernel.kernel_info
    (* ; XeusImpl.Complete.register Kernel.complete *)
    )

  fun run_with_configfile file =
    ( register ()
    ; XeusImpl.run (Primitive.NullString8.fromString (file ^ "\000"))
    )

  fun run () =
    let
      val args = CommandLine.arguments ()
      val file =
        case args
          of [] => "connection.json"
           | [_] => "connection.json"
           | (_::f::_) => f
    in
      run_with_configfile file
    end

end

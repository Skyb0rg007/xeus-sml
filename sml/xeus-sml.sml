
val foo = _import "foo" : unit -> int;

val () = TextIO.print ("foo() --> " ^ Int.toString (foo ()) ^ "\n")


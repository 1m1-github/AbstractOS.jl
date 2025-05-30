@api const REPL_OutputDevice = """
this knowledge allows you to communicate with the user on the REPL.
Use `put!(outputs[:REPL], v::String)` to print a `String` to `stdout`, displayed on the main `REPL`
"""

import REPL

import Base.put!
struct REPLOutputDevice <: OutputDevice end
@api put!(::REPLOutputDevice, v::String) = println(stdout, v)
describe(::REPLOutputDevice) = REPL_OutputDevice

outputs[:REPL] = REPLOutputDevice()

term = REPL.Terminals.TTYTerminal("AbstractOS", stdin, stdout, stderr)
repl = REPL.LineEditREPL(term, true)
REPL.run_repl(repl)
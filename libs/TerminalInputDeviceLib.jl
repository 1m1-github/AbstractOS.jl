## Terminal lib

import Base.take!, Base.put!, Base.print

struct StdInTerminal <: InputDevice end
stdInTerminal = StdInTerminal()
push!(inputDevices, stdInTerminal)
take!(t::StdInTerminal) = readline(stdin)
print(t::StdInTerminal) = "StdInTerminal reads from stdin"

struct StdOutTerminal <: OutputDevice end
stdOutTerminal = StdOutTerminal()
push!(outputDevices, stdOutTerminal)
put!(t::StdOutTerminal, v) = print(stdout, v)
print(t::StdOutTerminal) = "StdOutTerminal writes to stdout"
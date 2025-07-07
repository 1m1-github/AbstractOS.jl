using HTTP, JSON3, HTTP.WebSockets

@api const BrowserWebSocketDescription =
"""
from the browser, you can send julia commands back to the server, using the websocket.
if the websocket receives anything starting with `julia>`, then the rest of it `eval`ed as Julia code.
"""

function start_websocket(ip, port, BrowserOutputDeviceType)
    @show ip, port, BrowserOutputDeviceType # DEBUG
    WebSockets.listen(ip, port) do ws
        if haskey(outputs, :Browser)
            push!(outputs[:Browser].websockets, ws)
        else
            outputs[:Browser] = BrowserOutputDeviceType([ws])
        end
        for command in ws
            @show "command", command # DEBUG
            if startswith(lowercase(command), "julia>")
                julia_command = command[length("julia>")+1:end]
                eval(Meta.parse(julia_command))
                continue
            end
            put!(inputs[:Browser].command_channel, command)
        end
        @show "after command" # DEBUG
    end
    @show "after ws" # DEBUG
end
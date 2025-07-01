using HTTP, JSON3, HTTP.WebSockets

function start_websocket(ip, port, BrowserOutputDeviceType)
    @show ip, port, BrowserOutputDeviceType
    WebSockets.listen(ip, port) do ws
        if haskey(outputs, :Browser)
            push!(outputs[:Browser].websockets, ws)
        else
            outputs[:Browser] = BrowserOutputDeviceType([ws])
        end
        for command in ws
            @show "command", command
            if startswith(lowercase(command), "julia>")
                julia_command = command[length("julia>")+1:end]
                eval(Meta.parse(julia_command))
                continue
            end
            put!(inputs[:Browser].command_channel, command)
        end
        @show "after command"
    end
    @show "after ws"
end
using HTTP, JSON3, HTTP.WebSockets

@api const BrowserWebSocketDescription =
"""
from the browser, you can send julia commands back to the server, using the websocket (`ws`).
if the websocket receives anything starting with `julia>`, then the rest of it `eval`ed as Julia code.
else it is `put!` to `outputs[:Browser]`, which contains the `content_1M1` `div` `HTML` and the user command.
"""

# function start_websocket(ip, port, BrowserOutputDeviceType)
#     @show ip, port, BrowserOutputDeviceType
#     WebSockets.listen(ip, port) do ws
#         @show "ws"
#         if haskey(outputs, :Browser)
#             push!(outputs[:Browser].websockets, ws)
#         else
#             outputs[:Browser] = BrowserOutputDeviceType([ws])
#         end
#         for command in ws
#             @show "command", command
#             if startswith(lowercase(command), "julia>")
#                 julia_command = command[length("julia>")+1:end]
#                 eval(Meta.parse(julia_command))
#                 continue
#             end
#             put!(inputs[:Browser].command_channel, command)
#         end
#         @show "after command"
#     end
#     @show "after ws"
# end

function start_websocket(host, port, BrowserOutputDeviceType)
    @show host, port, BrowserOutputDeviceType # DEBUG
    WebSockets.listen(host, port) do websocket
        if haskey(outputs, :Browser)
            push!(outputs[:Browser].websockets, websocket)
        else
            outputs[:Browser] = BrowserOutputDeviceType([websocket])
        end
            for html_and_command_string in websocket
            @show "websocket" # DEBUG
            html_and_command = JSON3.read(html_and_command_string)
            command = html_and_command.command
            @show "command", command # DEBUG
            global content_1M1
            @show content_1M1, html_and_command.content_1M1 # DEBUG
            content_1M1 = html_and_command.content_1M1
            if startswith(lowercase(command), "julia>")
                julia_command = command[length("julia>")+1:end]
                eval(Meta.parse(julia_command))
                continue
            end
            put!(inputs[:Browser].command_channel, """the following is the current html of the `content_1M1` div from the browser and after it the command of the user. you thus use javascript to precisely manipulate the div:\n$(content_1M1)\nuser command:\n$command""")
        end
        @show "after command" # DEBUG
    end
    @show "after ws" # DEBUG
end

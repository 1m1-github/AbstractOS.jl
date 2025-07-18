using HTTP, JSON3, HTTP.WebSockets

@api const BrowserWebSocketDescription =
"""
from the browser, you can send julia commands back to the server, using the `websocket`.
if the websocket receives anything starting with `julia>`, then the rest of it `eval`ed as Julia code.
else it is `put!` to `outputs[:Browser]`, which contains the `content_1M1` `div` `HTML` and the user command.
"""

function start_websocket(host, port, BrowserOutputDeviceType)
    @debug host, port, BrowserOutputDeviceType # DEBUG
    WebSockets.listen(host, port) do websocket
        @debug "websocket" # DEBUG
        if haskey(outputs, :Browser)
            @debug "haskey(outputs, :Browser)", length(outputs[:Browser].websockets) # DEBUG
            push!(outputs[:Browser].websockets, websocket)
        else
            @debug "!haskey(outputs, :Browser), new outputs[:Browser]" # DEBUG
            outputs[:Browser] = BrowserOutputDeviceType([websocket])
        end
        for html_and_command_string in websocket
            @debug "html_and_command_string" # DEBUG
            html_and_command = JSON3.read(html_and_command_string)
            command = html_and_command.command
            @debug "command", command # DEBUG
            global content_1M1
            @debug length(content_1M1), length(html_and_command.content_1M1) # DEBUG
            content_1M1 = html_and_command.content_1M1
            if startswith(lowercase(command), "julia>")
                @debug "julia" # DEBUG
                julia_command = command[length("julia>")+1:end]
                eval(Meta.parse(julia_command))
                continue
            end
            @debug "put!ing to browser" # DEBUG
            html_and_command_string = """the following is the current html of the 'content_1M1' div from the browser and after it the command of the user. you thus use javascript to precisely manipulate the div:\ndiv with id='content_1M1':\n$(content_1M1)\nuser command:\n$command"""
            put!(inputs[:Browser].command_channel, html_and_command_string)
            @debug "after put!ing to browser" # DEBUG
        end
        @debug "after command" # DEBUG
    end
    @debug "after websocket" # DEBUG
end

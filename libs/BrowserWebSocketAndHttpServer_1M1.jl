function start_websocket(ip, port, BrowserOutputDeviceType)
    WebSockets.listen(ip, port) do ws
        outputs[:Browser] = BrowserOutputDeviceType(ws)
        for command in ws
            if startswith(lowercase(command), "julia>")
                julia_command = command[length("julia>")+1:end]
                eval(Meta.parse(julia_command))
                continue
            end
            put!(inputs[:Browser].command_channel, command)
        end
    end
end

struct Command
    value::String
end
using HTTP, JSON3
function handler(req, html_file_path)
    html_file = read(html_file_path, String)
    if haskey(ENV, "HEYGEN_API_KEY")
        html_file = replace(html_file, """ENV["HEYGEN_API_KEY"]""" => ENV["HEYGEN_API_KEY"])
    end
    input_div_file = read("libs/BrowserInputDiv_1M1.html", String)  
    html_file = replace(html_file, """<div id="input"></div>""" => input_div_file)
    req.method == "GET" && return HTTP.Response(200, html_file)
    HTTP.Response(404, "not found")
end
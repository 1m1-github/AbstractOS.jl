@api const Browser_OutputDevice = """
                                  connects to a browser. the browser gives you a graphic and an audio communication channel with the user.
                                  `put!(device::BrowserOutputDevice, div_content::String, audio_message::String)` will overwrite the `innerHTML` of the `div` with `id` "content" and will have the browser speak `audio_message`. nothing besides this content div is visible to the user.
                                  the html/css/js that you `put!` to the browser can also run code back in the system by sending Julia code via the websocket.
                                  anything sent to the websocket that begins with `julia>` will be executed (`eval`), whilst everything else is sent to `run`. this allows e.g. html buttons to run code back on the system/server/OS.
                                  and the OS (Julia) can run code in the browser simply by adding `script` elements in the `div_content`, e.g. to update data for the browser.
                                  this establishes a 2-way connection between the OS (Julia server) and the browser. Julia tasks could send updates or run code in the browser and the user/browser can run Julia code back in the server.
                                  generally, the browser is just a peripheral, the main code should be running in Julia (in the OS, in the server) and the browser can be showing data from the system as well as a way for the user to control the system; but all the important code (e.g. running an agent) should be happening in the OS (Julia/server), because the browser can be closed, but the system should keep running.
                                  currently, you cannot see the log or errors in the browser, so try to keep browser code simple and you could use try catch to communicate errors in the (Julia) system to the browser.
                                  """

using HTTP.WebSockets
@api struct BrowserOutputDevice <: OutputDevice
    ws::WebSocket
end

using JSON3
import Base.put!
@api function put!(device::BrowserOutputDevice, div_content::String, audio_message::String)
    msg = Dict(
        :div_content => div_content,
        :audio_message => audio_message,
    )
    !WebSockets.isclosed(device.ws) && send(device.ws, JSON3.write(msg))
end
import Base.take!

describe(::BrowserOutputDevice) = Browser_OutputDevice
inputs[:Browser] = ChannelStringInputDevice()

function start_websocket()
    WebSockets.listen("0.0.0.0", 8081) do ws
        outputs[:Browser] = BrowserOutputDevice(ws)
        for command in ws
            if startswith(lowercase(command), "julia>")
                julia_command = command[length("julia>")+1:end]
                return eval(julia_command)
            end
            put!(inputs[:Browser].command_channel, command)
        end
    end
end
@async start_websocket()

struct Command
    value::String
end
using HTTP, JSON3
function handler(req)
    @show "handler"
    # req.method == "GET" && return HTTP.Response(200, read("libs/Browser_OutputDevice_1M1.html", String))
    html_file = read("libs/BrowserHeyGen_OutputDevice_1M1.html", String)
    html_file = replace(html_file, """ENV["HEYGEN_API_KEY"]""" => ENV["HEYGEN_API_KEY"])
    req.method == "GET" && return HTTP.Response(200, html_file)
    HTTP.Response(404, "not found")
end
@async HTTP.serve(handler, "0.0.0.0", 8080)

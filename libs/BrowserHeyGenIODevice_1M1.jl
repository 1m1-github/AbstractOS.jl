# https://app.heygen.com
# https://1m1.fly.dev
# https://1m1.fly.dev?julia=@show memory
# https://1m1.fly.dev/yourcomputernumber
# https://1m1.fly.dev/yourcomputernumber?julia=somejuliacode

# set 
# @show ENV["HEYGEN_API_KEY"]
# @show ENV["ABSTRACTOS_HTTP_IP"]
# @show ENV["ABSTRACTOS_HTTP_PORT"]
# @show ENV["ABSTRACTOS_OUTER_WEBSOCKET_PROTOCOL"]
# @show ENV["ABSTRACTOS_OUTER_WEBSOCKET_IP"]
# @show ENV["ABSTRACTOS_INNER_WEBSOCKET_IP"]
# @show ENV["ABSTRACTOS_WEBSOCKET_PORT"]

# previous_div_content = ""

learn(:BrowserHeyGenOutputDevice, read("libs/BrowserHeyGenOutputDevice.jl", String))

learn(:BrowserWebSocket, read("libs/BrowserWebSocket_1M1.jl", String))
@async start_websocket(ENV["ABSTRACTOS_INNER_WEBSOCKET_IP"], parse(Int, ENV["ABSTRACTOS_WEBSOCKET_PORT"]), BrowserAudioOutputDevice)

learn(:BrowserSignalNextRunning, read("libs/BrowserSignalNextRunning_1M1.jl", String))
@async start_browser_signal_next_running()

include("libs/find_julia_code_1M1.jl")
function handle(req)
    input = read("libs/BrowserInputDiv_1M1.html", String)
    # input = replace(input, "// code for audio" => "if (Object.hasOwn(data, 'audio_message')) sendTask(data.audio_message)")
    input = replace(input, """\$(ENV["ABSTRACTOS_OUTER_WEBSOCKET_PROTOCOL"])://\$(ENV["ABSTRACTOS_OUTER_WEBSOCKET_IP"]):\$(ENV["ABSTRACTOS_WEBSOCKET_PORT"])""" => """$(ENV["ABSTRACTOS_OUTER_WEBSOCKET_PROTOCOL"])://$(ENV["ABSTRACTOS_OUTER_WEBSOCKET_IP"]):$(ENV["ABSTRACTOS_WEBSOCKET_PORT"])""")
    avatar = read("libs/BrowserHeyGenAvatarDiv_1M1.html", String)
    avatar = replace(avatar, """ENV["HEYGEN_API_KEY"]""" => ENV["HEYGEN_API_KEY"])
    julia_code = find_julia_code(req.target)
    global previous_div_content
    content = isempty(julia_code) ? previous_div_content : string(eval(Meta.parse(julia_code)))
    content = """<div id="content">$content</div>"""
    signals = """<div id="signals_next_running" style="display: inline-block; background-color: #ff4444; color: white; width: 40px; height: 40px; border-radius: 50%; text-align: center; line-height: 40px; font-size: 24px; font-weight: bold; box-shadow: 0 2px 5px rgba(0,0,0,0.2); margin: 10px;">✕</div>"""
    html = """<html><body>$signals$content$input$avatar</body></html>"""
    HTTP.Response(200, html)
end
@async HTTP.serve(handle, ENV["ABSTRACTOS_HTTP_IP"], parse(Int, ENV["ABSTRACTOS_HTTP_PORT"]))

learn(:BrowserHTMLServer, read("libs/BrowserHTMLServer_1M1.jl", String))

learn(:BrowserInputDevice, read("libs/BrowserInputDevice_1M1.jl", String))
inputs[:Browser] = BrowserInputDevice()
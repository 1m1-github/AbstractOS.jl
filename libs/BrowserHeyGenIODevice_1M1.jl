using HTTP.WebSockets, JSON3

# https://app.heygen.com
# https://1m1.fly.dev
# https://1m1.fly.dev?julia=@log memory
# https://1m1.fly.dev/yourcomputernumber
# https://1m1.fly.dev/yourcomputernumber?julia=somejuliacode

# set 
# @log ENV["HEYGEN_API_KEY"]
# @log ENV["ABSTRACTOS_HTTP_IP"]
# @log ENV["ABSTRACTOS_HTTP_PORT"]
# @log ENV["ABSTRACTOS_OUTER_WEBSOCKET_PROTOCOL"]
# @log ENV["ABSTRACTOS_OUTER_WEBSOCKET_IP"]
# @log ENV["ABSTRACTOS_INNER_WEBSOCKET_IP"]
# @log ENV["ABSTRACTOS_WEBSOCKET_PORT"]


previous_div_content = ""

learn(:BrowserHeyGenOutputDevice, read("libs/BrowserHeyGenOutputDevice_1M1.jl", String))

learn(:BrowserWebSocket, read("libs/BrowserWebSocket_1M1.jl", String))
@async start_websocket(ENV["ABSTRACTOS_INNER_WEBSOCKET_IP"], parse(Int, ENV["ABSTRACTOS_WEBSOCKET_PORT"]), BrowserHeyGenOutputDevice)

# learn(:BrowserSignals, read("libs/BrowserSignals_1M1.jl", String))
# @async start_browser_signal_next_running()

# learn(:BrowserHTTPServer, read("libs/BrowserHTTPServer_1M1.jl", String))

# learn(:BrowserInputDevice, read("libs/BrowserInputDevice_1M1.jl", String))
# inputs[:Browser] = BrowserInputDevice()
inputs[:Browser] = ChannelStringInputDevice()

include("libs/find_julia_code_1M1.jl")
function handle(req)
    input = read("libs/BrowserInputDiv_1M1.html", String)
    input = replace(input, "// code for audio" => "sendTask(data.audio_message)")
    input = replace(input, """\$(ENV["ABSTRACTOS_OUTER_WEBSOCKET_PROTOCOL"])://\$(ENV["ABSTRACTOS_OUTER_WEBSOCKET_IP"]):\$(ENV["ABSTRACTOS_WEBSOCKET_PORT"])""" => """$(ENV["ABSTRACTOS_OUTER_WEBSOCKET_PROTOCOL"])://$(ENV["ABSTRACTOS_OUTER_WEBSOCKET_IP"]):$(ENV["ABSTRACTOS_WEBSOCKET_PORT"])""")
    avatar = read("libs/BrowserHeyGenAvatarDiv_1M1.html", String)
    avatar = replace(avatar, """ENV["HEYGEN_API_KEY"]""" => ENV["HEYGEN_API_KEY"])
    julia_code = find_julia_code(req.target)
    global previous_div_content
    content = isempty(julia_code) ? previous_div_content : string(eval(Meta.parse(julia_code)))
    content = """<div id="content_1M1">$content</div>"""
    html = """<html><body>$content$input$avatar</body></html>"""
    # html = """<html><body>$content$input</body></html>"""
    HTTP.Response(200, html)
end
@async HTTP.serve(handle, ENV["ABSTRACTOS_HTTP_IP"], parse(Int, ENV["ABSTRACTOS_HTTP_PORT"]))
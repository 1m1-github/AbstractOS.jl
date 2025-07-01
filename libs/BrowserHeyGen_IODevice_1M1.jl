# https://app.heygen.com

# set 
@show ENV["HEYGEN_API_KEY"]
@show ENV["ABSTRACTOS_HTTP_IP"]
@show ENV["ABSTRACTOS_HTTP_PORT"]
@show ENV["ABSTRACTOS_OUTER_WEBSOCKET_IP"]
@show ENV["ABSTRACTOS_INNER_WEBSOCKET_IP"]
@show ENV["ABSTRACTOS_WEBSOCKET_PORT"]

learn(:BrowserAudio_OutputDevice, read("libs/BrowserAudio_OutputDevice_1M1.jl", String))
describe(::BrowserAudioOutputDevice) = BrowserAudio_OutputDevice
inputs[:Browser] = ChannelStringInputDevice()

learn(:BrowserWebSocket, read("libs/BrowserWebSocket_1M1.jl", String))
@async start_websocket(ENV["ABSTRACTOS_INNER_WEBSOCKET_IP"], parse(Int, ENV["ABSTRACTOS_WEBSOCKET_PORT"]), BrowserAudioOutputDevice)
function handle(req)
    html = """<html><body><div id="content"></div>inputavatar</body></html>"""
    input_html = read("libs/BrowserInputDiv_1M1.html", String)
    input_html = replace(input_html, "// code for audio" => "sendTask(data.audio_message)")
    input_html = replace(input_html, """\$(ENV["ABSTRACTOS_OUTER_WEBSOCKET_IP"]):\$(ENV["ABSTRACTOS_WEBSOCKET_PORT"])""" => """$(ENV["ABSTRACTOS_OUTER_WEBSOCKET_IP"]):$(ENV["ABSTRACTOS_WEBSOCKET_PORT"])""")
    avatar_html = read("libs/BrowserHeyGenAvatarDiv_1M1.html", String)
    avatar_html = replace(avatar_html, """ENV["HEYGEN_API_KEY"]""" => ENV["HEYGEN_API_KEY"])
    html = replace(html, "avatar" => avatar_html, "input" => input_html)
    HTTP.Response(200, html)
end
@async HTTP.serve(handle, ENV["ABSTRACTOS_HTTP_IP"], parse(Int, ENV["ABSTRACTOS_HTTP_PORT"]))
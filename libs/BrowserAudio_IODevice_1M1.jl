# set 
# ENV["ABSTRACTOS_HTTP_IP"]
# ENV["ABSTRACTOS_HTTP_PORT"]
# ENV["ABSTRACTOS_OUTER_WEBSOCKET_PROTOCOL"]
# ENV["ABSTRACTOS_OUTER_WEBSOCKET_IP"]
# ENV["ABSTRACTOS_INNER_WEBSOCKET_IP"]
# ENV["ABSTRACTOS_WEBSOCKET_PORT"]

previous_div_content = ""

learn(:BrowserAudio_OutputDevice, read("libs/BrowserAudio_OutputDevice_1M1.jl", String))
describe(::BrowserAudioOutputDevice) = BrowserAudio_OutputDevice
inputs[:Browser] = ChannelStringInputDevice()

learn(:BrowserWebSocket, read("libs/BrowserWebSocket_1M1.jl", String))
@async start_websocket(ENV["ABSTRACTOS_INNER_WEBSOCKET_IP"], parse(Int, ENV["ABSTRACTOS_WEBSOCKET_PORT"]), BrowserAudioOutputDevice)

include("libs/find_julia_code_1M1.jl")
function handle(req)
    input = read("libs/BrowserInputDiv_1M1.html", String)
    input = replace(input, "// code for audio" => "speechSynthesis.speak(new SpeechSynthesisUtterance(data.audio_message))")
    input = replace(input, """\$(ENV["ABSTRACTOS_OUTER_WEBSOCKET_PROTOCOL"])://\$(ENV["ABSTRACTOS_OUTER_WEBSOCKET_IP"]):\$(ENV["ABSTRACTOS_WEBSOCKET_PORT"])""" => """$(ENV["ABSTRACTOS_OUTER_WEBSOCKET_PROTOCOL"])://$(ENV["ABSTRACTOS_OUTER_WEBSOCKET_IP"]):$(ENV["ABSTRACTOS_WEBSOCKET_PORT"])""")
    julia_code = find_julia_code(req.target)
    global previous_div_content
    content = isempty(julia_code) ? previous_div_content : string(eval(Meta.parse(julia_code)))
    content = """<div id="content">$content</div>"""
    html = """<html><body>$content$input</body></html>"""
    HTTP.Response(200, html)
end
@async HTTP.serve(handle, ENV["ABSTRACTOS_HTTP_IP"], parse(Int, ENV["ABSTRACTOS_HTTP_PORT"]))

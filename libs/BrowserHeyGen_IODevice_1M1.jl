# https://app.heygen.com
# https://1m1.fly.dev
# https://1m1.fly.dev?julia=@show memory

# set 
# @show ENV["HEYGEN_API_KEY"]
# @show ENV["ABSTRACTOS_HTTP_IP"]
# @show ENV["ABSTRACTOS_HTTP_PORT"]
# @show ENV["ABSTRACTOS_OUTER_WEBSOCKET_IP"]
# @show ENV["ABSTRACTOS_INNER_WEBSOCKET_IP"]
# @show ENV["ABSTRACTOS_WEBSOCKET_PORT"]

learn(:BrowserAudio_OutputDevice, read("libs/BrowserAudio_OutputDevice_1M1.jl", String))
describe(::BrowserAudioOutputDevice) = BrowserAudio_OutputDevice
inputs[:Browser] = ChannelStringInputDevice()

learn(:BrowserWebSocket, read("libs/BrowserWebSocket_1M1.jl", String))
@async start_websocket(ENV["ABSTRACTOS_INNER_WEBSOCKET_IP"], parse(Int, ENV["ABSTRACTOS_WEBSOCKET_PORT"]), BrowserAudioOutputDevice)

function find_julia_code(query_param)
    query_param = HTTP.unescapeuri(query_param)
    !startswith(query_param, "/?") && return ""``
    query_params = split(query_param[length("/?")+1:end], '&')
    julia_query_param = filter(qp -> startswith(qp, "julia="), query_params)
    isempty(julia_query_param) && return ""
    first(julia_query_param)[length("julia=")+1:end]
end
function handle(req)
    input = read("libs/BrowserInputDiv_1M1.html", String)
    input = replace(input, "// code for audio" => "sendTask(data.audio_message)")
    input = replace(input, """\$(ENV["ABSTRACTOS_OUTER_WEBSOCKET_IP"]):\$(ENV["ABSTRACTOS_WEBSOCKET_PORT"])""" => """$(ENV["ABSTRACTOS_OUTER_WEBSOCKET_IP"]):$(ENV["ABSTRACTOS_WEBSOCKET_PORT"])""")
    avatar = read("libs/BrowserHeyGenAvatarDiv_1M1.html", String)
    avatar = replace(avatar, """ENV["HEYGEN_API_KEY"]""" => ENV["HEYGEN_API_KEY"])
    julia_code = find_julia_code(req.target)
    content = isempty(julia_code) ? "" : string(eval(Meta.parse(julia_code)))
    content = """<div id="content">$content</div>"""
    html = """<html><body>$content$input$avatar</body></html>"""
    HTTP.Response(200, html)
end
@async HTTP.serve(handle, ENV["ABSTRACTOS_HTTP_IP"], parse(Int, ENV["ABSTRACTOS_HTTP_PORT"]))
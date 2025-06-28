learn(:BrowserAudio_OutputDevice, read("libs/BrowserAudio_OutputDevice_1M1.jl", String))
describe(::BrowserAudioOutputDevice) = BrowserAudio_OutputDevice
inputs[:Browser] = ChannelStringInputDevice()

learn(:BrowserWebSocket, read("libs/BrowserWebSocket_1M1.jl", String))
@async start_websocket("127.0.0.1", 8081, BrowserAudioOutputDevice)
html = """<html><body><div id="content"></div>input</body></html>"""
input_html = read("libs/BrowserInputDiv_1M1.html", String)
input_html = replace(input_html, "// code for audio" => "speechSynthesis.speak(new SpeechSynthesisUtterance(data.audio_message));")
html = replace(html, "input" => input_html)
@async HTTP.serve(req -> HTTP.Response(200, html), "127.0.0.1", 8080)

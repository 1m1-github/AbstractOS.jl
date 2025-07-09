# set 
# ENV["ABSTRACTOS_INNER_WEBSOCKET_IP"]
# ENV["ABSTRACTOS_WEBSOCKET_PORT"]

learn(:BrowserAudioOutputDevice, read("libs/BrowserAudioOutputDevice_1M1.jl", String))

learn(:BrowserWebSocket, read("libs/BrowserWebSocket_1M1.jl", String))
@async start_websocket(ENV["ABSTRACTOS_INNER_WEBSOCKET_IP"], parse(Int, ENV["ABSTRACTOS_WEBSOCKET_PORT"]), BrowserAudioOutputDevice)

learn(:BrowserSignals, read("libs/BrowserSignals_1M1.jl", String))
@async start_browser_signal_next_running()

learn(:BrowserHTMLServer, read("libs/BrowserHTTPServer_1M1.jl", String))

learn(:BrowserInputDevice, read("libs/BrowserInputDevice_1M1.jl", String))
inputs[:Browser] = BrowserInputDevice()
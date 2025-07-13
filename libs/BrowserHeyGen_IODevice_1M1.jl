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

learn(:BrowserHeyGenOutputDevice, read("libs/BrowserHeyGenOutputDevice_1M1.jl", String))

learn(:BrowserWebSocket, read("libs/BrowserWebSocket_1M1.jl", String))
@async start_websocket(ENV["ABSTRACTOS_INNER_WEBSOCKET_IP"], parse(Int, ENV["ABSTRACTOS_WEBSOCKET_PORT"]), BrowserAudioOutputDevice)

learn(:BrowserSignals, read("libs/BrowserSignals_1M1.jl", String))
@async start_browser_signal_next_running()

learn(:BrowserHTTPServer, read("libs/BrowserHTTPServer_1M1.jl", String))

learn(:BrowserInputDevice, read("libs/BrowserInputDevice_1M1.jl", String))
inputs[:Browser] = BrowserInputDevice()
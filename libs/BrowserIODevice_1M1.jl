# set 
# ENV["ABSTRACTOS_INNER_WEBSOCKET_IP"]
# ENV["ABSTRACTOS_WEBSOCKET_PORT"]

# @api const BrowserIODeviceDescription = """"""

learn(:BrowserOutputDevice, read("libs/BrowserOutputDevice_1M1.jl", String))

learn(:BrowserWebSocket, read("libs/BrowserWebSocket_1M1.jl", String))
@async start_websocket(ENV["ABSTRACTOS_INNER_WEBSOCKET_IP"], parse(Int, ENV["ABSTRACTOS_WEBSOCKET_PORT"]), BrowserOutputDevice)

learn(:BrowserSignals, read("libs/BrowserSignals_1M1.jl", String))

learn(:BrowserHTTPServer, read("libs/BrowserHTTPServer_1M1.jl", String))

inputs[:Browser] = ChannelStringInputDevice()

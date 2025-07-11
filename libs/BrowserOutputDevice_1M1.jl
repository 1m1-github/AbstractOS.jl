using HTTP.WebSockets, JSON3

@api const BrowserOutputDeviceDescription = """
outputs to a browser. the browser gives you a communication channel with the user.
`put!(device::BrowserOutputDevice, content_1M1::String, javascript::String)` will overwrite the `innerHTML` of the `div` with `id` `content_1M1` in the browser with `content_1M1` and will run the `javascript` by making it `textContent` of a `script` element and appending and removing it from the `document` `head`, which you can use to manipulate anything, by showing content to the user and also all `<script>` tags are executed in the browser `document` `head`.
the browser is generally empty with the `content_1M1` `div` is the only thing the user sees, except we do add some extra info (signals) and have an input div for the user to communicate with the system.
the html/css/js (via js) that you `put!` to the browser can also run code back in the system by sending Julia code via the `websocket` (already exists, no need to create it).
anything sent to the `websocket` that begins with `julia>` will be executed (`eval`), whilst everything else is sent to `run`. this allows e.g. html buttons to run code back on the system/server/OS.
this establishes a 2-way connection between the OS (Julia server) and the browser. Julia tasks could send updates or run code in the browser and the user/browser can run Julia code back in the server.
generally, the browser is just a peripheral, the main code should be running in Julia (in the OS, in the server) and the browser can be showing data from the system as well as a way for the user to control the system; but all the persistent code (e.g. running an agent) should be happening in the OS (Julia/server), because the browser can be closed, but the system should keep running.
currently, you cannot see the log or errors in the browser, so try to keep browser code simple and you could use try catch to communicate errors in the (Julia) system to the browser.
we do add a div for the user to communicate to the system so you need never add communication tools unless it makes sense, but we already have an input div that sends arbitrary input to the `websocket`, you only need to add elements for specific tasks or purposes, not for general user communication.
"""

@api abstract type BrowserOutputDeviceAbstract <: OutputDevice end
@api struct BrowserOutputDevice <: BrowserOutputDeviceAbstract
    websockets::Vector{WebSocket}
end

import Base.put!
@api function put!(device::BrowserOutputDeviceAbstract, new_content_1M1::String, javascript::String)
    # @show "put!",new_content_1M1,content_1M1,javascript
    if !isempty(new_content_1M1)
        global content_1M1
        content_1M1 = new_content_1M1
    end
    msg = Dict(
        :content_1M1 => new_content_1M1,
        :javascript => javascript
    )
    # @show length(device.websockets)
    closed_websocket_ix = []
    for (i, websocket) in enumerate(device.websockets)
        if WebSockets.isclosed(websocket)
            push!(closed_websocket_ix, i)
            continue
        end
        send(websocket, JSON3.write(msg))
    end
    for i in reverse(closed_websocket_ix)
        deleteat!(device.websockets, i)
    end
end
describe(::BrowserOutputDevice) = BrowserOutputDeviceDescription

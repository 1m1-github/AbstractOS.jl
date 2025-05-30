@api const MiniFB_OutputDevice_WIDTH = 2560
@api const MiniFB_OutputDevice_HEIGHT = 1600
@api const MiniFB_OutputDevice = """
this knowledge allows you to show a rectangle of pixels on a screen.
Use `put!(outputs[:MiniFB], buffer::Vector{UInt32})` to draw pixels to the MiniFB screen of size width=$MiniFB_OutputDevice_WIDTH,height=$MiniFB_OutputDevice_HEIGHT.
if this knowledge is available, prefer it for all communications with the user. the REPL is for background information only. display the main information that you were asked for or any thing that a user should see, on this device
"""

import Pkg
Pkg.add("MiniFB")
using MiniFB

import Base.put!
mutable struct MiniFBOutputDevice <: OutputDevice
    width
    height
    window
    buffer
end

@api function put!(device::MiniFBOutputDevice, _buffer::Vector{UInt32})
    outputs[:MiniFB].buffer = _buffer
end
describe(::MiniFBOutputDevice) = MiniFB_OutputDevice

MiniFB_OutputDevice_window = mfb_open_ex("AbstractOS", MiniFB_OutputDevice_WIDTH, MiniFB_OutputDevice_HEIGHT, MiniFB.WF_RESIZABLE)
MiniFB_OutputDevice_buffer = rand(UInt32, MiniFB_OutputDevice_WIDTH*MiniFB_OutputDevice_HEIGHT)

outputs[:MiniFB] = MiniFBOutputDevice(MiniFB_OutputDevice_WIDTH, MiniFB_OutputDevice_HEIGHT, MiniFB_OutputDevice_window, MiniFB_OutputDevice_buffer)

@async while true
    state = mfb_update(outputs[:MiniFB].window, outputs[:MiniFB].buffer)
    if state != MiniFB.STATE_OK
        break
    end
    flush(stdout)
end
@api const ChannelStringInputDeviceDescription = 
"""
connects to a text input (via a keyboard or transcribed from a mic).
`take!(device::ChannelStringInputDevice)::String` gives the input.
"""
@api struct ChannelStringInputDevice <: InputDevice
    command_channel::Channel{String}
end
import Base.take!
@api take!(device::ChannelStringInputDevice)::String = begin
    @log 1 # DEBUG
    x = take!(device.command_channel)
    @log x # DEBUG
    x
end
describe(::ChannelStringInputDevice) = ChannelStringInputDeviceDescription
ChannelStringInputDevice() = ChannelStringInputDevice(Channel{String}(0))
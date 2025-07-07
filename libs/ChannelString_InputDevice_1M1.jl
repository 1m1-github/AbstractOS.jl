@api const ChannelString_InputDevice = 
"""
connects to a text input (via a keyboard or transcribed from a mic).
`take!(device::ChannelStringInputDevice)::String` gives the input.
"""
@api struct ChannelStringInputDevice <: InputDevice
    command_channel::Channel{String}
end
import Base.take!
@api take!(device::ChannelStringInputDevice)::String = begin
    command = take!(device.command_channel)
    "the command from the br$command"
end
describe(::ChannelStringInputDevice) = ChannelString_InputDevice
ChannelStringInputDevice() = ChannelStringInputDevice(Channel{String}(0))
@api const ChannelStringInputDeviceDescription = 
"""
connects to a text input (via a keyboard or transcribed from a mic).
`take!(device::ChannelStringInputDevice)::String` gives the input.
"""
@api struct ChannelStringInputDevice <: InputDevice
    command_channel::Channel{String}
end
import Base.take!
@api take!(device::ChannelStringInputDevice)::String = take!(device.command_channel)
describe(::ChannelStringInputDevice) = ChannelStringInputDeviceDescription
ChannelStringInputDevice() = ChannelStringInputDevice(Channel{String}(0))
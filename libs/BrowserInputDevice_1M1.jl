# current_html = "<html></html>"

@api const BrowserInputDeviceDescription = 
"""
connects to a text input (via a keyboard or transcribed from a mic) from the browser.
`take!(device::BrowserInputDevice)::String` prepends the current html (which can subsequently be manipulated using javscript via a browser output device) before the user input.
"""

@api struct BrowserInputDevice <: InputDevice
    command_channel::Channel{String}
end

import Base.take!
@api take!(device::BrowserInputDevice)::String = take!(device.command_channel)

describe(::BrowserInputDevice) = BrowserInputDeviceDescription
BrowserInputDevice() = BrowserInputDevice(Channel{String}(0))
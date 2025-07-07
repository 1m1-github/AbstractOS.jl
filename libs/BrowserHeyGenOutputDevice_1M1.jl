learn(:BrowserOutputDevice, read("libs/BrowserOutputDevice_1M1.jl", String))
@api struct BrowserHeyGenOutputDevice <: BrowserOutputDevice end

@api const BrowserHeyGenOutputDeviceDescription = 
"""
`put!(device::BrowserHeyGenOutputDevice, javascript::String, audio_message::String)`
connects to a with a `BrowserOutputDevice` and has the HeyGen avatar speak `audio_message`.
"""

using JSON3
import Base.put!
@api function put!(device::BrowserHeyGenOutputDevice, javascript::String, audio_message::String)
    javascript_with_audio_message = javascript * """\nsendTask($(audio_message))"""
    put!(device, javascript_with_audio_message)
end
describe(::BrowserHeyGenOutputDevice) = BrowserHeyGenOutputDeviceDescription

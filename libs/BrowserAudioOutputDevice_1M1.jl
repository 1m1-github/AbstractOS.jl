learn(:BrowserOutputDevice, read("libs/BrowserOutputDevice_1M1.jl", String))
@api struct BrowserAudioOutputDevice <: BrowserOutputDeviceAbstract
    websockets::Vector{WebSocket}
end

@api const BrowserAudioOutputDeviceDescription = 
"""
`put!(device::BrowserAudioOutputDevice, javascript::String, audio_message::String)`
connects to a with a `BrowserOutputDevice` and has the browser speak `audio_message`.
"""

using JSON3
import Base.put!
@api function put!(device::BrowserAudioOutputDevice, javascript::String, audio_message::String)
    javascript_with_audio_message = javascript * """\nspeechSynthesis.speak(new SpeechSynthesisUtterance($(audio_message)))"""
    put!(device, javascript_with_audio_message)
end
describe(::BrowserAudioOutputDevice) = BrowserAudioOutputDeviceDescription

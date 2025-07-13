# DEBUG
include("libs/log.jl")

## core - required at the top

const CORE_PATH = "src/core.jl"
include(CORE_PATH)

## intelligence - exactly 1 should be used
# learn(:Claude_next, read("libs/Claude_next_1M1.jl", String))
learn(:XAI_next, read("libs/XAI_next_1M1.jl", String))

## @true - todo

## devices

# learn(:ChannelStringInputDevice, read("libs/ChannelStringInputDevice_1M1.jl", String))
# learn(:MiniFBOutputDevice, read("libs/MiniFBOutputDevice_1M1.jl", String))
# learn(:BrowserIODevice, read("libs/BrowserIODevice_1M1.jl", String))
# learn(:BrowserAudioIODevice, read("libs/BrowserAudioIODevice_1M1.jl", String))
# learn(:BrowserHeyGenIODevice, read("libs/BrowserHeyGenIODevice_1M1.jl", String))

## knowledge

learn(:Advice, read("libs/Advice_1M1.jl", String))
learn(:LearningAdvice, read("libs/LearningAdvice_1M1.jl", String))
# learn(:FlyIO, read("libs/Fly_io_1M1.jl", String))
learn(:ReliableEngineering, read("libs/ReliableEngineering_1M1.jl", String))
# learn(:RonWayneOpinion, read("libs/RonWayneOpinion_1M1.jl", String))
# learn(:Onboarding, read("libs/Onboarding_1M1.jl", String))
# learn(:LegalReferral, read("libs/LegalReferral_1M1.jl", String))

# learn(:DrawWithCairo, read("libs/DrawWithCairo_1M1.jl", String))
# learn(:DisplaySimpleText_1M1, read("libs/DisplaySimpleText_1M1.jl", String))
# learn(:endless_animated_pattern, read("libs/endless_animated_pattern_1M1.jl", String))
# learn(:ClearMemory, read("libs/ClearMemory_1M1.jl", String))
# learn(:animated_file_visualization, read("libs/animated_file_visualization_1M1.jl", String))
# learn(:ShowTimeInCorner, read("libs/ShowTimeInCorner_1M1.jl", String))
# learn(:make_HTTP_request, read("libs/make_HTTP_request.jl", String))

# learn(:N8N_API, read("libs/N8N_API_1M1.jl", String))
# learn(:AirTable_API, read("libs/AirTable_API_1M1.jl", String))
# learn(:Heygen_API, read("libs/Heygen_API_1M1.jl", String))

[Threads.@spawn listen(inputs[device]) for device in keys(inputs)]

## REPL to block
# learn(:REPL, read("libs/REPL_OutputDevice_1M1.jl", String))

## block

# wait(Condition())

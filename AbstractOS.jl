# determines how often the intelligence can run itself without needing outside agency
# 1 ≤ AGENCY allows the intelligence to react to the first error without needing to be asked
const AGENCY = 2

## core - required at the top

const CORE_PATH = "/Users/1m1/Documents/AbstractOS/src/core.jl"
include(CORE_PATH)

## intelligence - exactly 1 should be used

learn(:Claude_next, read("libs/Claude_next_1M1.jl", String))
# learn(:XAI_next, read("libs/XAI_next_1M1.jl", String))

## @true - todo

## devices

learn(:MiniFB_OutputDevice, read("libs/MiniFB_OutputDevice_1M1.jl", String))

## knowledge

learn(:Advice, read("libs/Advice_1M1.jl", String))
learn(:DrawWithCairo, read("libs/DrawWithCairo_1M1.jl", String))
learn(:DisplaySimpleText_1M1, read("libs/DisplaySimpleText_1M1.jl", String))
learn(:endless_animated_pattern, read("libs/endless_animated_pattern_1M1.jl", String))
learn(:ClearMemory, read("libs/ClearMemory_1M1.jl", String))
learn(:animated_file_visualization, read("libs/animated_file_visualization_1M1.jl", String))
learn(:ShowTimeInCorner, read("libs/ShowTimeInCorner_1M1.jl", String))

## REPL - required at the end

learn(:REPL_OutputDevice, read("libs/REPL_OutputDevice_1M1.jl", String))
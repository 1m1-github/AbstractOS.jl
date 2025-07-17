const WORK_DIR = "/data"
const OS_SRC_DIR = "/1M1/src"

## logging

include("$(OS_SRC_DIR)/log.jl")

## core

const CORE_PATH = "$(OS_SRC_DIR)/core.jl"
include(CORE_PATH)

## intelligence - exactly 1 should be used

learn(:XAI_next, read("$(WORK_DIR)/knowdledge/XAI_next_1M1.jl", String))

## @true - todo

## devices

## knowledge

learn(:Advice, read("knowdledge/Advice_1M1.jl", String))
learn(:LearningAdvice, read("knowdledge/LearningAdvice_1M1.jl", String))
learn(:FlyIO, read("knowdledge/Fly_io_1M1.jl", String))
learn(:ReliableEngineering, read("knowdledge/ReliableEngineering_1M1.jl", String))

[Threads.@spawn listen(inputs[device]) for device in keys(inputs)]

## block

wait(Condition())

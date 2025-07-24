# const OS_ROOT_DIR = "/data"
const OS_ROOT_DIR = "/Users/1m1/"
# const OS_SRC_DIR = "/1M1/src"
const OS_SRC_DIR = "/Users/1m1/Documents/AbstractOS.jl/src"

## logging

include("$(OS_SRC_DIR)/log.jl")

## core

const CORE_PATH = "$(OS_SRC_DIR)/core.jl"
include(CORE_PATH)
learn(name::Symbol) = learn(name, read("$(OS_ROOT_DIR)/knowledge/$(name)_1M1.jl", String))

## intelligence - exactly 1 should be used

learn(:XAI_next)

## @true - todo

## devices

## knowledge

map(learn, [
    :Advice,
    :LearningAdvice,
    :ReliableEngineering,
])

[Threads.@spawn listen(inputs[device]) for device in keys(inputs)]

## block

# wait(Condition())

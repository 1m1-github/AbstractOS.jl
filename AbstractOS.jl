## params

const OS_ROOT_DIR = joinpath("/", "Users", "1m1")
const OS_SRC_DIR = joinpath(OS_ROOT_DIR, "src")
const OS_KNOWLEDGE_DIR = joinpath(OS_ROOT_DIR, "knowledge")

## logging # DEBUG

include(joinpath(OS_SRC_DIR, "log.jl"))

## core

include(joinpath(OS_SRC_DIR, "core.jl"))
# safe = true

## utils

learn(name::Symbol) = learn(name, read(joinpath(OS_KNOWLEDGE_DIR, "$name.jl"), String))

## intelligence - needs to implement `intelligence(who, what_system, what_user, complexity)::String`
# @assert length(methods(intelligence)) == 1 # exactly 1 intelligence should be used - todo

## @true - todo

## knowledge and devices

map(learn, [])

## REPL goes last

include(joinpath(OS_ROOT_DIR, "src", "repl.jl"))

## params

const OS_ROOT_DIR = joinpath("/", "Users", "aos")
const OS_SRC_DIR = joinpath(OS_ROOT_DIR, "src")
const OS_KNOWLEDGE_DIR = joinpath(OS_ROOT_DIR, "knowledge")

## logging # DEBUG

include(joinpath(OS_SRC_DIR, "log.jl"))

## core

include(joinpath(OS_SRC_DIR, "core.jl"))
safe = true

## utils

learn(name::Symbol) = learn(name, read(joinpath(OS_KNOWLEDGE_DIR, "$name.jl"), String))

## intelligence - needs to implement `next(;system::String, user::String)::String`

@assert length(methods(next)) == 1 # exactly 1 intelligence should be used

## @true - todo

## knowledge and devices

map(learn, [])

## run at the end

run()

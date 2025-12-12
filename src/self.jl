# todo @true mode == provable open source == trustless

SELF = @__FILE__
global BOOT # path to file
global STORAGE # path to dir
isdefined(Main, :AbstractOS) && return

"Everything after `@api` will be passed into state"
macro api(args...)
    isempty(args) && return nothing
    esc(args[end])
end # used to denote parts of `CODE` that are summarized via the signature and docstring without the implementation

abstract type Peripheral end
abstract type InputPeripheral <: Peripheral end # e.g. microphone, keyboard, camera, touch, ...
abstract type OutputPeripheral <: Peripheral end # e.g. speaker, screen, AR, VR, touch, ...
import Base.take! # ∃ `take!(::InputPeripheral, ...)`
import Base.put! # ∃ `put!(::OutputPeripheral, ...)`

JuliaCode = String
Time = Float64
"Each what/how combition creates an Action"
struct Action
    ts::Time
    source::Any
    input_summary::String
    input::String
    output_summary::String
    output::JuliaCode
end

const LOCK = ReentrantLock()
const MEMORY = Dict{String,Any}()
const CODE = Dict{String,JuliaCode}()
const HISTORY = Dict{Time,Action}()
const TASKS = Dict{Time,Task}()
const INPUTS = Dict{String,InputPeripheral}()
const OUTPUTS = Dict{String,OutputPeripheral}()
const FLAGS = Dict{String,Bool}("intelligence running" => false)

"""
use `learn` to add Julia code to `CODE`, persist to `STORAGE` and optionally add to `BOOT`
only `learn` code that is reliable and when specifically told to
"""
function learn(code_summary, code::JuliaCode, boot=false)
    haskey(CODE, code_summary) && return false
    code ∈ collect(values(CODE)) && return false
    code_expr = eval_code(code)
    state.(find_api_macrocalls(code_expr)) # `code` should be `state`able
    CODE[code_summary] = code
    write(joinpath(STORAGE, "$(code_summary).jl"), code)
    boot && add_to_boot(code_summary, code) # adds `learn($code_summary,$code)` to `BOOT`
    true
end

function act(ts::Time, source, input_summary, input, output_summary, output::JuliaCode)
    HISTORY[ts] = Action(ts, source, input_summary, input, output_summary, output)
    TASKS[ts] = Threads.@spawn eval_code(output)
end
function act(ts::Time, source, input, output::JuliaCode)
    input_summary  = extract_summary(output, input,  :input_summary)
    output_summary = extract_summary(output, output, :output_summary)
    act(ts, source, input_summary, input, output_summary, output)
end
act(input, output::JuliaCode) = act(time(), "SELF", input, output)

const LAST_TIME = Threads.Atomic{Float64}(time())
function next(ts, source, input)
    FLAGS["intelligence running"] = true
    output = nothing
    try
        output = intelligence(ts, source, state(), input)
    catch e
        @error "intelligence", ts, e
    end
    FLAGS["intelligence running"] = false
    isnothing(output) && return
    ts < LAST_TIME[] && return
    Threads.atomic_max!(LAST_TIME, ts)
    act(ts, source, input, output)
end

function listen(source::InputPeripheral)
    while true
        input = take!(source)
        isempty(input) && continue
        @lock LOCK next(time(), source, input)
        yield() # always add `yield()` at the end of a loop so we can interrupt it
    end
end

function awaken(w=true)
    ks = filter(!startswith("REPL"), keys(INPUTS))
    for k in ks
        # todo dups
        output_summary = "listen(INPUTS[\"$k\"])"
        input_summary = "listen to \"$k\""
        code = :(input_summary = $(input_summary); output_summary = $(output_summary); listen(INPUTS[$k]))
        code.args = filter(a -> !isa(a, LineNumberNode), code.args)
        act(time(), INPUTS[k], input_summary, input_summary, output_summary, string(code))
    end
    FLAGS["awake"] = true
    w && wait(Condition())
end

block(code) = "begin $code end"
function eval_code(code)
    code_expr = Meta.parse(block(code))
    code_expr.head == :incomplete && throw(code_expr.args[1])
    code_imports, code_body = separate(code_expr) # to `eval `using`s and `import`s separately
    eval(code_imports)
    eval(code_body)
    code_expr
end

mutable struct Loop <: InputPeripheral
    duration::Time
end
function take!(l::Loop)
    l.duration < time() - LAST_TIME[] && return "LOOP"
    sleep(l.duration)
    ""
end
INPUTS["LOOP"] = Loop(20.0) # consciousness emerges from a loop, expect the loop and you are conscious, i loop therefore i am, allows planning and patience

include("aux.jl")
state() = join([
    isdefined(Main, :STATE_PRE) ? STATE_PRE : "",
    read(SELF, String), # proof of loop
    state(FLAGS),
    state(MEMORY),
    state(CODE),
    state(HISTORY, TASKS), # intertwined by `when`
    state(INPUTS), # runs `state(::InputPeripheral)` if ∃
    state(OUTPUTS), # runs `state(::OutputPeripheral)` if ∃
    isdefined(Main, :STATE_POST) ? STATE_POST : "",
], "\n\n")
    
AbstractOS = something

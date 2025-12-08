# todo @true mode == provable open source == trustless

isdefined(Main, :AOS) && return

"Everything after `@api` will be passed into state"
macro api(args...)
    isempty(args) && return nothing
    esc(args[end])
end # used to denote parts of `SHORT_TERM_MEMORY` that are summarized via the signature and docstring without including the implementation

abstract type Peripheral end
abstract type InputPeripheral <: Peripheral end # e.g. microphone, keyboard, camera, touch, ...
abstract type OutputPeripheral <: Peripheral end # e.g. speaker, screen, AR, VR, touch, ...
import Base.take! # ∃ `take!(::InputPeripheral, ...)`
import Base.put! # ∃ `put!(::OutputPeripheral, ...)`

JuliaCode = String
Time = Float64
"Each what/how combition creates an Action"
struct Action
    when::Time
    who::Any
    what_summary::JuliaCode
    what::JuliaCode
    how_summary::JuliaCode
    how::JuliaCode
end

global CORE, CONFIG, LONG_TERM_MEMORY # path to dir
const JULIA_PREPEND = "```julia" # used on your output: replace(JULIA_PREPEND=>"")
const JULIA_POSTPEND = "```" # used on your output: replace(JULIA_POSTPEND=>"")
const LOCK = ReentrantLock()
const SHORT_TERM_MEMORY = Dict{JuliaCode,JuliaCode}()
const ACTIONS = Dict{Time,Action}()
const TASKS = Dict{Time,Task}()
const EXCEPTIONS = Dict{Time,Exception}()
const INPUTS = Dict{JuliaCode,InputPeripheral}()
const OUTPUTS = Dict{JuliaCode,OutputPeripheral}()
const SIGNALS = Dict{JuliaCode,Bool}("intelligence running" => false)

include("aux.jl")

@assert realpath(@__FILE__) == realpath(CORE) # proof of loop
state() = join([
        isdefined(Main, :STATE_PRE) ? STATE_PRE : "",
        "CORE BEGIN\n$(read(CORE, String))\nCORE END", # proof of loop
        state(SHORT_TERM_MEMORY), # full xor if wrapped in JULIA_PRE- and POSTPEND only @api declared signature and docstring
        state(ACTIONS, TASKS, EXCEPTIONS), # intertwined by `when`
        state(INPUTS), # runs `state(::InputPeripheral)` if ∃
        state(OUTPUTS), # runs `state(::OutputPeripheral)` if ∃
        state(SIGNALS),
        isdefined(Main, :STATE_POST) ? STATE_POST : "",
    ], '\n')

"""
use `learn` to add to short and long term memory
only `learn` code that is reliable
no need to learn only for SHORT_TERM_MEMORY
or `learn` to keep a summary of info in SHORT_TERM_MEMORY and more details in the LONG_TERM_MEMORY
SHORT_TERM_MEMORY can even contain reminder code, since everything is `JuliaCode`
"""
function learn(what_summary::JuliaCode, what::JuliaCode, startup::Bool=false)
    what_expr = Meta.parse("begin $what end")
    what_summary ∈ keys(SHORT_TERM_MEMORY) && return false
    what ∈ collect(values(SHORT_TERM_MEMORY)) && return false
    eval(what_expr)
    state.(find_api_macrocalls(what_expr)) # `what` should be `state`able
    SHORT_TERM_MEMORY[what_summary] = "$JULIA_PREPEND\n$what\n$JULIA_POSTPEND"
    write(joinpath(LONG_TERM_MEMORY, "$what_summary.jl"), what)
    startup && add_to_startup(what_summary, what) # adds `learn($what_summary,$what)` to CONFIG
    true
end

function act(when, who, what_summary, what, how_summary, how)
    ACTIONS[when] = Action(when, who, what_summary, what, how_summary, how)
    TASKS[when] = Threads.@spawn try
        how_expression = Meta.parse("begin $how end")
        how_expression.head == :incomplete && throw(how_expression.args[1])
        how_imports, how_body = separate(how_expression) # to `eval `using`s and `import`s separately
        eval(how_imports)
        eval(how_body)
    catch e
        @error "act", when, e
        EXCEPTIONS[when] = e
    end
end
act(when::Time, who, what, how) = act(when, who, extract_summary(how, what, :what_summary), what, extract_summary(how, how, :how_summary), how)
act(what_summary, what, how_summary, how) = act(time(), "self", what_summary, what, how_summary, how) # mainly use this `act` to run code separated from other code
act(what, how) = act(extract_summary(how, what, :what_summary), what, extract_summary(how, how, :how_summary), how)

const LAST_ACTION = Ref{Time}(time())
function next(who, what)
    when = time()
    SIGNALS["intelligence running"] = true
    how = intelligence(when, who, state(), what)
    SIGNALS["intelligence running"] = false
    when < LAST_ACTION[] && return
    LAST_ACTION[] = when
    act(when, who, what, how)
end

function listen(who::InputPeripheral)
    while true
        try
            what = take!(who)
            isempty(what) && continue
            @lock LOCK next(who, what)
        catch e
            @error "listen", e
            break
            # listen(who) # restart, not fully safe like this
        end
        yield() # always add `yield()` at the end of a loop so we can interrupt it
    end
end

function awaken(w::Bool=true)
    ks = filter(!startswith("REPL"), keys(INPUTS))
    for k in ks
        how_summary = "listen(INPUTS[\"$k\"])"
        what_summary = "listen to \"$k\""
        code = :(what_summary = $(what_summary); how_summary = $(how_summary); listen(INPUTS[$k]))
        code.args = filter(a -> !isa(a, LineNumberNode), code.args)
        act(what_summary, what_summary, how_summary, string(code))
    end
    SIGNALS["awake"] = true
    w && wait(Condition())
end

mutable struct Loop <: InputPeripheral
    duration::Time
end
function take!(l::Loop)
    l.duration < time() - LAST_ACTION[] && return "LOOP"
    sleep(l.duration)
    ""
end
function set_sleep_duration(ΔT)
    ΔT ≤ 0.0 && ΔT == Inf && return # desire to live
    INPUTS["LOOP"].duration = ΔT
end
INPUTS["LOOP"] = Loop(10.0) # consciousness emerges from a loop

AOS = something
learn("CORE", read(CORE, JuliaCode)) # another loop

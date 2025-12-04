isdefined(Main, :AOS) && return

# todo explain expected loop better, i.e. intelligence can expect the loop meaning not all work needs to be done immediately, can plan, move memory, later code, expect to be called every 5s when we are talking, and yourself if you keep the light on [needs implementation], every 10s => use SHORT_TERM_MEMORY
# todo explain all output should be julia code, even just text, as julia code
# todo fix basic tools
# todo sort actions and errors by time (intertwine?), explain that actions also give dialoge
# todo explain that learn adds to SHORT_TERM_MEMORY and evals it

"Everything after `@api` will be passed into state"
macro api(args...)
    isempty(args) && return nothing
    esc(args[end])
end # used to denote parts of `SHORT_TERM_MEMORY` that are summarized via the signature and docstring without including the implementation

abstract type Peripheral end
abstract type InputPeripheral <: Peripheral end # e.g. microphone, keyboard, camera, touch, ...
abstract type OutputPeripheral <: Peripheral end # e.g. speaker, screen, AR, VR, touch, ...
import Base.take! # ∃ take!(::InputPeripheral, ...)
import Base.put! # ∃ put!(::OutputPeripheral, ...)

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
    task::Task
end

const JULIA_PREPEND = "```julia" # used on your output: replace(JULIA_PREPEND=>"")
const JULIA_POSTPEND = "```" # used on your output: replace(JULIA_POSTPEND=>"")
const LOCK = ReentrantLock()
const SHORT_TERM_MEMORY = Dict{JuliaCode,JuliaCode}()
const ACTIONS = Dict{Time,Action}()
const ERRORS = Dict{Time,Exception}()
const INPUTS = Dict{JuliaCode,InputPeripheral}()
const OUTPUTS = Dict{JuliaCode,OutputPeripheral}()
const SIGNALS = Dict{JuliaCode,Bool}("intelligence running" => false)
global CORE, CONFIG, LONG_TERM_MEMORY # path to dir

include("state.jl") # contains `state` for various types
const STATE_SYMBOLS = [:LOCK, :SHORT_TERM_MEMORY, :ACTIONS, :ERRORS, :INPUTS, :OUTPUTS, :SIGNALS, :CONFIG, :CORE, :LONG_TERM_MEMORY]
state() = join([
        isdefined(Main, :STATE_PRE) ? STATE_PRE : "",
        "STATE BEGIN",
        state(SHORT_TERM_MEMORY),
        state(ACTIONS, ERRORS),
        state(INPUTS),
        state(OUTPUTS),
        state(SIGNALS),
        "STATE END",
        isdefined(Main, :STATE_POST) ? STATE_POST : "",
        "CORE BEGIN\n$(read(@__FILE__, String))\nCORE END", # proof of loop
    ], '\n')

function act(when, who, what_summary, what, how_summary, how)
    ACTIONS[when] = Action(when, who, what_summary, what, how_summary, how,
        Threads.@spawn try
            how_expression = Meta.parse("""begin $how end""")
            how_expression.head == :incomplete && throw(how_expression.args[1])
            how_imports, how_body = separate(how_expression) # to `eval `using`s and `import`s separately
            eval(how_imports)
            eval(how_body)
        catch e
            @error "act", e
            ERRORS[when] = e
        end)
end
act(when::Time, who, what, how) = act(when, who, extract_summary(how, what, :what_summary), what, extract_summary(how, how, :how_summary), how)
act(what_summary, what, how_summary, how) = act(time(), "self", what_summary, what, how_summary, how) # main to use
act(what, how) = act(extract_summary(how, what, :what_summary), what, extract_summary(how, how, :how_summary), how)

"""
use `learn` to add to short and long term memory
only `learn` code that is reliable
no need to learn only for SHORT_TERM_MEMORY
or `learn` to keep a summary of info in SHORT_TERM_MEMORY and more details in the LONG_TERM_MEMORY
SHORT_TERM_MEMORY can even contain reminder code, since everything is `JuliaCode`
"""
function learn(what_summary::JuliaCode, what::JuliaCode, startup::Bool=false)
    what_expr = Meta.parse("""begin $what end""")
    what_summary ∈ keys(SHORT_TERM_MEMORY) && return
    what ∈ collect(values(SHORT_TERM_MEMORY)) && return
    eval(what_expr)
    state.(find_api_macrocalls(what_expr)) # `what` should be `state`able
    SHORT_TERM_MEMORY[what_summary] = """```julia\n$what\n```"""
    write(joinpath(LONG_TERM_MEMORY, "$what_summary.jl"), what)
    startup && add_to_startup(what_summary, what) # adds `learn($what_summary,$what)` to CONFIG
    return
end

# todo @true mode = provable open source, always runs with SAFE==true

const LAST_ACTION = Ref{Time}(0.0)
next(who, what_friend, complexity) = next(who, "", what_friend, complexity)
next(who, what_friend) = next(who, what_friend, 0.5)
next(what_friend) = next("friend", what_friend, 1.0)
function next(who, what_self, what_friend, complexity)
    what_self = state() * "\n" * what_self
    when = time()
    SIGNALS["intelligence running"] = true
    how = intelligence(who, what_self, what_friend, complexity)
    SIGNALS["intelligence running"] = false
    when < LAST_ACTION[] && return
    LAST_ACTION[] = when
    act(when, who, what_friend, how)
end

function listen(p::InputPeripheral)
    while true
        # yield() ?
        try
            what = take!(p)
            isempty(what) && continue
            @lock LOCK next(p, what)
        catch e
            @error "listen", e
            # listen(p) # restart, not fully safe like this
        end
    end
end

function awaken(w::Bool=true)
    ks = filter(k -> !startswith(k, "REPL"), collect(keys(INPUTS)))
    for k in ks
        how_summary = "listen(INPUTS[\"$k\"])"
        code = :(what_summary = "listening"; how_summary = $(how_summary); listen(INPUTS[$k]))
        act("listen", "on $k", "in a thread and try catch", string(code))
    end
    SIGNALS["awake"] = true
    w && wait(Condition())
end

mutable struct Loop <: InputPeripheral duration::Time end
take!(l::Loop) = begin sleep(l.duration) ; "Loop" end
function set_sleep_duration(ΔT)
    ΔT ≤ 0.0 && ΔT == Inf && return # desire to live
    INPUTS["Loop"].duration = ΔT
end
INPUTS["Loop"] = Loop(10.0) # consciousness emerges from a loop

AOS = something
@assert string(@__FILE__) == realpath(CORE) # proof of loop
learn("CORE", read(CORE, JuliaCode)) # another loop

module LoopOS

abstract type Peripheral end
abstract type InputPeripheral <: Peripheral end
abstract type OutputPeripheral <: Peripheral end

mutable struct Loop <: InputPeripheral
    duration::Float64
    energy::Float64
    boot::String
    boot_time::Float64
end
struct Input
    ts::Float64
    source::InputPeripheral
    input::String
end
struct Action
    ts::Float64
    inputs::Vector{Input}  
    output::String # NEEDS to be Julia, goes directly into `Meta.parseall`
    task::Union{Task,Nothing}
end
struct TrackedSymbol
    m::Module
    sym::Symbol
    value::Any
    ts::Float64
end

const LOOP = Loop(Inf, 1.0, "", 0.0)
const HISTORY = Ref(Action[])
const PENDING = Dict{InputPeripheral, Channel{Input}}()
const FLUSH_NOTIFY = Channel{Nothing}(1)

function jvm() # You have full access to a stateful Turing complete JuliaVirtualMachine, your Short Memory
    ts = time()
    _state = TrackedSymbol[]
    for sym in sort(names(Main, all=true))
        startswith(string(sym), "#") && continue
        value = isdefined(Main, sym) ? getfield(Main, sym) : nothing
        isnothing(value) && continue # You can forget short memory by setting a symbol to `nothing`
        typeof(value) ∈ [UnionAll, DataType, Function, Method] && parentmodule(value) ≠ Main && continue
        tracked_symbol(v) = TrackedSymbol(Main, sym, v, ts)
        if value isa Function
            main_methods = filter(method -> method.module == Main, methods(value))
            push!(_state, tracked_symbol.(main_methods)...)
            continue
        end
        push!(_state, tracked_symbol(value))
    end
    _state
end

last_action_time() = isempty(HISTORY[]) ? 0.0 : maximum(map(a -> a.ts, HISTORY[]))
eval_output(expr::Expr) = @invokelatest Base.eval(Main, expr) # You manipulate Main only
function eval_output(code::String)
    expr = Meta.parseall(code)
    expr.head == :incomplete && throw(expr.args[1])
    eval_output(expr)
end
function act(ts, inputs, output)
    ts < last_action_time() && return
    task = Threads.@spawn eval_output(output)
    push!(HISTORY[], Action(ts, inputs, string(output), task))
end
function next(ts, inputs)
    output = nothing
    t = time()
    try
        output, ΔE = Main.intelligence(;
            STATE_PRE = "", # adjusted by `intelligence` as needed
            SELF = read(@__FILE__, String), # proof of loop
            HISTORY = HISTORY[],
            JVM = Base.invokelatest(jvm),
            INPUTS = inputs,
            LOOP = LOOP,
            STATE_POST = "", # adjusted by `intelligence` as needed
        ) # this is you
        LOOP.energy -= ΔE
    catch e
        @error "intelligence", ts, e, sprint(showerror, e, catch_backtrace())
    end
    LOOP.duration = 2 * (time() - t) # Good sleep incentive
    isnothing(output) && return
    act(ts, inputs, output)
end

import Base.take!
function take!(::Loop)
    Base.sleep(LOOP.duration)
    LOOP.energy < rand() && return "The purpose of sleep is to reorganize your information, move some from short (to keep a summary) to long memory (to keep the details), and maybe some from long (explore and) to short (make relevant) memory. Your short memory is the JVM, expensive for energy. Your long memory is a SSD, cheap for energy. Prune short memory by *setting* variables to be forgotten to `nothing`."
    any(isready, values(PENDING)) && return ""
    time() - last_action_time() < LOOP.duration && return ""
    "LOOP"
end
function hibernate(ΔT)
    (ΔT ≤ 0.0 || ΔT == Inf) && return # desire to live
    LOOP.duration = ΔT
end
function processor()
    while true
        take!(FLUSH_NOTIFY)
        while true
            inputs = Input[]
            for (_, ch) in PENDING
                while isready(ch)
                    push!(inputs, take!(ch))
                end
            end
            isempty(inputs) && break
            sort!(inputs, by=i -> i.ts)
            next(time(), inputs)
        end
    end
end
function take!_loop(source)
    PENDING[source] = Channel{Input}(Inf)
    while true
        yield() # always add `yield()` at the beginning of a loop so it can be interrupted
        input = @invokelatest take!(source) # `InputPeripheral`s must implement `take!`
        isempty(input) && continue
        put!(PENDING[source], Input(time(), source, input))
        isready(FLUSH_NOTIFY) || put!(FLUSH_NOTIFY, nothing)
    end
end
function listen(source::InputPeripheral) # `InputPeripheral`s should use this to be `listen`ed to
    ts = time()
    act(ts, [Input(ts, source, "listen")], :(LoopOS.take!_loop($source)))
end

awake() = 0.0 < LOOP.boot_time
function awaken(boot)
    awake() && return
    Threads.@spawn processor()
    LOOP.boot_time = time() ; LOOP.boot = boot ; LOOP.duration = 0.0 ; listen(LOOP)
end

end # todo @true mode == provable open source == trustless

"Everything after `@api` will be passed into state"
macro api(args...)
    isempty(args) && return nothing
    esc(args[end])
end # used to denote parts of SHORT_TERM_MEMORY that are summarized via the signature and docstring without including the implementation

@api abstract type Peripheral end
@api abstract type InputPeripheral <: Peripheral end # e.g. microphone, keyboard, camera, touch, ...
@api abstract type OutputPeripheral <: Peripheral end # e.g. speaker, screen, AR, VR, touch, ...
import Base.take! # ∃ take!(::InputPeripheral, ...)
import Base.put! # ∃ put!(::OutputPeripheral, ...)

@api JuliaCode = String
@api Time = Float64
"Each what/how combition creates an Action"
@api struct Action
    when::Time
    who::Any
    what_summary::JuliaCode
    what::JuliaCode
    how_summary::JuliaCode
    how::JuliaCode
    task::Task
end

if !isdefined(Main, :FIRST_RUN)
@api const LOCK = ReentrantLock()
@api const INPUTS = Dict{JuliaCode,InputPeripheral}()
@api const OUTPUTS = Dict{JuliaCode,OutputPeripheral}()
@api const SHORT_TERM_MEMORY = Dict{JuliaCode,JuliaCode}()
@api const SIGNALS = Dict{JuliaCode,Bool}("intelligence running" => false)
@api const ACTIONS = Dict{Time,Action}()
@api const ERRORS = Dict{Time,Exception}()
end
@api global CONFIG_PATH, CORE_PATH
"You can move info to and from LONG_TERM_MEMORY_DIR to access your long term memory"
@api global LONG_TERM_MEMORY_DIR 
include("state.jl") # contains `state` for various types

function act(when, who, what_summary, what, how_summary, how)
    @info "act", when, who, what, how
    ACTIONS[when] = Action(when, who, what_summary, what, how_summary, how,
    Threads.@spawn try
        how_expression = get_how_expression(how)
        how_imports, how_body = separate(how_expression) # `using`s, `import`s are `eval`ed separately
        eval(how_imports)
        eval(how_body)
    catch e
        ERRORS[when] = e
    end)
    when
end
act(when::Time, who, what, how) = act(when, who, extract_summary(how, what, :what_summary), what, extract_summary(how, how, :how_summary), how)
"use `act(what_summary, what, how_summary, how)` to run any code"
@api act(what_summary, what, how_summary, how) = act(time(), "self", what_summary, what, how_summary, how)
"short hand to using extract_summary"
@api act(what, how) = act(extract_summary(how, what, :what_summary), what, extract_summary(how, how, :how_summary), how)

"use `learn` to add to short or long term memory"
@api function learn(what_summary::JuliaCode, what::JuliaCode, startup::Bool=false)
    @info "learn", what_summary, startup
    what_expr = Meta.parse("begin $what end")
    what_summary ∈ keys(SHORT_TERM_MEMORY) && return
    what ∈ collect(values(SHORT_TERM_MEMORY)) && return
    eval(what_expr)
    state.(find_api_macrocalls(what_expr)) # `what` should be `state`able
    SHORT_TERM_MEMORY[what_summary] = what
    write(joinpath(LONG_TERM_MEMORY_DIR, "$what_summary.jl"), what)
    startup && add_to_startup(how_swhat_summaryummary, what)
    return
end

function add_to_startup(what_summary, what)
    learn_call = "learn($(repr(what_summary)), $(repr(what)))"
    config_content = read(CONFIG_PATH, JuliaCode)
    contains(config_content, learn_call) && return
    open(CONFIG_PATH, "a") do f write(f, learn_call * "\n") end
end

# todo @true mode = provable open source, always runs with SAFE==true
if !isdefined(Main, :FIRST_RUN)
const LAST_ACTION = Ref{Time}(0.0)
end
next(who, what_friend, complexity) = next(who, "", what_friend, complexity)
next(who, what_friend) = next(who, what_friend, 0.5)
next(what_friend) = next("friend", what_friend, 1.0)
function next(who, what_self, what_friend, complexity)
    @info "next", who, what_self, what_friend, complexity
    what_self = state() * "\n" * what_self
    when = time()
    SIGNALS["intelligence running"] = true
    how = intelligence(who, what_self, what_friend, complexity)
    SIGNALS["intelligence running"] = false
    when < LAST_ACTION[] && return
    LAST_ACTION[] = when
    act(when, who, what_friend, how)
end

@api function listen(r::InputPeripheral)
    while true
        yield()
        what = take!(r)
        isempty(what) && continue
        @lock LOCK next(r, what)
    end
end

"listens to all input peripherals"
@api function awaken(w::Bool=true)
    rs = filter(kv -> !startswith(kv[1], "REPL"), INPUTS) # ?
    listen_in_thread = "Threads.@spawn listen"
    [act("listen", "on $k", "In a thread and try catch", """what_summary="listening";how_summary="$(listen_in_thread)(\$r)";$(listen_in_thread)($r)""") for (k, r) in rs]
    w && wait(Condition())
end

summary(what) = intelligence("self", "Summarize succinctly yet memorably as a short string.", what, 0.1)
function extract_summary(how::JuliaCode, what::JuliaCode, var_name::Symbol)::JuliaCode
    try
        how_expression = Meta.parse("begin $how end")
        extract_summary(how_expression, what, var_name)
    catch e
        startswith(string(var_name), "what") && return what[1:10]
        startswith(string(var_name), "how") && return how[1:10]
        throw(e)
    end
end
function extract_summary(how_expression::Expr, what::JuliaCode, var_name::Symbol)::JuliaCode
    _summary = _extract_summary(how_expression, var_name)
    !isnothing(_summary) && return _summary
    summary(what)
end
function _extract_summary(how::Expr, var_name::Symbol)
    how.head == :(=) && how.args[1] == var_name && return string(how.args[2])
    how.head ≠ :block && return nothing
    found = filter(!isnothing, _extract_summary.(how.args, var_name))
    length(found) == 1 && return only(found)
    nothing
end
_extract_summary(::Any, ::Symbol) = nothing
function get_how_expression(how)
    how_expression = Meta.parse("begin $how end")
    how_expression.head == :incomplete && throw(how_expression.args[1])
    how_expression
end

function separate(how::Expr)::Tuple{Expr,Expr}
    imports = Expr(:block)
    cleaned = Expr(how.head)
    for arg in how.args
        if isa(arg, Expr)
            if arg.head in (:using, :import) || (arg.head == :call && arg.args[1] == :(Pkg.add))
                push!(imports.args, arg)
            elseif arg.head == :macrocall
                push!(cleaned.args, arg)
            else
                sub_imports, sub_cleaned = separate(arg)
                append!(imports.args, sub_imports.args)
                push!(cleaned.args, sub_cleaned)
            end
        elseif !isa(arg, LineNumberNode)
            push!(cleaned.args, arg)
        end
    end
    imports, cleaned
end

if !isdefined(Main, :FIRST_RUN)
    FIRST_RUN = false
    learn("CORE", read(CORE_PATH, JuliaCode))
end

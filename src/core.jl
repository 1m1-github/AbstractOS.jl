const YOUR_PURPOSE = "you are an a learning and truthful computer operating system"

abstract type IODevice end
abstract type InputDevice <: IODevice end # e.g. microphone, keyboard, camera, touch, ...
abstract type OutputDevice <: IODevice end # e.g. speaker, screen, AR, VR, touch, ...
import Base.take! # ∃ take!(::InputDevice, ...)
import Base.put! # ∃ put!(::OutputDevice, ...)

struct TaskElement
    # todo maybe add `who`
    task_name::Symbol
    input::String
    output::String
    task::Task
end

using UUIDs
mutable struct State
    state_id::UUID
    safe::Bool # true requires confirmation from user before executing code
    lock::ReentrantLock # enforces single thread on main intelligence
    input_devices::Dict{Symbol,InputDevice} # name => device with take!(device::InputDevice)::Any implemented
    output_devices::Dict{Symbol,OutputDevice} # name => device with put!::InputDevice, info...) implemented
    memory::Dict{Symbol,Any} # ephemeral, name => anything # todo just use new vars added to jvm
    knowledge::Dict{Symbol,String} # persisted, name => code
    tasks::Dict{Symbol,TaskElement} # ephemeral, task_name => input, output, task
    signals::Dict{Symbol,Bool} # can be used to communicate
end
empty_state() = State(
    UUID(0),
    false,
    ReentrantLock(),
    Dict{Symbol,InputDevice}(),
    Dict{Symbol,OutputDevice}(),
    Dict{Symbol,Any}(),
    Dict{Symbol,String}(),
    Dict{Symbol,TaskElement}(:latest_task => TaskElement(:latest_task, "", "", Task(() -> nothing))),
    Dict{Symbol,Bool}(:stop_next => false, :intelligence_running => false),
)
const STATES = Dict{UUID,State}( # state_id => State
    UUID(0) => empty_state()
)

macro api(args...)
    isempty(args) && return nothing
    esc(args[end])
end # used to denote parts of `knowledge` that are presented to the `intelligence` as abilities that can be considered black-boxes (can be a struct, type, function, variable)

global OS_ROOT_DIR, OS_SRC_DIR, OS_KNOWLEDGE_DIR # only persist to OS_ROOT_DIR
include("describe.jl") # contains `describe` for various types

function learn(state::State, code_name::Symbol, code::String)
    @info "learn", state.state_id, code_name # DEBUG
    try
        code_expr = Meta.parse("begin $code end")
        code_name ∈ keys(state.knowledge) && return
        code ∈ collect(values(state.knowledge)) && return
        eval(code_expr)
        describe.(find_api_macrocalls(code_expr)) # code should be describable
        state.knowledge[code_name] = code
        write(joinpath(OS_KNOWLEDGE_DIR, "$code_name.jl"), code)
    catch e
        show(e)
        throw(e)
    end
end

# todo @true mode = provable open source, always runs with safe==true

function listen(state::State, device::InputDevice)
    @info "listen", state.state_id, typeof(device) # DEBUG
    while true
        @info "waiting to take!", state.state_id, typeof(device) # DEBUG
        output = take!(device)
        @info "listen output", state.state_id, output # DEBUG
        isempty(output) && continue
        @lock state.lock next(state, device, output)
    end
end

function next(state::State, who, what_system, what_user, complexity)
    @info "next", state.state_id, who, what_system, what_user, complexity # DEBUG
    if state.signals[:stop_next]
        @info "next signals[:stop_next]", state.state_id # DEBUG
        state.signals[:stop_next] = false
        return
    end
    code_string = ""
    state.signals[:intelligence_running] = true
    system_state = describe(state) * "\n" * what_system
    @info "got system_state", state.state_id, length(string(who) * system_state * what_user) # DEBUG
    isa(who, IODevice) && (system_state *= "\nThis is direct input from the user, first will run at lower complexity, use it for planning\n")

    input_logfile = file_stream("input.jl") # DEBUG
    write(input_logfile, "$who\n$system_state\n$what_user") # DEBUG
    close(input_logfile) # DEBUG

    try
        code_string = intelligence(who, system_state, what_user, complexity) # `next` is the attached intelligence (you), giving us the natural next output information from input information, and the output should be Julia code
        # code_string = read("/Users/1m1/logs/log-1763499513-output.jl", String) # DEBUG
    catch e
        @error "`intelligence` failed", state.state_id, e
        return
    finally
        state.signals[:intelligence_running] = false
    end

    @info "code_string", state.state_id, code_string # DEBUG
    output_logfile = file_stream("output.jl") # DEBUG
    write(output_logfile, code_string) # DEBUG
    close(output_logfile) # DEBUG

    code_expression, task_name = nothing, nothing
    try
        code_expression = Meta.parse(join(["begin", code_string, "end"], '\n'))
        @info "got code_expression", state.state_id, code_expression # DEBUG
        task_name = taskname(code_expression)
        @info "got task_name", state.state_id, task_name # DEBUG
    catch e
        @error "`Meta.parse` or `taskname` failed", state.state_id, e # DEBUG
        who = string(who) * "_parseortasknameerrorrerun"
        what_system = join([
            "Your code failed with Exception: $e",
            previous_input_output(what_user, code_string)...,
        ])
        what_user = "Fix and retry without making the same mistake again"
        return next(state, who, what_system, what_user, complexity)
    end

    code_imports, code_body = separate(code_expression)
    @info "got code_imports", state.state_id, code_imports # DEBUG
    @info "got code_body", state.state_id, code_body # DEBUG
    if state.safe && !confirm()
        @info "safe && !confirm()", state.state_id # DEBUG
        state.tasks[:latest_task] = TaskElement(:latest_task, what_user, code_string, Task(() -> nothing)) # to have to access to the suggested code
        return # 'safe' guaranteed to be settable by the user (via the REPL)
    end

    run_task(state, who, what_user, complexity, task_name, code_string, code_imports, code_body)
    @info "next done", state.state_id # DEBUG
end
next(state::State, who, what_user, complexity) = next(state, who, "", what_user, complexity)
next(state::State, who, what_user) = next(state, who, what_user, 0.5)
next(state::State, what_user) = next(state, "user", what_user, 1.0)
function next(state::State, w::Bool=true)
    # todo important rm old listen threads first
    [Threads.@spawn listen(state, device) for (_, device) in state.input_devices]
    # block ~ depends where the system is run from
    if w
        wait(Condition())
    end
end

function run_task(state::State, who, what_user::String, complexity, task_name::Symbol, code_string::String, code_imports::Expr, code_body::Expr)
    @info "run_task", state.state_id, who, what_user, complexity, task_name # DEBUG
    code_body = add_latest_task_closure(state, code_body)
    @info "got add_latest_task_closure", state.state_id, code_body # DEBUG
    inject_state!(state, code_body)
    @info "did inject_state!", state.state_id, code_body # DEBUG
    state.tasks[:latest_task] = state.tasks[task_name] =
        TaskElement(task_name, what_user, code_string,
            Threads.@spawn try
                eval(code_imports)
                @info "got eval(code_imports)", state.state_id # DEBUG
                eval(code_body)
            catch e
                @error "run_task", state.state_id, e # DEBUG
                e isa InterruptException && return
                e_string = Base.invokelatest(string, hasfield(typeof(e), :task) ? e.task.exception : e)
                who = string(who) * "_evalcodeerrorrerun"
                what_system = join([
                    "`tasks[:$task_name]` failed with Exception: $e_string",
                    previous_input_output(state.tasks[task_name].input, state.tasks[task_name].output)...,])
                what_user = "Fix or restart it if appropriate"
                return next(state, who, what_system, what_user, complexity)
            end)
end
previous_input_output(in, out) = ["The `input` was\n$in", "Your output code was\n$out"]

add_latest_task_closure(::State, ex) = ex
function add_latest_task_closure(state::State, ex::Expr)
    if ex.head == :(=) && isa(ex.args[1], Expr) && ex.args[1].head == :ref && ex.args[1].args[1] == :tasks && ex.args[1].args[2] == QuoteNode(:latest_task)
        throw("write to `tasks[:latest_task]` not allowed for closure")
    end
    new_args = [add_latest_task_closure(state, a) for a in ex.args]
    if ex.head == :ref && length(ex.args) == 2 && ex.args[1] == :tasks && ex.args[2] == QuoteNode(:latest_task)
        return state.tasks[:latest_task]
    end
    Expr(ex.head, new_args...)
end

function inject_state!(state::State, code::Expr)
    for (i, arg) in pairs(code.args)
        if arg isa Expr
            inject_state!(state, arg)
        elseif arg isa QuoteNode
            if arg.value isa Expr
                inject_state!(state, arg)
            elseif arg.value in fieldnames(State)

                arg = QuoteNode(Expr(:., Expr(:ref, :STATES, state.state_id), QuoteNode(arg.value)))
            end
        elseif arg in fieldnames(State)
            code.args[i] = Expr(:., Expr(:ref, :STATES, state.state_id), QuoteNode(arg))
        end
    end
    code
end

function separate(code::Expr)::Tuple{Expr,Expr}
    imports = Expr(:block)
    cleaned = Expr(code.head)
    for arg in code.args
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

function taskname(code::Expr)::Symbol
    task_name = _taskname(code)
    isnothing(task_name) && throw("need to set `task_name`")
    task_name
end
_taskname(::Any) = nothing
function _taskname(code::Expr)
    if code.head == :(=) && code.args[1] == :task_name
        return code.args[2].value
    end
    code.head ≠ :block && return nothing
    only(filter(!isnothing, _taskname.(code.args)))
end

function confirm()
    print("run code Y/n")
    answer = lowercase(strip(readline()))
    @info answer # DEBUG
    isempty(answer) || answer == 'y'
end

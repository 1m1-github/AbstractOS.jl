# todo
# add `yield()` to all loops

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

const SAFE = Ref(false)
const LOCK = ReentrantLock()
const INPUT_DEVICES = Dict{Symbol,InputDevice}()
const OUTPUT_DEVICES = Dict{Symbol,OutputDevice}()
const MEMORY = Dict{Symbol,Any}()
const KNOWLEDGE = Dict{Symbol,String}()
const TASKS = Dict{Symbol,TaskElement}(:latest_task => TaskElement(:latest_task, "", "", Task(() -> nothing)))
const SIGNALS = Dict{Symbol,Bool}(:stop_next => false, :intelligence_running => false)

macro api(args...)
    isempty(args) && return nothing
    esc(args[end])
end # used to denote parts of `KNOWLEDGE` that are presented to the `intelligence` as abilities that can be considered black-boxes (can be a struct, type, function, variable)

global OS_ROOT_DIR, OS_SRC_DIR, OS_KNOWLEDGE_DIR # only persist to OS_ROOT_DIR
include("describe.jl") # contains `describe` for various types

function learn(code_name::Symbol, code::String)
    @info "learn", code_name # DEBUG
    try
        code_expr = Meta.parse("begin $code end")
        code_name ∈ keys(KNOWLEDGE) && return
        code ∈ collect(values(KNOWLEDGE)) && return
        eval(code_expr)
        describe.(find_api_macrocalls(code_expr)) # code should be describable
        KNOWLEDGE[code_name] = code
        write(joinpath(OS_KNOWLEDGE_DIR, "$code_name.jl"), code)
    catch e
        show(e)
        throw(e)
    end
end

# todo @true mode = provable open source, always runs with SAFE==true

function listen(device::InputDevice)
    @info "listen", typeof(device) # DEBUG
    while true
        yield()
        @info "waiting to take!", typeof(device) # DEBUG
        output = take!(device)
        @info "listen output", output # DEBUG
        isempty(output) && continue
        @lock LOCK next(device, output)
    end
end

function next(who, what_system, what_user, complexity)
    @info "next", who, what_system, what_user, complexity # DEBUG
    if SIGNALS[:stop_next]
        @info "next SIGNALS[:stop_next]" # DEBUG
        SIGNALS[:stop_next] = false
        return
    end
    code_string = ""
    SIGNALS[:intelligence_running] = true
    system_state = describe() * "\n" * what_system
    @info "got system_state", length(string(who) * system_state * what_user) # DEBUG
    isa(who, IODevice) && (system_state *= "\nThis is direct input from the user, first will run at lower complexity, use it for planning\n")

    input_logfile = file_stream("input.jl") # DEBUG
    write(input_logfile, "$who\n$system_state\n$what_user") # DEBUG
    close(input_logfile) # DEBUG

    try
        # todo @async to get REPl
        code_string = intelligence(who, system_state, what_user, complexity) # `next` is the attached intelligence (you), giving us the natural next output information from input information, and the output should be Julia code
        # code_string = read("/Users/1m1/logs/log-1764313293-output.jl", String) # DEBUG
    catch e
        @error "`intelligence` failed", e
        return
    finally
        SIGNALS[:intelligence_running] = false
    end

    @info "code_string", code_string # DEBUG
    output_logfile = file_stream("output.jl") # DEBUG
    write(output_logfile, code_string) # DEBUG
    close(output_logfile) # DEBUG

    code_expression, task_name = nothing, nothing
    try
        code_expression = Meta.parse(join(["begin", code_string, "end"], '\n'))
        code_expression.head && throw(code_expression.args[1])
        @info "got code_expression", code_expression # DEBUG
        task_name = taskname(code_expression)
        @info "got task_name", task_name # DEBUG
    catch e
        @error "`Meta.parse` or `taskname` failed", e # DEBUG
        who = string(who) * "_parseortasknameerrorrerun"
        what_system = join([
            "Your code failed with Exception: $e",
            previous_input_output(what_user, code_string)...,
        ])
        what_user = "Fix and retry without making the same mistake again"
        return next(who, what_system, what_user, complexity)
    end

    code_imports, code_body = separate(code_expression)
    @info "got code_imports", code_imports # DEBUG
    @info "got code_body", code_body # DEBUG
    if SAFE[] && !confirm()
        @info "SAFE && !confirm()" # DEBUG
        TASKS[:latest_task] = TaskElement(:latest_task, what_user, code_string, Task(() -> nothing)) # to have to access to the suggested code
        return # 'SAFE' guaranteed to be settable by the user (via the REPL)
    end

    run_task(who, what_user, complexity, task_name, code_string, code_imports, code_body)
    @info "next done" # DEBUG
end
next(who, what_user, complexity) = next(who, "", what_user, complexity)
next(who, what_user) = next(who, what_user, 0.5)
next(what_user) = next("user", what_user, 1.0)
function next(w::Bool=true)
    # todo important rm old listen threads first
    # @show INPUT_DEVICES # DEBUG
    devices_to_listen = filter(kv -> kv[1] != :REPL, INPUT_DEVICES)
    [Threads.@spawn listen(device) for (_, device) in devices_to_listen]
    # block ~ depends where the system is run from
    if w
        wait(Condition())
    end
end

function run_task(who, what_user::String, complexity, task_name::Symbol, code_string::String, code_imports::Expr, code_body::Expr)
    @info "run_task", who, what_user, complexity, task_name # DEBUG
    code_body = add_latest_task_closure(code_body)
    @info "got add_latest_task_closure", code_body # DEBUG
    TASKS[:latest_task] = TASKS[task_name] =
        TaskElement(task_name, what_user, code_string,
            Threads.@spawn try
                eval(code_imports)
                @info "got eval(code_imports)" # DEBUG
                eval(code_body)
            catch e
                @error "run_task", e # DEBUG
                e isa InterruptException && return
                e_string = Base.invokelatest(string, hasfield(typeof(e), :task) ? e.task.exception : e)
                who = string(who) * "_evalcodeerrorrerun"
                what_system = join([
                    "`TASKS[:$task_name]` failed with Exception: $e_string",
                    previous_input_output(TASKS[task_name].input, TASKS[task_name].output)...,])
                what_user = "Fix or restart it if appropriate"
                return next(who, what_system, what_user, complexity)
            end)
end
previous_input_output(in, out) = ["The `input` was\n$in", "Your output code was\n$out"]

add_latest_task_closure(ex) = ex
function add_latest_task_closure(ex::Expr)
    if ex.head == :(=) && isa(ex.args[1], Expr) && ex.args[1].head == :ref && ex.args[1].args[1] == :TASKS && ex.args[1].args[2] == QuoteNode(:latest_task)
        throw("write to `TASKS[:latest_task]` not allowed for closure")
    end
    new_args = [add_latest_task_closure(a) for a in ex.args]
    if ex.head == :ref && length(ex.args) == 2 && ex.args[1] == :TASKS && ex.args[2] == QuoteNode(:latest_task)
        return TASKS[:latest_task]
    end
    Expr(ex.head, new_args...)
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

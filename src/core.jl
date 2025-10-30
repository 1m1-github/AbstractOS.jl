const YOUR_PURPOSE = "you are an a learning computer operating system"

abstract type IODevice end
abstract type InputDevice <: IODevice end # e.g. microphone, keyboard, camera, touch, ...
abstract type OutputDevice <: IODevice end # e.g. speaker, screen, AR, VR, touch, ...

struct TaskElement
    # todo maybe add `who::String`
    input::String
    output::String
    task::Task
end
safe = false # true requires confirmation from user before executing code
lock = ReentrantLock() # enforces single thread on main intelligence
input_devices = Dict{Symbol,InputDevice}() # name => device with take!(device::InputDevice)::Any implemented
output_devices = Dict{Symbol,OutputDevice}() # name => device with put!::InputDevice, info...) implemented
memory = Dict{Symbol,Any}() # ephemeral, name => anything # todo just use new vars added to jvm
knowledge = Dict{Symbol,String}() # persisted, name => code
tasks = Dict{Symbol,TaskElement}() # ephemeral, name => input, output, task
signals = Dict{Symbol,Bool}(:stop_next => false, :intelligence_running => false) # can be used to communicate

macro api(args...)
    isempty(args) && return nothing
    esc(args[end])
end # used to denote parts of `knowledge` that are presented to the `intelligence` as abilities that can be considered black-boxes (can be a struct, type, function, variable)

global OS_ROOT_DIR, OS_SRC_DIR, OS_KNOWLEDGE_DIR # only persist to OS_ROOT_DIR
include("describe.jl") # contains `describe` for various types

function learn(code_name::Symbol, code::String)
    @info "learn", code_name # DEBUG
    global knowledge
    try
        clean_code = replace(code, "@api " => "")
        code_expr = Meta.parse("begin $clean_code end")
        code_name ∈ keys(knowledge) && return
        code ∈ collect(values(knowledge)) && return
        describe.(find_api_macrocalls(code_expr)) # code should be describable
        eval(code_expr)
        knowledge[code_name] = code
        write(joinpath(OS_KNOWLEDGE_DIR, "$code_name.jl"), code)
    catch e
        show(e)
        throw(e)
    end
end

# todo @true mode = provable open source, always runs with safe==true

function listen(device::InputDevice)
    @info "listen", typeof(device) # DEBUG
    while true
        output = take!(device)
        isempty(output) && continue
        @lock lock next(device, output)
    end
end

function next(who, what_system, what_user, complexity)
    @info "next", who, what_system, what_user, complexity # DEBUG
    global signals
    if signals[:stop_next]
        @info "next signals[:stop_next]" # DEBUG
        signals[:stop_next] = false
        return
    end
    code_string = ""
    signals[:intelligence_running] = true
    try
        system_state = describe() * "\n" * what_system
        @info "got system_state", length(who * system_state * what_user) # DEBUG
        isa(who, IODevice) && (system_state *= "\nThis is direct input from the user, first will run at lower complexity, use it for planning\n")

        input_logfile = file_stream("input.jl") # DEBUG
        write(input_logfile, "$who\n$system_state\n$what_user") # DEBUG
        close(input_logfile) # DEBUG

        code_string = intelligence(who, system_state, what_user, complexity) # `next` is the attached intelligence (you), giving us the natural next output information from input information, and the output should be Julia code
        
        @info "code_string", code_string # DEBUG
        output_logfile = file_stream("output.jl") # DEBUG
        write(output_logfile, code_string) # DEBUG
        close(output_logfile) # DEBUG
    catch e
        @error "`intelligence` failed", e
        return
    finally
        signals[:intelligence_running] = false
    end

    code_expression, task_name = nothing, nothing
    try
        code_expression = Meta.parse(join(["begin", code_string, "end"], '\n'))
        @info "got code_expression" # DEBUG
        task_name = taskname(code_expression)
        @info "got task_name", task_name # DEBUG
    catch e
        @error "`Meta.parse` or `taskname` failed", e # DEBUG
        who *= "_parseortasknameerrorrerun"
        what_system = join([
            "Your code failed with Exception: $e",
            previous_input_output(what_user, code_string)...,
        ])
        what_user = "Fix and retry without making the same mistake again"
        return next(who, what_system, what_user, complexity)
    end

    code_imports, code_body = separate(code_expression)
    @info "got separate" # DEBUG
    if safe && !confirm()
        @info "safe && !confirm()" # DEBUG
        tasks[:latest_task] = TaskElement(what_user, code_string, Task(0)) # to have to access to the suggested code
        return # 'safe' guaranteed to be settable by the user (via the REPL)
    end

    run_task(who, what_user, complexity, task_name, code_string, code_imports, code_body)
    @info "next done" # DEBUG
end
next(who, what_user, complexity) = next(who, "", what_user, complexity)
next(who, what_user) = next(who, what_user, 0.5)
next(what_user) = next("user", what_user, 1.0)
function next()
    [Threads.@spawn listen(input_devices[device]) for device in keys(input_devices)]
    # block ~ depends where the system is run from
    # wait(Condition())
end

function run_task(who, what_user, complexity, task_name::Symbol, code_string::String, code_imports::Expr, code_body::Expr)
    @info "run_task", who, what_user, complexity, task_name # DEBUG
    global tasks
    code_body = add_latest_task_closure(code_body)
    @info "got add_latest_task_closure" # DEBUG
    tasks[:latest_task] = tasks[task_name] =
        TaskElement(what_user, code_string,
            Threads.@spawn try
                eval(code_imports)
                @info "got eval(code_imports)" # DEBUG
                eval(code_body)
            catch e
                @error "run_task", e # DEBUG
                e isa InterruptException && return
                e_string = Base.invokelatest(string, hasfield(typeof(e), :task) ? e.task.exception : e)
                who *= "_evalcodeerrorrerun"
                what_system = join([
                    "`tasks[:$task_name]` failed with Exception: $e_string",
                    previous_input_output(tasks[task_name].input, tasks[task_name].output)...,])
                what_user = "Fix or restart it if appropriate"
                return next(who, what_system, what_user, complexity)
            end)
end
previous_input_output(in, out) = ["The `input` was\n$in", "Your output code was\n$out"]

add_latest_task_closure(ex) = ex
function add_latest_task_closure(ex::Expr)
    if ex.head == :(=) && isa(ex.args[1], Expr) && ex.args[1].head == :ref && ex.args[1].args[1] == :tasks && ex.args[1].args[2] == QuoteNode(:latest_task)
        throw("write to `tasks[:latest_task]` not allowed for closure")
    end
    new_args = [add_latest_task_closure(a) for a in ex.args]
    if ex.head == :ref && length(ex.args) == 2 && ex.args[1] == :tasks && ex.args[2] == QuoteNode(:latest_task)
        return tasks[:latest_task]
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

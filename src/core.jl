const YOUR_PURPOSE = "you operate a learning and truthful computer operating system called AOS (AbstractOS)"

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

# const FORCED_AGENCY = Ref(false)
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
function listen(w::Bool=true)
    # todo important rm old listen threads first
    # @show INPUT_DEVICES # DEBUG
    devices_to_listen = filter(kv -> kv[1] != :REPL, INPUT_DEVICES)
    [Threads.@spawn listen(device) for (_, device) in devices_to_listen]
    # block ~ depends where the system is run from
    if w
        wait(Condition())
    end
end

function check_signals()
    if SIGNALS[:stop_next]
        @info "next SIGNALS[:stop_next]" # DEBUG
        return SIGNALS[:stop_next] = false
    end
    SIGNALS[:intelligence_running] && return false
    return SIGNALS[:intelligence_running] = true
end

function next(who, what_system, what_user, complexity)
    @info "next", who, what_system, what_user, complexity # DEBUG
    !check_signals() && return

    system_state = describe() * "\n" * what_system
    @info "got system_state", length(string(who) * system_state * what_user) # DEBUG
    # isa(who, IODevice) && (system_state *= "\nThis is direct input from the user, first will run at lower complexity, use it for planning\n")

    input_logfile = file_stream("input.jl") # DEBUG
    write(input_logfile, "$who\n$system_state\n$what_user") # DEBUG
    close(input_logfile) # DEBUG
    
    code_string = ""
    try
        # todo @async to get REPl
        code_string = intelligence(who, system_state, what_user, complexity) # `next` is the attached intelligence (you), giving us the natural next output information from input information, and the output should be Julia code
        # code_string = read("/Users/1m1/logs/log-1764389100-output.jl", String) # DEBUG
        # who="user" # DEBUG
        # what_user="""give me a list (api) of abilities you want to have to be a useful system. you can name each function as you want or expect. these are abilities that you reuse often, given that you have access to a stateful julia vm including internet access.""" # DEBUG
        # complexity=0.5 # DEBUG
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

    code_expression = nothing
    try
        code_expression = Meta.parse(join(["begin", code_string, "end"], '\n'))
        code_expression.head == :incomplete && throw(code_expression.args[1])
        @info "got code_expression", code_expression # DEBUG
    catch e return retry_on_error("`Meta.parse`: $e", "$(who)_parseerrorrerun", what_user, code_string, complexity) end
    
    task_name = nothing
    try
        task_name = taskname(code_expression)
        @info "got task_name", task_name # DEBUG
    catch e return retry_on_error("`taskname` failed: $e", "$(who)_tasknameerrorrerun", what_user, code_string, complexity) end

    code_imports, code_body = separate(code_expression)
    @info "got code_imports", code_imports # DEBUG
    @info "got code_body", code_body # DEBUG
    if SAFE[] && !confirm()
        @info "SAFE && !confirm()" # DEBUG
        TASKS[:latest_task] = TaskElement(:latest_task, what_user, code_string, Task(() -> nothing)) # to have to access to the suggested code
        return # 'SAFE' guaranteed to be settable by the user (via the REPL)
    end

    run_task(who, what_user, complexity, task_name, code_string, code_imports, code_body)
    @info "run_task" # DEBUG
end
next(who, what_user, complexity) = next(who, "", what_user, complexity)
next(who, what_user) = next(who, what_user, 0.5)
next(what_user) = next("user", what_user, 1.0)

function retry_on_error(why, who, prev_input, prev_output, complexity)
    # @info "retry_on_error", why
    what_system = join([
        "Your code failed because $why",
        "The `input` was\n$prev_input",
        "Your output code was\n$prev_output"
    ])
    what_user = "Fix and retry without making the same mistake again if appropriate"
    next(who, what_system, what_user, complexity)
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
                FORCED_AGENCY[] && next("AOS", "continue towards your goal if not fully achieved: $(what_user)")
            catch e
                e isa InterruptException && return
                e_string = Base.invokelatest(string, hasfield(typeof(e), :task) ? e.task.exception : e)
                return retry_on_error("`TASKS[:$task_name]` failed with Exception: $e_string", "$(who)_evalcodeerrorrerun", TASKS[task_name].input, TASKS[task_name].output, complexity)
            end)
end

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

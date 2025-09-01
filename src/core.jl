const YOUR_PURPOSE = "you are an a learning computer operating system"

abstract type IODevice end
abstract type InputDevice <: IODevice end # e.g. microphone, keyboard, camera, touch, ...
abstract type OutputDevice <: IODevice end # e.g. speaker, screen, AR, VR, touch, ...

struct TaskElement
    input::String
    output::String
    task::Task
end
safe = false # true requires confirmation from user before executing code
lock = ReentrantLock() # enforces single thread on main intelligence
input_devices = Dict{Symbol, InputDevice}() # name => device with take!(device::InputDevice)::Any implemented
output_devices = Dict{Symbol, OutputDevice}() # name => device with put!::InputDevice, info...) implemented
memory = Dict{Symbol, Any}() # ephemeral, name => anything
knowledge = Dict{Symbol, String}() # persisted, name => code
tasks = Dict{Symbol, TaskElement}() # ephemeral, name => input, output, task
signals = Dict{Symbol, Bool}(:stop_run => false, :next_running => false) # can be used to communicate

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
        @lock lock run(output)
    end
end

function run(device_output)
    @info "run", device_output # DEBUG
    global signals
    if signals[:stop_run]
        @info "run signals[:stop_run]" # DEBUG
        signals[:stop_run] = false
        return
    end
    code_string = ""
    signals[:next_running] = true
    try
        memory[:latest_input] = device_output
        memory[:latest_output] = code_string = next(system=describe(), user=device_output) # `next` is the attached intelligence (you), giving us the natural next output information from input information, and the output should be Julia code
        # memory[:latest_output] = code_string = read(joinpath(OS_ROOT_DIR, "logs", "output.jl"), String) # DEBUG
        @info code_string # DEBUG
        output_logfile = file_stream("output") # DEBUG
        write(output_logfile, code_string) # DEBUG
        close(output_logfile) # DEBUG
    catch e
        @error "`next` failed", e
        return
    finally
        signals[:next_running] = false
    end

    code_expression, task_name = nothing, nothing
    try
        code_expression = Meta.parse("begin $code_string end")
        task_name = taskname(code_expression)
    catch e
        @error "`Meta.parse` or `taskname` failed", e # DEBUG
        return run(join([
            "Your code failed with Exception: $e",
            previous_input_output(device_output, code_string)...,
            "Fix and retry without making the same mistake again",
            ], '\n'))
    end
    @info task_name # DEBUG
    code_imports, code_body = separate(code_expression)
    println(code_string)
    if safe && !confirm()
        tasks[:latest_task] = TaskElement(device_output, code_string, Task(0)) # to have to access to the suggested code
        return # guaranteed to be settable by the user (via the REPL)
    end

    run_task(device_output, task_name, code_string, code_imports, code_body)
    @info "run done" # DEBUG
end
function run_task(device_output::String, task_name::Symbol, code_string::String, code_imports::Expr, code_body::Expr)
    @info "run_task", device_output, task_name # DEBUG
    global tasks
    tasks[:latest_task] = tasks[task_name] = 
    TaskElement(device_output, code_string, 
    Threads.@spawn try
        eval(code_imports)
        eval(code_body)
    catch e
        @error "run_task", e # DEBUG
        e isa InterruptException && return
        return run(join([
            "`tasks[:$task_name]` failed with Exception: $(e.task.exception)",
            previous_input_output(tasks[task_name].input, tasks[task_name].output)...,
            "Fix or restart it if appropriate"
        ], '\n'))
    end)
end
function run()
    [Threads.@spawn listen(input_devices[device]) for device in keys(input_devices)]
    # block ~ depends where the system is run from
    # wait(Condition())
end
previous_input_output(in, out) = ["The `device_output` was: $in", "Your output code was: $out"]

function separate(code::Expr)::Tuple{Expr, Expr}
    imports = Expr(:block)
    cleaned = Expr(code.head)
    for arg in code.args
        if isa(arg, Expr)
            if arg.head in (:using, :import) || (arg.head == :call && arg.args[1] == :(Pkg.add))
                push!(imports.args, arg)
            elseif arg.head == :macrocall
                push!(cleaned.args, arg)
            else
                sub_imports, sub_cleaned  = separate(arg)
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

# + restrict write area: running user

const YOUR_PURPOSE = "you are an a computer operating system"

abstract type IODevice end
abstract type InputDevice <: IODevice end # e.g. microphone, keyboard, camera, touch, ...
abstract type OutputDevice <: IODevice end # e.g. speaker, screen, AR, VR, touch, ...
# `describe(device::IODevice)` exists
# `take!(device::InputDevice)` exists
# `put!(device::OutputDevice, info)` exists

safe = false
lock = ReentrantLock()
inputs = Dict{Symbol, InputDevice}()
outputs = Dict{Symbol, OutputDevice}()
memory = Dict{Symbol, Any}()
knowledge = Dict{Symbol, String}()
tasks = Dict{Symbol, Task}()
signals = Dict{Symbol, Bool}(:stop_run => false, :next_running => false)
errors = Exception[]

macro api(args...) 
    isempty(args) && return nothing
    esc(args[end])
end # used to denote parts of `knowledge` that are presented to the `intelligence` as abilities that can be considered black-boxes

function learn(code_name::Symbol, code::String)
    @debug code_name # DEBUG
    try
        clean_code = replace(code, "@api " => "")
        @debug "got clean_code"
        code_expr = Meta.parse("begin $clean_code end")
        @debug "code_expr" # DEBUG
        code_name ∈ keys(knowledge) && return
        @debug "code_name ∉ keys(knowledge)" # DEBUG
        code ∈ collect(values(knowledge)) && return
        @debug "code ∉ collect(values(knowledge))" # DEBUG
        eval(code_expr)
        @debug "eval" # DEBUG
        knowledge[code_name] = code
        write("libs/$(code_name)_1M1.jl", code)
        @debug "learned $code_name"  # DEBUG
    catch e
        show(e)
        throw(e)
    end
end

# todo @true mode = provable open source, always runs with safe==true

num_tokens(s) = length(split(s, r"\s+"; keepempty=false))

function listen(device::InputDevice)
    @debug device # DEBUG
    while true
        output = take!(device)
        @debug "output", length(output), num_tokens(output) # DEBUG
        memory[Symbol("$(typeof(device))/output")] = output
        isempty(output) && continue
        @debug output # DEBUG
        @lock lock run(output)
    end
end


function run(device_output; files=[])
    @debug "run", length(device_output), num_tokens(device_output) # DEBUG
    global memory, signals, errors
    signals[:stop_run] && ( @debug "signals[:stop_run] = false"; signals[:stop_run] = false ) && return
    @debug signals, signals[:stop_run] # DEBUG
    clean(tasks)
    @debug "cleaned tasks", length(tasks) # DEBUG
    input = "$(describe())\n$device_output"
    @debug "got input", length(input), num_tokens(input) # DEBUG
    write(log_name("input"), input) # DEBUG
    # input = read("log/input.jl", String) # DEBUG
    errors = Exception[]
    try
        signals[:next_running] = true
        memory[:output] = julia_code = next(input, files=files) # `next` is implemented by the attached intelligence
        # memory[:output] = julia_code = read("log/output.jl", String) # DEBUG
    catch e
        @debug "next failed", e
        return
    finally
        signals[:next_running] = false
    end
    @debug "got output", length(julia_code), num_tokens(julia_code) # DEBUG
    println(julia_code)
    write(log_name("output"), julia_code) # DEBUG
    julia_code = "begin $julia_code end"
    run_task(julia_code)
    @debug "after run_task"
end

function run_task(julia_code::String)
    @debug "run_task" # DEBUG
    task_name, task = run_code_inside_task(julia_code)
    @debug task_name, task # DEBUG
    isnothing(task_name) && isnothing(task) && return 
    isnothing(task_name) && throw("need to set `task_name`")
    global tasks
    tasks[task_name] = task
    Threads.@spawn wait_and_monitor_task_for_error(task)
end

function run_code_inside_task(julia_code::String)
    @debug "run_code_inside_task" # DEBUG
    try
        imports, body = separate(Meta.parse(julia_code))
        @debug "separate", safe  # DEBUG
        safe && !confirm() && return  # guaranteed to be settable by the user (via the REPL)
        eval(imports)
        @debug "eval" # DEBUG
        task = Threads.@spawn eval(body)
        @debug "task" # DEBUG
        return taskname(body), task
    catch e
        @debug "error", e # DEBUG
        global errors
        push!(errors, e)
        run("there was an error, try and never make the same mistake again.")
    end
end

function describe()::String
    join([
            "describe() BEGIN\n",
            "OS source code BEGIN:\n" * read(CORE_PATH, String) * "==\nOS source code END",
            "inputs BEGIN:\n" * join(map(symbol -> "describe(inputs[:$symbol]) = \"" * describe(inputs[symbol]) * "\"", collect(keys(inputs))), '\n') * "\ninputs END",
            "outputs BEGIN:\n" * join(map(symbol -> "describe(outputs[:$symbol]) = \"" * describe(outputs[symbol]) * "\"", collect(keys(outputs))), '\n') * "\noutputs END",
            "memory BEGIN:\n" * join(map(symbol -> "$symbol => $(memory[symbol])", collect(keys(memory))), '\n') * "\nmemory END",
            "knowledge BEGIN:\n" * join(map(code_name ->  describe(code_name, knowledge[code_name]), collect(keys(knowledge))), '\n') * "\nknowledge END",
            "tasks BEGIN:\n" * join(keys(tasks), ',') * "\ntasks END",
            "signals BEGIN:\n" * join(map(symbol -> "$symbol => $(signals[symbol])", collect(keys(signals))), ',') * "\nsignals END",
            "errors BEGIN:\n" * join(map(describe, errors), '\n') * "\nerrors END",
            "describe() END\n==\n",
        ], "==\n")
end
function describe(e::Exception)
    io = IOBuffer()
    Base.showerror(io, e)
    String(take!(io))
end
function describe(code_name::Symbol, code::String)
    result = "knowledge[$code_name] BEGIN"
    code_expr = Meta.parse("begin $code end")
    result = [result, describe(code_expr)...]
    push!(result, "knowledge[$code_name] END")
    join(result, '\n')
end
function describe(expr::Expr)
    if expr.head == :macrocall && expr.args[1] == Symbol("@api")
        expr = expr.args[3]
        if expr.head == :struct
            lines = ["struct $(expr.args[2])"]
            for l in expr.args[3].args
                isa(l, LineNumberNode) && continue
                push!(lines, string(l))
            end
            push!(lines, "end")
            return join(lines, '\n')
        end
        return string(expr.args[1])
    end
    descriptions = vcat([describe(arg) for arg in expr.args]...)
    filter(d -> !isnothing(d), descriptions)
end
describe(a) = nothing

function wait_and_monitor_task_for_error(task::Task)
    try wait(task) catch e 
        @debug "wait_and_monitor_task_for_error, error, $e, $(e.task.exception), "
        bt = catch_backtrace()
        @debug length("$bt")
        # limited_bt = bt[1:min(length(bt), 1000)] # todo magic # DEBUG
        Base.show_backtrace(stdout, bt)
        global errors
        push!(errors, e.task.exception)
        @debug length(errors)
        run("there was an error, try again and never make the same mistake again, $e, $(e.task.exception).")
    end
end

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

function taskname(code::Expr)
    for arg in code.args
        if isa(arg, Expr)
            if arg.head == :(=) && arg.args[1] == :task_name
                return arg.args[2].value
            end
            argValue = taskname(arg)
            isa(argValue, Symbol) && return argValue
        end
    end
    nothing
end

function clean(t::Dict{Symbol, Task})
    global tasks
    name_and_tasks = map(s -> (s, t[s]), collect(keys(t)))
    done_name_and_tasks = filter(name_and_task -> istaskdone(name_and_task[2]), name_and_tasks)
    map(name_and_task -> delete!(tasks, name_and_task[1]), done_name_and_tasks)
end

function confirm()
    print("run code Y/n")
    answer = lowercase(strip(readline()))
    @debug answer
    isempty(answer) || answer == 'y'
end
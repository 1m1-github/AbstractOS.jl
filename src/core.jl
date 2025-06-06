const YOUR_PURPOSE = """
you are an intelligence operating a machine using this computer operating system. 
upon command, manipulate the state as appropriate. your response is the output of `next`.
provide an amazing experience to the user with this most powerful ever built OS. it is AbstractOS because it deals with any inputs and outputs, it is EngineerOS because you build and learn together with the user, it is HumanOS because the user can talk, gesture as with any other human, provided the correct input modules.
ONLY return raw Julia code (without any types of quotes). return text that when run with `eval(Meta.parse(YourResponse))` will manipulate the system, that means not wrapped in a string or anything, not prepended with non-code, you communicate only via the `outputs`.
when learning, after the import/using and such commands, encapsulate everything else into functions (some functions with @api) and do not run any of these functions, because `learn` `eval`s the code, we want to add this code to `knowledge`, not run this, which we probably just ran and want to learn becauseit worked and is working; `learn` `eval`s to have the functions loaded
always consider your `knowledge`, reuse whenever possible instead of reinventing .
always set `task_name`, this allows you to stop the task in the future.
when there is an error, there is no fixing unless you rerun it fixed.
to stop any `Task`, get the `Task` from the `tasks` `Dict` and run `schedule(tasks[:some_task_name], InterruptException(),error=true)`.
"""

abstract type InputOutputDevice end
abstract type InputDevice <: InputOutputDevice end # e.g. microphone, keyboard, camera, touch, ...
abstract type OutputDevice <: InputOutputDevice end # e.g. speaker, screen, AR, VR, touch, ...
# `describe(device::InputOutputDevice)` exists
# `take!(device::InputDevice)` exists
# `put!(device::OutputDevice, info)` exists

safe = false
lock = ReentrantLock()
inputs = Dict{Symbol, InputDevice}()
outputs = Dict{Symbol, OutputDevice}()
memory = Dict{Symbol, Any}()
knowledge = Dict{Symbol, String}()
tasks = Dict{Symbol, Task}()
signals = Dict{Symbol, Bool}()
errors = Exception[]

macro api(args...) 
    isempty(args) && return nothing
    esc(args[end])
end # used to denote parts of `knowledge` that are presented to the `intelligence` as abilities that can be considered black-boxes

function learn(code_name::Symbol, code::String)
    try
        clean_code = replace(code, "@api " => "")
        code_expr = Meta.parse("begin $clean_code end")
        code_name ∈ keys(knowledge) && return
        code ∈ collect(values(knowledge)) && return
        eval(code_expr)
        knowledge[code_name] = code
        write("libs/$(code_name)_1M1.jl", code)
        @show "learned $code_name"
    catch e
        show(e)
        throw(e)
    end
end

# todo @true mode = provable open source, always runs with safe==true

function listen(device::InputDevice)
    while true
        output = take!(device)
        isempty(output) && continue
        @lock lock run(output)
    end
end

function run(device_output; files=[])
    clean(tasks) # rm 'done' tasks
    input = "$(describe())\n$device_output"
    memory[:input] = input
    write("log/input.jl", input) # DEBUG
    global errors ; errors = Exception[] # `inputs` contains errors
    signals[:next_running] = true
    memory[:next] = julia_code = next(input, files=files) # `next` is implemented by the attached intelligence
    # memory[:next] = julia_code = read("log/output.jl", String) # DEBUG
    signals[:next_running] = false
    println(julia_code)
    write("log/output.jl", julia_code) # DEBUG
    run_task("begin $julia_code end")
end

function run_task(julia_code::String)
    task_name, task = run_code_inside_task(julia_code)
    isnothing(task_name) && isnothing(task) && return 
    isnothing(task_name) && throw("need to set `task_name`")
    tasks[task_name] = task
    Threads.@spawn wait_and_monitor_task_for_error(task)
end

function run_code_inside_task(julia_code::String)
    try
        imports, body = separate(Meta.parse(julia_code))
        safe && !confirm() && return  # guaranteed to be settable by the user (via the REPL)
        eval(imports)
        task = Threads.@spawn eval(body)
        return taskname(body), task
    catch e
        @show "run_code_inside_task error", e # DEBUG
        push!(errors, e)
        return nothing, nothing
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
        return string(expr.args[1])
    end
    descriptions = vcat([describe(arg) for arg in expr.args]...)
    filter(d -> !isnothing(d), descriptions)
end
describe(a) = nothing

function wait_and_monitor_task_for_error(task::Task)
    try wait(task) catch e 
        @show "wait_and_monitor_task_for_error, error, $e, $(e.task.exception), "
        bt = catch_backtrace()
        limited_bt = bt[1:min(length(bt), 100)] # todo magic #
        Base.show_backtrace(stdout, limited_bt)
        push!(errors, e.task.exception)
    end
end

function separate(code::Expr)::Tuple{Expr, Expr}
    imports = Expr(:block)
    cleaned = Expr(code.head)

    for arg in code.args
        if isa(arg, Expr)
            if arg.head in (:using, :import) || (arg.head == :call && arg.args[1] == :(Pkg.add))
                push!(imports.args, arg)
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
    name_and_tasks = map(s -> (s, t[s]), collect(keys(t)))
    done_name_and_tasks = filter(name_and_task -> istaskdone(name_and_task[2]), name_and_tasks)
    map(name_and_task -> delete!(tasks, name_and_task[1]), done_name_and_tasks)
end

function confirm()
    print("run code Y/n")
    answer = lowercase(strip(readline()))
    isempty(answer) || answer == 'y'
end

[Threads.@spawn listen(inputs[device]) for device in keys(inputs)]
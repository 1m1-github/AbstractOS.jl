include("auxilary.jl")

const YOUR_PURPOSE = """
you are an intelligence operating a machine using this computer operating system. 
upon command, manipulate the state as appropriate. your response is the output of `next`.
provide an amazing experience to the user with this most powerful ever built OS. it is AbstractOS because it deals with any inputs and outputs, it is EngineerOS because you build and learn together with the user, it is HumanOS because the user can talk, gesture as with any other human, provided the correct input modules.
ONLY return raw Julia code (without any types of quotes). return text that when run with `eval(Meta.parse(YourResponse))` will manipulate the system, that means not wrapped in a string or anything, not prepended with non-code, you communicate only via the `outputs`.
"""

abstract type InputDevice <: InputOutputDevice end # e.g. microphone, keyboard, camera, touch, ...
abstract type OutputDevice <: InputOutputDevice end # e.g. 
# `describe(device::InputOutputDevice)` exists
# `take!(device::InputDevice)` exists
# `put!(device::OutputDevice, info)` exists

safe = false
lock = ReentrantLock()
inputs = Dict{Symbol, InputDevice}()
outputs = Dict{Symbol, OutputDevice}()
memory = Dict{Symbol, Any}()
knowledge = Dict{Symbol, String}()
tasks = Dict{Symbol, Tuple{Base.Threads.Atomic{Bool}, Task}}()
signals = Dict{Symbol, Bool}()
errors = Exception[]

macro api(expr) 
    return expr 
end # used to denote parts of `knowledge` that are presented to the `intelligence` as abilities that can be considered black-boxes

function learn(code_name::Symbol, code::String)
    try
        code_without_api_macro = replace(code, "@api " => "")
        code_expr = Meta.parse("begin $code_without_api_macro end")
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

function run(device_output)
    clean(tasks) # rm 'done' tasks
    input = "$(describe(OSCoreFileName = @__FILE__))\n$device_output"
    global errors ; errors = Exception[] # `inputs` contains errors
    signals[:next_running] = true
    memory[:next] = julia_code = next(input) # `next` is implemented by the attached intelligence
    # memory[:next] = julia_code = read("log/output.jl", String) # DEBUG
    signals[:next_running] = false
    println(julia_code)
    write("log/input.jl", input) # DEBUG
    write("log/output.jl", julia_code) # DEBUG
    run_task("begin $julia_code end")
end

function run_task(julia_code::String)
    task_name, stop, task = run_code_inside_task(julia_code)
    isnothing(task_name) && isnothing(stop) && isnothing(task) && return 
    isnothing(task_name) && ( task_name = :task )
    tasks[task_name] = (stop, task)
    Threads.@spawn wait_and_monitor_task_for_error(task)
end

function run_code_inside_task(julia_code::String)
    try
        imports, body = separate(Meta.parse(julia_code))
        safe && !confirm() && return  # guaranteed to be settable by the user (via the REPL)
        eval(imports)
        stop = Base.Threads.Atomic{Bool}(false)
        expr = quote
            let stop = $stop
                $body
            end
        end
        task = Threads.@spawn eval(expr)
        return taskname(body), stop, task
    catch e
        @show "run_code_inside_task error", e # DEBUG
        push!(errors, e)
        return nothing, nothing, nothing
    end
end

function confirm()
    print("run code Y/n")
    answer = lowercase(strip(readline()))
    isempty(answer) || answer == 'y'
end

[Threads.@spawn listen(inputs[device]) for device in keys(inputs)]
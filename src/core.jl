# AbstractOS

const SYSTEM_PROMPT = """
you operate AbstractOS. only return julia code. return code that when run with `eval(Meta.parse(yourCode))` will manipulate the system, that means not wrapped in a string or anything.
write code that is easy to read, descriptive human language, using variables and more lines rather than convoluted arguments. remember to use include/using/import or even Pkg.add if needed. use camelCase for everything.
your code can change context to provide info for future prompts (e.g. add context["it"]="..." to whatever "it" naturally would correspond to given all the current information).
to communicate with the user, use `put!` on the `outputDevice` of some outputDevice, the list of which were printed for you.
`learn`ing a function will give you its signature in future prompts. `learn` a only function is you are told to do so.
"""

Context = Dict{AbstractString, AbstractString}
abstract type InputOutputDevice end
abstract type InputDevice <: InputOutputDevice end
abstract type OutputDevice <: InputOutputDevice end
# `take!(device::InputDevice)` exists
# `put!(device::OutputDevice, info)` exists

inputDevices = InputDevice[]
outputDevices = OutputDevice[]
modules = Module[]
context = Context()
learnedFunctions = Set{Function}()
nextHistory = String[]

learn(f::Function) = push!(learnedFunctions, f)
learn(learn)

function state()
    join([
        "$(read(@__FILE__, String))",
        "inputDevices: $(map(print, inputDevices))",
        "outputDevices: $(map(print, outputDevices))",
        "modules: $(map(print, modules))",
        "context: $(map(symbol -> "$symbol => $context[symbol]", collect(keys(context))))",
        "learnedFunctions: $(map(print, collect(learnedFunctions)))",
    ], '\n')
end

function inputDeviceListener(device::InputDevice)
    while true
        print("\n>")
        deviceOutput = take!(device)
        run(deviceOutput)
    end
end

function run(deviceOutput)
    inputs = [state(), join(nextHistory, '.'), deviceOutput]
    write("inputs.txt", join(inputs,'\n'))
    output::String = next(inputs)
    write("output.txt", output)
    push!(nextHistory, output)
    outputAsABeginBlock = "begin\n$output\nend"
    expr = Meta.parse(outputAsABeginBlock)
    # todo add ask before run param or sandbox
    try
        eval(expr)
    catch e 
        @show e
        push!(nextHistory, "error: $e")
    end
end
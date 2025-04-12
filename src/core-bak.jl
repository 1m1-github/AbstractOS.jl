# AbstractOS is an operating system written in julia.
# 
# This core of the OS It lets an intelligent operator 

# export init
# todo package creation and loading, also what if loading overrides a function used by this core

# const GENERAL_PREPEND =
# """
# you run an operating system written in julia. output only julia code. this code will be run 
# use human language descriptive names for everything using camelCase.
# use type annotation for all variables and inputs and the output of the function.
# """

# const TRUTH_PREPEND =
# """
# you are asked to run whichever computation in "truth" mode, enclose your output in a @truth macro.
# in truth mode, all the information is provably true, as alive on the best known trustless network, Algorand-mainnet.
# all code in truth mode will be compiled to AVM bytecode and if asked to run, execute on Algorand-mainnet.
# """
# # todo could add check of correct connection on each command, increasing cost yet ensuring truth

# const LEARNED_FUNCTIONS_PREPEND =
# """
# assume you have the following functions available to use already:
# """

# const LOADED_PACKAGES_PREPEND =
# """
# the following julia modules are already imported:
# """

# const CONTEXT_PREPEND =
# """
# the following determiners exist in a Dict{Language, JuliaCode} called context, and you can use them:
# """

# const SYSTEM_USER_INPUT_DIVIDER = "__SYSTEM_USER_INPUT_DIVIDER__"

# learners, input-to-human-language-conversion
# output-conversions

struct Parameters
    askBeforeRunningCode:Bool
    runCodeInSandbox:Bool
end

abstract type Language <: AbstractString end
abstract type JuliaCode <: Language end
abstract type Signature <: JuliaCode end
Context = Dict{Language, Language}

struct Resources
    inputDevices::Set{InputDevice}
    outputDevices::Set{OutputDevice}
    learnedFunctions::Set{Function}
    context::Context # dict{Symbol, Language}, choose efficiently
    parameters::Parameters
    modules::Vector{Module}
end

# input devices, e.g. camera (light), microphone (sound), keyboard (text), touch (movement), pointer (e.g. mouse or a finger, defines a coordinate)
# output devices, e.g. screen (light), speaker (sound), robot (movement)
# abstract type Learner end
abstract type InputOutputDevice end
abstract type InputDevice <: InputOutputDevice end
inputDevices = InputDevice[]
abstract type OutputDevice <: InputOutputDevice end
outputDevices = OutputDevice[]

tasks = Task[]

# learner == transformer == LLM == machine

# Information = Any
# abstract type Information end
# abstract type Language end
abstract type Language <: AbstractString end # of information

# lib functions?
# todo at least in init! check correct connection to truth source provably by running a smart contract and checking `global GenesisHash`

"""
connect to learners
init input and output devices
init any other libraries
"""
function init!(;
    _inputDevices::Array{InputDevice},
    _outputDevices::Array{OutputDevice},
    _modules::Vector{Module},
    _parameters::Parameters = Parameters(true, false) # (askBeforeRunningCode, runCodeInSandbox)
)::Resources
    context = 
    resources = Resources(_inputDevices, _outputDevices)
    map(init!, resources.inputDevices)
    map(init!, resources.outputDevices)
    # init!(resources.learner)
    push!(resources.learnedFunctions, learn)
    resources.context = init!(Context())
    resources.parameters = _parameters
    resources.modules = _modules
    # todo add exported functions from resources.modules to resources.learnedFunctions if the module is unknown to the learner, add ability to tell core whether a should be `explain`ed to the learner. 
    resources
end

exit = false

"""
runs main loop of the operating system
"""
function run()
    global exit
    while !exit
        
    end
end

"""
"""
function getInput(resources::Resources)
    map(receive, resources.inputDevices)
    input = 
end

"""
given any information input, next(x) is the 'appropriate' output information
input could be text, e.g. "what is the time right now?", "take a screenshot"=="save a screenshot"
input could be hand gesture, e.g. 3 fingers shown downwards
input could be audio in some language
"""
# function next(input::Information)
function next!(resources::Resources, input)
    inputAsLanguage::Language = convert(Language, input) # `convert` exists in an input conversion library
    inputAsLanguage = addPrependToInputLanguage(resources, inputAsLanguage)
    output = next(inputAsLanguage) # `next` exists in a learner library
    map(device -> show!(output, device), outputDevices) # `show!` exists in an output library
    update!(resources.context, output) # `update!` exists in a context library
end

signature(func::Function) = signature(func, first(methods(func)))
function signature(func::Function, method::Method)::Signature
    @assert method in methods(func)
    functionName = string(method.name)
    inputNames = split(method.slot_syms, '\0')[2:end-2]
    inputTypes = map(string, method.sig.parameters[2:end])
    returnType = Base.return_types(func, Tuple{Int, String})[1]
    sig = "$functionName("
    for (inputName, inputType) in zip(inputNames, inputTypes)
        sig = "$sig$inputName::$inputType,"
    end
    sig = sig[1:end-1] # remove last ,
    sig = "$sig)::$returnType"
end
function explain(m::Module)::Vector{Signature}
    signatures = Signature[]
    for name in names(m)
        field = getfield(m, name)
        !isa(field, Function) && continue
        push!(signatures, signature(field))
    end
    signatures
end

function addPrependToInputLanguage(resources::Resources, input::Language)::Language
    global SYSTEM_USER_INPUT_DIVIDER, GENERAL_PREPEND, LEARNED_FUNCTIONS_PREPEND
    learnedFunctionsSignatures = String[]
    for func in resources.learnedFunctions, method in methods(func)
        sig = signature(func, method)
        push!(learnedFunctionsSignatures, sig)
    end
    learnedFunctions = join(learnedFunctionsSignatures, '\n')
    determiners = join(keys(resources.context), ',')
    modules = join(values(Base.loaded_modules), ',') # todo could rm base julia packages (the ones always loaded) and need to add exported functions from packages that the learner does not know about
    """
    $GENERAL_PREPEND
    $TRUTH_PREPEND
    $LEARNED_FUNCTIONS_PREPEND:$learnedFunctions
    $LOADED_PACKAGES_PREPEND:$modules
    $CONTEXT_PREPEND:$determiners
    $SYSTEM_USER_INPUT_DIVIDER
    $input
    """
end

"""
add function for the learner
"""
learn(resources::Resources, f::Function) = push!(resources.learnedFunctions, f)

"""
updates an device given some output information
typeof, convert, update! are defined in the OutputDevice library
"""
function show!(output, device::OutputDevice)
    typeNeededByDevice = inputType(device)
    outputAsNeededByDevice = convert(typeNeededByDevice, output)
    update!(device, outputAsNeededByDevice)
end

"""
resources = init!(
    _inputDevices::Array{InputDevice},
    _outputDevices::Array{OutputDevice},
    _parameters::Parameters
    _modules::Vector{Module},
)
run(resources)

example

import MicrophoneAbstractOSLib, ScreenAbstractOSLib
run(init!(
    [MicrophoneAbstractOSLib.mic],
    [ScreenAbstractOSLib.screen],
    Module[] # no modules
    # default parameters
))
"""
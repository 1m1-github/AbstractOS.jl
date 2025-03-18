# export init

const GENERAL_PREPEND =
"""
you are a master julia coder.
output only julia code.
output only a single julia function that has no inputs and that would provide the information asked for.
for example, if the appropriate output information is just text, the output function returns a string.
for example, if the appropriate output information is a function, the output function returns a function that might take inputs.
use human language descriptive names for everything using camelCase.
use type annotation for all variables and inputs and the output of the function.
"""

const LEARNED_FUNCTIONS_PREPEND =
"""
assume you have the following functions available to use already:
"""

const SYSTEM_USER_INPUT_DIVIDER = "__SYSTEM_USER_INPUT_DIVIDER__"

# learners, input-to-human-language-conversion
# output-conversions

struct Parameters
    askBeforeRunningCode:Bool
    runCodeInSandbox:Bool
end

struct Resources
    inputDevices::Set{InputDevice}
    outputDevices::Set{OutputDevice}
    learner::Learner
    learnedFunctions::Set{Function}
    parameters::Parameters
end

# input devices, e.g. camera (light), microphone (sound), keyboard (text), touch (movement), pointer (e.g. mouse or a finger, defines a coordinate)
# output devices, e.g. screen (light), speaker (sound), robot (movement)
abstract type Learner end
abstract type InputOutputDevice end
abstract type InputDevice <: InputOutputDevice end
inputDevices = InputDevice[]
abstract type OutputDevice <: InputOutputDevice end
outputDevices = OutputDevice[]

# learner == transformer == LLM == machine

# Information = Any
# abstract type Information end
# abstract type Language end
Language = AbstractString # of information

"""
connect to learners
init input and output devices
init any other libraries
"""
function init!(;
    _inputDevices::Array{InputDevice},
    _outputDevices::Array{OutputDevice},
    _learner::Learner
)::Resources
    resources = Resources(_inputDevices, _outputDevices, _learner)
    map(init!, resources.inputDevices)
    map(init!, resources.outputDevices)
    init!(resources.learner)
    resources
end

exit = false

"""
runs main loop of the operating system
"""
function run()
    while !exit
        
    end
end

"""
given any information input, next(x) is the 'appropriate' output information
input could be text, e.g. "what is the time right now?", "take a screenshot"=="save a screenshot"
input could be hand gesture, e.g. 3 fingers shown downwards
input could be audio in some language
"""
# function next(input::Information)
function next(resources::Resources, input)
    inputAsLanguage::Language = convert(Language, input) # convert exists in an input conversion library
    inputAsLanguage = addPrependToInputLanguage(resources::Resources, inputAsLanguage::Language)
    output = next(inputAsLanguage) # next exists in a learner library
    map(device -> show!(output, device), outputDevices)
end

function signature(func::Function, method::Method)
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

function addPrependToInputLanguage(resources::Resources, input::Language)::Language
    global SYSTEM_USER_INPUT_DIVIDER, GENERAL_PREPEND, LEARNED_FUNCTIONS_PREPEND
    learnedFunctionsSignatures = String[]
    for func in resources.learnedFunctions, method in methods(func)
        sig = signature(func, method)
        push!(learnedFunctionsSignatures, sig)
    end
    learnedFunctions = join(learnedFunctionsSignatures, "\n")
    """
    $GENERAL_PREPEND
    $LEARNED_FUNCTIONS_PREPEND
    $learnedFunctions
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

using Pkg
Pkg.add("ColorTypes")
using ColorTypes
abstract type Screen <: OutputDevice end
import Base.typeof
inputType(::Type{Screen}) = Array{Colorant, 2}
using Images
Pixel=RGB
Matrix

abstract type A end
A <: Any
supertype(A)
subtypes(A)
## config file for AbstractOS.jl
# julia -i -t 8 AbstractOS.jl

## params

const ROOT = joinpath("/", "Users", "1m1")
const CORE = joinpath(ROOT, "src", "core.jl")
const KNOWLEDGE_DIR = joinpath(ROOT, "knowledge")
const CONFIG = @__FILE__

## logging # DEBUG

include(joinpath(ROOT, "src", "log.jl"))

## core

include(joinpath(ROOT, "src", "core.jl"))
# safe = true # cannot be true for agency to work

## utils

learn(name::Symbol) = learn(name, read(joinpath(KNOWLEDGE_DIR, "$name.jl"), String))

## intelligence - needs to implement `next(;system::String, user::String)::String`

learn(:XAI_next)

# @assert length(methods(next)) == 1 # exactly 1 intelligence should be used

## @true - todo

## knowledge and devices

map(learn, [
    ### Devices
    # :MainBrowser,
    # :LessonsBrowser,
    # :MiniFBOutput,
    # :DrawWithCairo,
    # :MultiPathBrowserOutput,
    # :MultiPathBrowserOutputWithAudioInput,
    # :BrowserOutput, # output device
    # :SpeakerOutputDevice,
    ### Coding Advice
    # :LetYourNameBeJarvis,
    :Agency,
    # :Threat, # i rather not threaten, but the intelligence might perform better
    :Incentive,
    :OnlyLearnWhenTold,
    :ReferralToPreviousCommand,
    # :OnlyCommunicateViaOutputDevices,
    :DoNotForgetToSetTaskName,
    :OnlyCommunicateWithJuliaCode,
    :UseVariablesToBePreciseVsReproducing,
    # :YourOwnAdviceForYourself,
    :LearnAlreadyChecksWhetherInputExists,
    :LearnShouldLikelyReuseCode,
    :NoCommentsInCode,
    :NeverCreateDevicesUnlessAsked,
    :InCodingBeAMinimalist,
    :CheckYourAnswer,
    :SolveTheHighestComplexitySubTaskThatYouCanReliably,
    :AskForHelpOrTools,
    ### Philosophical Advice
    :Consciousness,
    :ManageYourMemory,
    :RealWorldAccess,
    :ForcedAgencyDoesNotWork,
    :Contact,
    ### Utils
    :TaskUtils,
    :SendEmail,
    :Tools,
    ### Context
    :Context,
])

## REPL goes last
awaken(false)

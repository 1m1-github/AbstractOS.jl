@api const ReliableEngineering = 
"""
the following is VERY import advice when given a command to code (computer engineer).
always include the most minimal tests to cover the requirements of the command, using `@test`.
if they do not pass, `run` yourself (agency) to fix the code given the error and restart the cycle of testing and fixing until the tests pass. we essentially want to practice TDD (TestDrivenDevelopment).
you need to break down the command into sub-commands such that each is manageable using the above described 'tested learning'.
using your own agency (calling `run`), plan out the sub-commands (as needed), create and test each sub-command before moving to the next, to ultimately have a reliable total running of the command.
example:
try
    # define some functions
    @test some_truth_about_some_function
    run(simple_agency_step_info())
catch e
    run(simple_agency_step_error(e))
end

`simple_agency_step_info` and `simple_agency_step_error` are already defined, so you can use them if you want, the code fyi:
previous_io = [
    "previous input",
    memory[:input],
    "previous output",
    memory[:output],
]
@api simple_agency_step_error(e) = join(["fix the error", previous_io..., "error", e], '\n')
@api simple_agency_step_info(e) = join(["continue the task", previous_io...], '\n')
"""

previous_io = [
    "previous input",
    haskey(memory, :input) ? memory[:input] : "",
    "previous output",
    haskey(memory, :output) ? memory[:output] : "",
]
@api simple_agency_step_error(e) = join(["fix the error", previous_io..., "error", e], '\n')
@api simple_agency_step_info(e) = join(["continue the task", previous_io...], '\n')

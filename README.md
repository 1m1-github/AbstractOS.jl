# AbstractOS == InfoOS == JuliaOS == HumanOS == EngineerOS == MagicOS

A computer operating system that can learn to do anything

# Use

Install Julia: https://julialang.org/downloads/

Download: https://github.com/1m1-github/AbstractOS.jl (this repository)

Edit: `AbstractOS.jl` to choose your intelligence, to choose the knowledge available on system start, to choose the devices that you are using, and choose the paths where the system will run [this is your OS config file]

Run: `julia -t NUM_THREADS` (1 < NUM_THREADS) to start the JVM (Julia virtual machine)
and `include(AbstractOS.jl)` inside the JVM

REPL/terminal gives access backend to the virtual machine 

Run: `run("some_command")`

# Core

`core.jl` gives the plug-in intelligence access to all input and output devices and the ability to learn (add to knowledge)

# Knowledge

Adding knowledge is what gives and retains ability to the sytem. The bare core has only the ability to learn (plus the abilities of the bare JVM)

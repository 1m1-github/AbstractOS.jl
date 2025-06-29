import Pkg

Pkg.add("Revise")
using Revise

@show pwd()
@show readdir()
cd("AbstractOS")
include("AbstractOS.jl")

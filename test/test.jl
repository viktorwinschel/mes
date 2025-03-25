using Pkg
Pkg.activate(".")
push!(LOAD_PATH, "../src/")
Pkg.instantiate()

using Test
include("runtests.jl")
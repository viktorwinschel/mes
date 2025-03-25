using Pkg
Pkg.activate(".")
push!(LOAD_PATH, "../src/")
Pkg.instantiate()

using Test
using MES

include("runtests.jl")
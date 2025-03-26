using Pkg
Pkg.activate(".")

using DataFrames
using CSV
using Dates
using Parameters

# Import MoMaSCF parameters and state
include("../MOMA/examples/national_accounting/momascf.jl")

# The simulation data is already saved in simulation_data/data_full.csv
# Let's read it and display the structure

# Read the simulation data
df = CSV.read("simulation_data/data_full.csv", DataFrame)

println("\nMoMaSCF Simulation Data Structure:")
println("==================================")
println("Number of periods: ", nrow(df))
println("Number of variables: ", ncol(df))
println("\nVariables:")
for col in names(df)
    println(col)
end

# Print some basic statistics
println("\nBasic Statistics:")
println("================")
println("Initial GDP: ", df[1, :FLOW_PRODUCTION_GOOD] * df[1, :PRICE_GOOD])
println("Final GDP: ", df[end, :FLOW_PRODUCTION_GOOD] * df[end, :PRICE_GOOD])
println("Average Consumption: ", mean(df[!, :FLOW_CONSUMPTION_TOTAL]))
println("Average Investment: ", mean(df[!, :FLOW_INVESTMENT_TOTAL]))
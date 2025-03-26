using MES
using Dates
using Plots

# Create and run simulation
sim = @economic_simulation DateTime(2020, 1, 1) 12
results = run_simulation(sim)

# Plot results
p = plot_results(results)
display(p)

# Print some statistics
println("\nSimulation Results:")
println("==================")
println("Initial GDP: ", results[1].values["gdp"])
println("Final GDP: ", results[end].values["gdp"])
println("GDP Growth: ", (results[end].values["gdp"] - results[1].values["gdp"]) / results[1].values["gdp"] * 100, "%")
println("\nInitial Inflation: ", results[1].values["inflation"], "%")
println("Final Inflation: ", results[end].values["inflation"], "%")
println("Inflation Change: ", results[end].values["inflation"] - results[1].values["inflation"], "%")

# Print colimit values
println("\nColimit Values:")
println("==============")
for (key, value) in results[end].values
    if startswith(key, "colimit_")
        println(key, ": ", value)
    end
end
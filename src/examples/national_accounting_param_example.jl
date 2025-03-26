using MES
using Dates
using Plots
using Statistics

# Create economic parameters
params = EconomicParameters(
    1000, 100, 10,  # n_households, n_firms, n_banks
    1000.0, 2.0, 1.0, 50.0, 20.0,  # initial values
    0.8, 0.2, 0.2, 0.5,  # behavioral parameters
    0.02, 0.01, 2.0, 0.5  # stochastic parameters
)

# Generate data
data = generate_economic_data(params, 12)

# Extract time series
times = 1:12
gdp = [step["gdp"] for step in data]
inflation = [step["inflation"] for step in data]
interest_rate = [step["interest_rate"] for step in data]
consumption = [step["total_consumption"] for step in data]
investment = [step["total_investment"] for step in data]
savings = [step["total_savings"] for step in data]

# Create plots
p1 = plot(times, [gdp consumption investment],
    label=["GDP" "Consumption" "Investment"],
    title="Economic Activity",
    xlabel="Time",
    ylabel="Value"
)

p2 = plot(times, [inflation interest_rate],
    label=["Inflation (%)" "Interest Rate (%)"],
    title="Monetary Indicators",
    xlabel="Time",
    ylabel="Percentage"
)

# Display plots
display(plot(p1, p2, layout=(2, 1)))

# Print statistics
println("\nSimulation Results:")
println("==================")
println("Initial GDP: ", gdp[1])
println("Final GDP: ", gdp[end])
println("GDP Growth: ", (gdp[end] - gdp[1]) / gdp[1] * 100, "%")
println("\nInitial Inflation: ", inflation[1], "%")
println("Final Inflation: ", inflation[end], "%")
println("Inflation Change: ", inflation[end] - inflation[1], "%")
println("\nInitial Interest Rate: ", interest_rate[1], "%")
println("Final Interest Rate: ", interest_rate[end], "%")
println("Interest Rate Change: ", interest_rate[end] - interest_rate[1], "%")

# Print correlations
println("\nCorrelations:")
println("=============")
println("GDP-Inflation: ", cor(gdp, inflation))
println("GDP-Interest Rate: ", cor(gdp, interest_rate))
println("Consumption-Investment: ", cor(consumption, investment))
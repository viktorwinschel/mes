using DataFrames, Statistics

"""
Vergleicht die Ergebnisse der originalen und kategorischen Simulation
"""
function compare_simulations(original_sim::DataFrame, categorical_results::Dict)
    # 1. Vergleiche Kontostände
    balance_diff = Dict{String,Float64}()

    # Bank Konten
    balance_diff["Bank"] = abs(
        sum(original_sim[end, [:AccLabBank, :AccResBank, :AccComBank, :AccCapBank]]) -
        categorical_results["macro_balance"][end]
    )

    # 2. Vergleiche Invarianzen
    invariance_diff = abs(
        original_sim[end, :InvMacro] -
        (categorical_results["micro_balance"][end] - categorical_results["macro_balance"][end])
    )

    # 3. Vergleiche Flüsse
    flow_preservation = mean(categorical_results["functor_preservation"])

    return Dict(
        "balance_differences" => balance_diff,
        "invariance_difference" => invariance_diff,
        "flow_preservation" => flow_preservation,
        "is_equivalent" => all(v < 1e-10 for v in values(balance_diff)) &&
                           invariance_diff < 1e-10 &&
                           flow_preservation ≈ 1.0
    )
end

# Lade die Simulationsdaten
original_data = CSV.read("simulation_data/data_full.csv", DataFrame)
categorical_data = CSV.read("simulation_data/categorical_data_full.csv", DataFrame)

# Führe Vergleich durch
comparison = compare_simulations(original_data, categorical_results)

# Visualisiere Vergleich
using Plots

function plot_comparison(original::DataFrame, categorical::Dict)
    p1 = plot(0:nrow(original)-1,
        [original.InvMacro categorical_results["macro_balance"]],
        label=["Original Invarianz" "Kategorische Balance"],
        title="Invarianzen vs. Kategorische Balance")

    p2 = plot(0:nrow(original)-1,
        abs.(original.InvMacro - categorical_results["macro_balance"]),
        label="Differenz",
        title="Abweichung zwischen Simulationen")

    plot(p1, p2, layout=(2, 1), size=(800, 600))
    savefig("simulation_data/comparison.png")
end

plot_comparison(original_data, categorical_results)
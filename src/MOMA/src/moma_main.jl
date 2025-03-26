using Dates
using DataFrames
using Plots

# Main function to run the simulation
function main()
    # Create simulation landscape
    println("Creating MOMA simulation landscape...")
    landscape = create_moma_simulation()

    # Run simulation
    println("\nRunning simulation...")
    landscape = run_simulation!(landscape)

    # Generate and display results
    println("\nGenerating results...")
    print_summary_report(landscape)

    # Create visualizations
    println("\nGenerating visualizations...")

    # Plot balance sheet evolution for each agent
    for agent_name in keys(landscape.agents)
        p = plot_balance_sheet_evolution(landscape, agent_name)
        savefig(p, "balance_sheet_$(lowercase(agent_name)).png")
    end

    # Plot transaction flow
    p = plot_transaction_flow(landscape)
    savefig(p, "transaction_flow.png")

    println("\nSimulation complete! Results have been saved to files.")
end

# Run the simulation
main()
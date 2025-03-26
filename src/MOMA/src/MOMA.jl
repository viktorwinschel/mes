module MOMA

using Dates
using DataFrames
using Plots

# Include all necessary modules
include("moma_simulation.jl")
include("moma_events.jl")
include("moma_visualization.jl")
include("moma_main.jl")

# Export all public functions and types
export MOMALandscape,
    Agent,
    Account,
    create_moma_simulation,
    process_event!,
    update_account!,
    record_transaction!,
    run_simulation!,
    generate_balance_sheet,
    plot_balance_sheet_evolution,
    plot_transaction_flow,
    generate_summary_stats,
    generate_final_balance_sheets,
    print_summary_report,
    main

# Precompile the most commonly used functions
Base.precompile(Tuple{typeof(create_moma_simulation)})
Base.precompile(Tuple{typeof(process_event!),MOMALandscape,Dict{String,Any}})
Base.precompile(Tuple{typeof(update_account!),Account,Float64,String,Date})
Base.precompile(Tuple{typeof(record_transaction!),MOMALandscape,Date,String,String,Float64,Float64})
Base.precompile(Tuple{typeof(run_simulation!),MOMALandscape})
Base.precompile(Tuple{typeof(generate_balance_sheet),MOMALandscape,String})
Base.precompile(Tuple{typeof(generate_summary_stats),MOMALandscape})

end
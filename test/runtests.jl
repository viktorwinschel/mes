using Test
using DataFrames
using Dates
using Plots

# Include the source files directly
include("../src/moma_simulation.jl")
include("../src/moma_events.jl")
include("../src/moma_visualization.jl")
include("../src/moma_main.jl")

@testset "MOMA.jl" begin
    # Test simulation initialization
    @testset "Simulation Initialization" begin
        landscape = create_moma_simulation()

        # Test parameters
        @test landscape.parameters["initial_money"] == 1000.0
        @test landscape.parameters["loan_amount"] == 200.0
        @test landscape.parameters["bicycle_price"] == 100.0
        @test landscape.parameters["interest_rate"] == 0.05
        @test landscape.parameters["start_date"] == Date("2025-01-15")

        # Test agents
        @test length(landscape.agents) == 5
        @test haskey(landscape.agents, "CB")
        @test haskey(landscape.agents, "Banks")
        @test haskey(landscape.agents, "Bankb")
        @test haskey(landscape.agents, "S")
        @test haskey(landscape.agents, "B")

        # Test events
        @test length(landscape.events) == 8
        @test landscape.results isa DataFrame
    end

    # Test account operations
    @testset "Account Operations" begin
        landscape = create_moma_simulation()

        # Test account creation
        cb_accounts = landscape.agents["CB"].accounts
        @test haskey(cb_accounts, "Paper Money")
        @test haskey(cb_accounts, "Paper Money in Circulation")

        # Test account balance updates
        account = cb_accounts["Paper Money"]
        update_account!(account, 100.0, "debit")
        @test account.balance == 100.0
        update_account!(account, 50.0, "credit")
        @test account.balance == 50.0

        # Test transaction recording
        @test length(account.transactions) == 2
        @test account.transactions[1]["amount"] == 100.0
        @test account.transactions[2]["amount"] == 50.0
    end

    # Test event processing
    @testset "Event Processing" begin
        landscape = create_moma_simulation()

        # Test money creation event
        money_event = landscape.events[1]
        process_event!(landscape, money_event)

        cb_accounts = landscape.agents["CB"].accounts
        @test cb_accounts["Paper Money"].balance == 1000.0
        @test cb_accounts["Paper Money in Circulation"].balance == -1000.0

        # Test loan event
        loan_event = landscape.events[2]
        process_event!(landscape, loan_event)

        @test cb_accounts["Loans to Banks"].balance == 200.0
        @test cb_accounts["Loans to Bankb"].balance == 200.0
        @test cb_accounts["Paper Money"].balance == -400.0
    end

    # Test balance sheet generation
    @testset "Balance Sheet Generation" begin
        landscape = create_moma_simulation()

        # Process some events
        for event in landscape.events[1:2]
            process_event!(landscape, event)
        end

        # Generate balance sheet for CB
        cb_sheet = generate_balance_sheet(landscape, "CB")

        @test cb_sheet["total_assets"] == 1400.0  # Paper Money + Loans
        @test cb_sheet["total_liabilities"] == 1000.0  # Paper Money in Circulation
        @test cb_sheet["net_worth"] == 400.0
    end

    # Test visualization functions
    @testset "Visualization Functions" begin
        landscape = create_moma_simulation()

        # Process events
        for event in landscape.events[1:2]
            process_event!(landscape, event)
        end

        # Test balance sheet evolution plot
        p = plot_balance_sheet_evolution(landscape, "CB")
        @test p isa Plots.Plot

        # Test transaction flow plot
        p = plot_transaction_flow(landscape)
        @test p isa Plots.Plot

        # Test summary statistics
        stats = generate_summary_stats(landscape)
        @test stats["total_transactions"] > 0
        @test stats["total_amount"] > 0
        @test nrow(stats["agent_stats"]) == 5
        @test nrow(stats["account_stats"]) > 0
    end

    # Test full simulation
    @testset "Full Simulation" begin
        landscape = create_moma_simulation()
        landscape = run_simulation!(landscape)

        # Test final results
        @test nrow(landscape.results) > 0
        @test all(landscape.results.date .>= landscape.parameters["start_date"])

        # Test final balance sheets
        final_sheets = generate_final_balance_sheets(landscape)
        @test length(final_sheets) == 5

        # Test that all balance sheets balance
        for (agent, sheet) in final_sheets
            @test abs(sheet["total_assets"] - sheet["total_liabilities"]) ≈ sheet["net_worth"] atol = 1e-10
        end
    end
end
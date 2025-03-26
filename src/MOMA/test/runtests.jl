using Test
using DataFrames
using Dates
using Plots

# Create the main module
module MOMA
include("../src/moma_category.jl")
include("../src/moma_simulation.jl")
include("../src/moma_events.jl")
include("../src/moma_visualization.jl")
end

# Import all submodules
using .MOMA.MOMACategory
using .MOMA.MOMASimulation
using .MOMA.MOMAEvents: process_event!, update_account!, record_transaction!,
    check_micro_invariance, check_macro_invariance, check_boe_macro_invariance,
    run_simulation!, generate_balance_sheet
using .MOMA.MOMAVisualization

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
        @test length(landscape.events) == 7
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
        update_account!(account, 100.0, "debit", landscape.parameters["start_date"])
        @test account.balance == 100.0
        update_account!(account, 50.0, "credit", landscape.parameters["start_date"])
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
        @test cb_accounts["Paper Money in Circulation"].balance == 1000.0

        # Test loan event
        loan_event = landscape.events[2]
        process_event!(landscape, loan_event)

        @test cb_accounts["Loans to Banks"].balance == 200.0
        @test cb_accounts["Loans to Bankb"].balance == 200.0
        @test cb_accounts["Paper Money"].balance == 600.0
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

# Run all test files
@testset "MOMA Tests" begin
    # Core categorical tests
    include("test_category.jl")

    # Documentation examples
    include("test_documentation.jl")

    # Financial event tests
    include("test_events.jl")

    # Functor and natural transformation tests
    include("test_functors.jl")

    # Macro accounting tests
    include("test_macro_accounting.jl")
end

@testset "BOE Macro Accounting" begin
    # Create a test landscape
    landscape = create_test_landscape()

    # Test BOE creation
    boe_event = Dict(
        "type" => "boe_creation",
        "date" => Date(2024, 1, 1),
        "agent" => "S",
        "accounts" => ["Receivable from BOE", "Liability from BOE"],
        "amount" => 100.0
    )

    # Process BOE creation
    process_event!(landscape, boe_event)

    # Test micro invariance for both agents
    @test check_micro_invariance(landscape.agents["S"])
    @test check_micro_invariance(landscape.agents["B"])

    # Test BOE macro invariance after creation
    @test check_boe_macro_invariance(landscape)

    # Test that S's receivable equals B's liability
    s_receivable = landscape.agents["S"].accounts["Receivable from BOE"].debit -
                   landscape.agents["S"].accounts["Receivable from BOE"].credit
    b_liability = landscape.agents["B"].accounts["Liability from BOE"].credit -
                  landscape.agents["B"].accounts["Liability from BOE"].debit
    @test isapprox(s_receivable, b_liability)

    # Test BOE bank transfer
    transfer_event = Dict(
        "type" => "boe_bank_transfer",
        "date" => Date(2024, 1, 2),
        "agent" => "Banks",
        "accounts" => ["Receivable from BOE", "Deposits from S"],
        "amount" => 100.0
    )

    # Process bank transfer
    process_event!(landscape, transfer_event)

    # Test micro invariance for affected agents
    @test check_micro_invariance(landscape.agents["Banks"])
    @test check_micro_invariance(landscape.agents["S"])

    # Test BOE macro invariance after transfer
    @test check_boe_macro_invariance(landscape)

    # Test that bank's BOE claim equals original amount
    bank_boe = landscape.agents["Banks"].accounts["Receivable from BOE"].debit -
               landscape.agents["Banks"].accounts["Receivable from BOE"].credit
    @test isapprox(bank_boe, 100.0)

    # Test that S's deposit equals original BOE amount
    s_deposit = landscape.agents["S"].accounts["Deposits at Banks"].debit -
                landscape.agents["S"].accounts["Deposits at Banks"].credit
    @test isapprox(s_deposit, 100.0)
end
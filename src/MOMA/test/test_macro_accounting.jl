using Test
using Dates

# Include necessary source files
include("../src/moma_simulation.jl")

@testset "Macro Accounting Relationships" begin
    """
    Test macro accounting relationships where:
    1. Every debt has exactly one debtor and one creditor
    2. Claims between agents must net to zero
    3. Internal accounts don't affect macro relationships
    """

    @testset "Money Creation - No Net Debt" begin
        landscape = create_test_landscape()

        # Money creation event (1000.0)
        money_event = Dict(
            "type" => "money_creation",
            "date" => Date(2024, 1, 1),
            "agent" => "CB",
            "accounts" => ["Paper Money", "Paper Money in Circulation"],
            "amount" => 1000.0
        )

        process_event!(landscape, money_event)

        # Test micro invariance for CB
        @test check_micro_invariance(landscape.agents["CB"])

        # At macro level, Paper Money doesn't create net debt
        total_money = landscape.agents["CB"].accounts["Paper Money"].debit -
                      landscape.agents["CB"].accounts["Paper Money"].credit
        total_circulation = landscape.agents["CB"].accounts["Paper Money in Circulation"].credit -
                            landscape.agents["CB"].accounts["Paper Money in Circulation"].debit
        @test isapprox(total_money, total_circulation)
    end

    @testset "Loan Relationships - Debtor-Creditor Pairs" begin
        landscape = create_test_landscape()

        # Loan event (200.0 to each bank)
        loan_event = Dict(
            "type" => "loans",
            "date" => Date(2024, 1, 1),
            "agent" => "CB",
            "accounts" => ["Loans to Banks", "Deposits from Banks"],
            "amount" => 200.0
        )

        process_event!(landscape, loan_event)

        # Test that CB's claim equals Banks' liability
        cb_claim_banks = landscape.agents["CB"].accounts["Loans to Banks"].debit -
                         landscape.agents["CB"].accounts["Loans to Banks"].credit
        banks_liability = landscape.agents["Banks"].accounts["Loans from CB"].credit -
                          landscape.agents["Banks"].accounts["Loans from CB"].debit
        @test isapprox(cb_claim_banks, banks_liability)

        # Test that CB's claim equals Bankb's liability
        cb_claim_bankb = landscape.agents["CB"].accounts["Loans to Bankb"].debit -
                         landscape.agents["CB"].accounts["Loans to Bankb"].credit
        bankb_liability = landscape.agents["Bankb"].accounts["Loans from CB"].credit -
                          landscape.agents["Bankb"].accounts["Loans from CB"].debit
        @test isapprox(cb_claim_bankb, bankb_liability)
    end

    @testset "BOE Chain - Claim Transfer Without Net Change" begin
        landscape = create_test_landscape()

        # Initial BOE creation
        boe_event = Dict(
            "type" => "boe_creation",
            "date" => Date(2024, 1, 1),
            "agent" => "S",
            "accounts" => ["Receivable from BOE", "Liability from BOE"],
            "amount" => 100.0
        )

        process_event!(landscape, boe_event)

        # Initial state: S's claim equals B's liability
        s_claim = landscape.agents["S"].accounts["Receivable from BOE"].debit -
                  landscape.agents["S"].accounts["Receivable from BOE"].credit
        b_liability = landscape.agents["B"].accounts["Liability from BOE"].credit -
                      landscape.agents["B"].accounts["Liability from BOE"].debit
        @test isapprox(s_claim, b_liability)

        # Transfer to Banks
        transfer_event = Dict(
            "type" => "boe_bank_transfer",
            "date" => Date(2024, 1, 2),
            "agent" => "Banks",
            "accounts" => ["Receivable from BOE", "Deposits from S"],
            "amount" => 100.0
        )

        process_event!(landscape, transfer_event)

        # After transfer: Banks' claim equals original amount
        # S now has deposit instead of BOE claim
        banks_claim = landscape.agents["Banks"].accounts["Receivable from BOE"].debit -
                      landscape.agents["Banks"].accounts["Receivable from BOE"].credit
        s_deposit = landscape.agents["S"].accounts["Deposits at Banks"].debit -
                    landscape.agents["S"].accounts["Deposits at Banks"].credit
        @test isapprox(banks_claim, s_deposit)

        # Total claims in system remain unchanged
        @test isapprox(banks_claim, b_liability)
    end

    @testset "Settlement - Debt Cancellation" begin
        landscape = create_test_landscape()

        # Setup interbank position
        transfer_event = Dict(
            "type" => "boe_bank_transfer",
            "date" => Date(2024, 1, 1),
            "agent" => "Bankb",
            "accounts" => ["Receivable from BOE", "Deposits from Banks"],
            "amount" => 100.0
        )

        process_event!(landscape, transfer_event)

        # Initial interbank position
        banks_claim = landscape.agents["Banks"].accounts["Deposits at Bankb"].debit -
                      landscape.agents["Banks"].accounts["Deposits at Bankb"].credit
        bankb_liability = landscape.agents["Bankb"].accounts["Deposits from Banks"].credit -
                          landscape.agents["Bankb"].accounts["Deposits from Banks"].debit
        @test isapprox(banks_claim, bankb_liability)

        # Settlement
        settlement_event = Dict(
            "type" => "settlement",
            "date" => Date(2024, 1, 2),
            "agent" => "Banks",
            "accounts" => ["Deposits at Bankb", "CB Reserve"],
            "amount" => 100.0
        )

        process_event!(landscape, settlement_event)

        # After settlement: Positions are cleared through CB reserves
        banks_reserve_change = landscape.agents["Banks"].accounts["CB Reserve"].credit -
                               landscape.agents["Banks"].accounts["CB Reserve"].debit
        bankb_reserve_change = landscape.agents["Bankb"].accounts["CB Reserve"].debit -
                               landscape.agents["Bankb"].accounts["CB Reserve"].credit
        @test isapprox(banks_reserve_change, bankb_reserve_change)
    end
end
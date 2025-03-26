using Test
include("../src/MOMA.jl")

"""
Test suite for BOE Bicycle Example demonstrating categorical constructions:

1. Micro Balance (Pullbacks):
   - Each account must balance internally
   - Bicycle Dealer's accounts
   - Customer's accounts
   - Bank's BOE accounts

2. Macro Balance (Pushouts):
   - Agents must be imbalanced together
   - BOE relationships between parties
   - Trade relationships
"""

@testset "BOE Bicycle Example" begin
    # Setup initial landscape
    landscape = MOMALandscape()

    # Add agents
    add_agent!(landscape, "BikeDealer")
    add_agent!(landscape, "Customer")
    add_agent!(landscape, "Bank")

    # Add accounts
    # Bike Dealer
    add_account!(landscape.agents["BikeDealer"], "Inventory")
    add_account!(landscape.agents["BikeDealer"], "BOE Receivable")
    add_account!(landscape.agents["BikeDealer"], "Cash")

    # Customer
    add_account!(landscape.agents["Customer"], "BOE Liability")
    add_account!(landscape.agents["Customer"], "Bicycle Asset")

    # Bank
    add_account!(landscape.agents["Bank"], "BOE Receivable")
    add_account!(landscape.agents["Bank"], "BOE Liability")
    add_account!(landscape.agents["Bank"], "Reserves")

    @testset "1. Initial Bicycle Sale with BOE" begin
        # Record sale: Bicycle (100) sold to Customer, paid with BOE
        event = Dict(
            "type" => "trade",
            "from" => "BikeDealer",
            "to" => "Customer",
            "amount" => 100.0,
            "date" => Date(2024, 1, 1)
        )

        # Process trade
        process_trade!(landscape, event)

        # Test Pullbacks (Micro Balance)
        @test verify_micro_pullback(landscape.agents["BikeDealer"].accounts["Inventory"])
        @test verify_micro_pullback(landscape.agents["Customer"].accounts["Bicycle Asset"])

        # Test Pushout (Macro Balance)
        @test verify_macro_pushout(landscape, "Inventory ↔ Bicycle Asset")

        # Create BOE
        boe_event = Dict(
            "type" => "create_boe",
            "from" => "Customer",
            "to" => "BikeDealer",
            "amount" => 100.0,
            "date" => Date(2024, 1, 1)
        )

        process_boe_event!(landscape, boe_event)

        # Test BOE Pullbacks
        @test verify_micro_pullback(landscape.agents["Customer"].accounts["BOE Liability"])
        @test verify_micro_pullback(landscape.agents["BikeDealer"].accounts["BOE Receivable"])

        # Test BOE Pushout
        @test verify_macro_pushout(landscape, "BOE Receivable ↔ BOE Liability")
    end

    @testset "2. BOE Discounting at Bank" begin
        # Dealer discounts BOE at Bank
        discount_event = Dict(
            "type" => "transfer_boe",
            "from" => "BikeDealer",
            "to" => "Bank",
            "amount" => 95.0,  # 5% discount
            "date" => Date(2024, 1, 2)
        )

        process_boe_event!(landscape, discount_event)

        # Test New Pullbacks
        @test verify_micro_pullback(landscape.agents["Bank"].accounts["BOE Receivable"])
        @test verify_micro_pullback(landscape.agents["Bank"].accounts["BOE Liability"])

        # Test New Pushout
        @test verify_macro_pushout(landscape, "BOE Receivable ↔ BOE Liability")

        # Test Money Creation
        @test detect_money_emergence(landscape)["Bills of Exchange"][1].amount == 95.0
    end

    @testset "3. BOE Settlement" begin
        # Customer settles BOE at maturity
        settle_event = Dict(
            "type" => "settle_boe",
            "from" => "Customer",
            "to" => "Bank",
            "amount" => 100.0,
            "date" => Date(2024, 3, 1)
        )

        process_boe_event!(landscape, settle_event)

        # Test Final Pullbacks
        @test verify_micro_pullback(landscape.agents["Customer"].accounts["BOE Liability"])
        @test verify_micro_pullback(landscape.agents["Bank"].accounts["BOE Receivable"])

        # Test Pushout Resolution
        @test !verify_macro_pushout(landscape, "BOE Receivable ↔ BOE Liability")

        # Test Money Destruction
        @test isempty(detect_money_emergence(landscape)["Bills of Exchange"])
    end

    @testset "4. Complete Categorical Structure" begin
        # Generate complete balance diagram
        diagram = generate_balance_diagram(landscape)

        # Test structure
        @test haskey(diagram, "pullbacks")
        @test haskey(diagram, "pushouts")

        # Test specific structures
        @test haskey(diagram["pullbacks"], "BikeDealer:Inventory")
        @test haskey(diagram["pullbacks"], "Customer:Bicycle Asset")
        @test haskey(diagram["pushouts"], "BOE Receivable ↔ BOE Liability")

        # Test final state
        @test check_categorical_balance(landscape)
    end
end
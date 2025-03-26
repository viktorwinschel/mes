@testset "Financial Events" begin
    date = Date("2025-01-15")

    @testset "Money Creation" begin
        amount = 1000.0
        diagram = create_money_creation_diagram(amount, date)

        # Test structure
        @test length(diagram.objects) == 3
        @test length(diagram.morphisms) == 2
        @test diagram.event_type == "MoneyCreation"

        # Test flow consistency
        @test diagram.morphisms[1].amount == amount
        @test diagram.morphisms[2].amount == amount
        @test is_commutative(diagram)
    end

    @testset "Loans" begin
        amount = 500.0
        diagram = create_loans_diagram(amount, date)

        # Test structure
        @test length(diagram.objects) == 3
        @test length(diagram.morphisms) == 2
        @test diagram.event_type == "Loans"

        # Test flow consistency
        @test all(m -> m.amount == amount, diagram.morphisms)
        @test is_commutative(diagram)
    end

    @testset "Bicycle Purchase" begin
        amount = 200.0
        diagram = create_bicycle_purchase_diagram(amount, date)

        # Test structure
        @test length(diagram.objects) == 2
        @test length(diagram.morphisms) == 1
        @test diagram.event_type == "BicyclePurchase"

        # Test flow
        @test diagram.morphisms[1].amount == amount
    end

    @testset "BOE Operations" begin
        amount = 300.0

        # Test BOE Creation
        creation = create_boe_creation_diagram(amount, date)
        @test creation.event_type == "BOECreation"
        @test length(creation.morphisms) == 1
        @test creation.morphisms[1].amount == amount

        # Test BOE Transfer
        transfer = create_boe_transfer_diagram(amount, date)
        @test transfer.event_type == "BOETransfer"
        @test length(transfer.morphisms) == 1
        @test transfer.morphisms[1].amount == amount
    end

    @testset "Settlement" begin
        amount = 400.0
        diagram = create_settlement_diagram(amount, date)

        # Test structure
        @test length(diagram.objects) == 4
        @test length(diagram.morphisms) == 3
        @test diagram.event_type == "Settlement"

        # Test flow consistency
        @test all(m -> m.amount == amount, diagram.morphisms)
        @test is_commutative(diagram)
    end

    @testset "Full Event Sequence" begin
        initial_money = 1000.0
        loan_amount = 200.0
        bicycle_price = 100.0
        start_date = date

        events = create_full_event_sequence(
            initial_money,
            loan_amount,
            bicycle_price,
            start_date
        )

        # Test sequence structure
        @test length(events) == 6

        # Test event types in sequence
        event_types = [e.event_type for e in events]
        @test event_types == [
            "MoneyCreation",
            "Loans",
            "BicyclePurchase",
            "BOECreation",
            "BOETransfer",
            "Settlement"
        ]

        # Test dates are sequential
        for i in 1:length(events)-1
            @test events[i+1].event_date == events[i].event_date + Day(1)
        end

        # Test all diagrams are valid
        for event in events
            @test is_commutative(event)
            @test verify_universal_property(create_colimit(event))
        end
    end
end
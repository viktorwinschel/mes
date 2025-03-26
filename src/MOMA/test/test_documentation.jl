using Test
using Dates
include("../src/moma_category.jl")

@testset "Documentation Examples" begin
    @testset "Basic Example" begin
        # Test the basic example from the documentation
        date = Date("2025-01-15")
        diagram = create_money_creation_diagram(1000.0, date)

        # Create functor to macro level
        F = create_micro_macro_functor(diagram)

        # Verify categorical properties
        @test is_commutative(diagram)
        @test verify_universal_property(create_colimit(diagram))
    end

    @testset "Full Event Sequence" begin
        # Test creating and analyzing a full sequence of events
        start_date = Date("2025-01-15")
        initial_money = 1000.0
        loan_amount = 200.0
        bicycle_price = 100.0

        events = create_full_event_sequence(
            initial_money,
            loan_amount,
            bicycle_price,
            start_date
        )

        # Verify each event in the sequence
        for event in events
            @test is_commutative(event)
            colimit = create_colimit(event)
            @test verify_universal_property(colimit)
        end
    end

    @testset "Categorical Properties" begin
        # Test composition properties
        date = Date("2025-01-15")

        # Create objects
        cb_paper = create_account_object("CB", "PaperMoney", Asset())
        cb_circulation = create_account_object("CB", "PaperMoneyCirculation", Liability())
        banks_deposit = create_account_object("Banks", "Deposit", Liability())

        # Create morphisms
        m1 = create_morphism(cb_paper, cb_circulation, 1000.0, date)
        m2 = create_morphism(cb_circulation, banks_deposit, 1000.0, date)

        # Test composition
        composed = compose_morphisms(m1, m2)
        @test composed.source == cb_paper
        @test composed.target == banks_deposit
        @test composed.amount == 1000.0

        # Test identity morphism
        id_morph = create_morphism(cb_paper, cb_paper, 0.0, date)
        @test id_morph.source == id_morph.target

        # Test composition with identity
        comp_with_id = compose_morphisms(id_morph, m1)
        @test comp_with_id.amount == m1.amount
        @test comp_with_id.source == m1.source
        @test comp_with_id.target == m1.target
    end
end
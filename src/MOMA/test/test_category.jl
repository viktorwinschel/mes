using Test
using Dates
include("../src/moma_category.jl")

@testset "Categorical Accounting Tests" begin
    @testset "Basic Structures" begin
        # Test account object creation
        cb_paper = create_account_object("CB", "PaperMoney", Asset())
        @test cb_paper.agent == "CB"
        @test cb_paper.account == "PaperMoney"
        @test cb_paper.acc_type isa Asset

        # Test morphism creation
        date = Date("2025-01-15")
        cb_circulation = create_account_object("CB", "PaperMoneyCirculation", Liability())
        morph = create_morphism(cb_paper, cb_circulation, 1000.0, date)
        @test morph.source == cb_paper
        @test morph.target == cb_circulation
        @test morph.amount == 1000.0
        @test morph.date == date
    end

    @testset "Money Creation Diagram" begin
        date = Date("2025-01-15")
        diagram = create_money_creation_diagram(1000.0, date)

        # Test diagram structure
        @test length(diagram.objects) == 3
        @test length(diagram.morphisms) == 2
        @test diagram.event_type == "MoneyCreation"
        @test diagram.event_date == date

        # Test composition
        composed = compose_morphisms(diagram.morphisms[1], diagram.morphisms[2])
        @test composed.source == diagram.morphisms[1].source
        @test composed.target == diagram.morphisms[2].target
        @test composed.amount == 1000.0
    end

    @testset "Loans Diagram" begin
        date = Date("2025-01-16")
        diagram = create_loans_diagram(200.0, date)

        # Test diagram structure
        @test length(diagram.objects) == 3
        @test length(diagram.morphisms) == 2
        @test diagram.event_type == "Loans"
        @test diagram.event_date == date

        # Test commutativity
        @test is_commutative(diagram)
    end

    @testset "Colimit Construction" begin
        date = Date("2025-01-15")
        diagram = create_money_creation_diagram(1000.0, date)
        colimit = create_colimit(diagram)

        # Test colimit structure
        @test colimit.colimit_object.agent == "System"
        @test colimit.colimit_object.account == "Balance"
        @test length(colimit.universal_morphisms) == length(diagram.objects)

        # Test universal property
        @test verify_universal_property(colimit)
    end

    @testset "All Event Diagrams" begin
        date = Date("2025-01-15")

        # Test Bicycle Purchase
        bicycle_diagram = create_bicycle_purchase_diagram(100.0, date)
        @test length(bicycle_diagram.objects) == 2
        @test length(bicycle_diagram.morphisms) == 1
        @test bicycle_diagram.event_type == "BicyclePurchase"

        # Test BOE Creation
        boe_diagram = create_boe_creation_diagram(100.0, date)
        @test length(boe_diagram.objects) == 2
        @test length(boe_diagram.morphisms) == 1
        @test boe_diagram.event_type == "BOECreation"

        # Test BOE Transfer
        transfer_diagram = create_boe_transfer_diagram(100.0, date)
        @test length(transfer_diagram.objects) == 2
        @test length(transfer_diagram.morphisms) == 1
        @test transfer_diagram.event_type == "BOETransfer"

        # Test Settlement
        settlement_diagram = create_settlement_diagram(100.0, date)
        @test length(settlement_diagram.objects) == 4
        @test length(settlement_diagram.morphisms) == 3
        @test settlement_diagram.event_type == "Settlement"
    end

    @testset "Full Event Sequence" begin
        start_date = Date("2025-01-15")
        events = create_full_event_sequence(1000.0, 200.0, 100.0, start_date)

        # Test sequence length and dates
        @test length(events) == 6
        @test events[1].event_date == start_date
        @test events[end].event_date == start_date + Day(5)

        # Test event types
        @test events[1].event_type == "MoneyCreation"
        @test events[2].event_type == "Loans"
        @test events[3].event_type == "BicyclePurchase"
        @test events[4].event_type == "BOECreation"
        @test events[5].event_type == "BOETransfer"
        @test events[6].event_type == "Settlement"

        # Test all diagrams commute
        @test all(e -> is_commutative(e), events)
    end

    @testset "Functors and Natural Transformations" begin
        date = Date("2025-01-15")
        diagram = create_money_creation_diagram(1000.0, date)

        # Test functor creation
        F = create_micro_macro_functor(diagram)
        @test F.source_category == "Micro"
        @test F.target_category == "Macro"
        @test length(F.object_map) == length(diagram.objects)
        @test length(F.morphism_map) == length(diagram.morphisms)

        # Test functor preserves structure
        for morph in diagram.morphisms
            macro_morph = F.morphism_map[morph]
            @test macro_morph.amount == morph.amount
            @test macro_morph.date == morph.date
        end

        # Test natural transformation
        G = create_micro_macro_functor(diagram)  # Another functor
        nat_trans = create_natural_transformation(F, G, diagram)
        @test length(nat_trans.components) == length(diagram.objects)

        # Test naturality condition
        for obj in diagram.objects
            @test haskey(nat_trans.components, obj)
            @test nat_trans.components[obj].amount == 0.0  # Identity morphism
        end
    end

    @testset "Category Theory Properties" begin
        date = Date("2025-01-15")

        # Test identity morphisms
        obj = create_account_object("CB", "PaperMoney", Asset())
        id_morph = create_morphism(obj, obj, 0.0, date)
        @test id_morph.source == id_morph.target

        # Test associativity of composition
        diagram = create_settlement_diagram(100.0, date)
        @test length(diagram.morphisms) >= 3  # Need at least 3 morphisms

        # (f ∘ g) ∘ h = f ∘ (g ∘ h)
        f = diagram.morphisms[1]
        g = diagram.morphisms[2]
        h = diagram.morphisms[3]

        comp1 = compose_morphisms(compose_morphisms(f, g), h)
        comp2 = compose_morphisms(f, compose_morphisms(g, h))

        @test comp1.source == comp2.source
        @test comp1.target == comp2.target
        @test comp1.amount == comp2.amount
    end
end

@testset "Category Structure" begin
    # Test object creation
    @testset "Objects" begin
        obj = create_account_object("CB", "PaperMoney", Asset())
        @test obj.agent == "CB"
        @test obj.account == "PaperMoney"
        @test obj.acc_type isa Asset
    end

    # Test morphism creation
    @testset "Morphisms" begin
        source = create_account_object("CB", "PaperMoney", Asset())
        target = create_account_object("CB", "Circulation", Liability())
        date = Date("2025-01-15")
        morph = create_morphism(source, target, 1000.0, date)

        @test morph.source == source
        @test morph.target == target
        @test morph.amount == 1000.0
        @test morph.date == date
    end

    # Test morphism composition
    @testset "Composition" begin
        date = Date("2025-01-15")
        a = create_account_object("CB", "A", Asset())
        b = create_account_object("CB", "B", Asset())
        c = create_account_object("CB", "C", Asset())

        f = create_morphism(a, b, 1000.0, date)
        g = create_morphism(b, c, 2000.0, date)

        # Test regular composition
        comp = compose_morphisms(f, g)
        @test comp.source == a
        @test comp.target == c
        @test comp.amount == 1000.0  # Should preserve first morphism's amount

        # Test composition with identity
        id_b = create_morphism(b, b, 0.0, date)
        comp_with_id = compose_morphisms(f, id_b)
        @test comp_with_id.amount == f.amount
    end

    # Test diagram commutativity
    @testset "Commutativity" begin
        date = Date("2025-01-15")
        diagram = create_money_creation_diagram(1000.0, date)
        @test is_commutative(diagram)

        # Test non-commutative diagram
        cb_paper = create_account_object("CB", "PaperMoney", Asset())
        cb_circ = create_account_object("CB", "Circulation", Liability())
        m1 = create_morphism(cb_paper, cb_circ, 1000.0, date)
        m2 = create_morphism(cb_paper, cb_circ, 2000.0, date)  # Different amount
        non_comm = MacroEventDiagram([cb_paper, cb_circ], [m1, m2], "Test", date)
        @test_throws AssertionError is_commutative(non_comm)
    end
end

@testset "Colimit Properties" begin
    # Test colimit creation
    @testset "Creation" begin
        date = Date("2025-01-15")
        diagram = create_money_creation_diagram(1000.0, date)
        colimit = create_colimit(diagram)

        @test colimit.colimit_object.agent == "System"
        @test colimit.colimit_object.account == "Balance"
        @test length(colimit.universal_morphisms) == length(diagram.objects)
    end

    # Test universal property
    @testset "Universal Property" begin
        date = Date("2025-01-15")

        # Test for money creation
        diagram1 = create_money_creation_diagram(1000.0, date)
        @test verify_universal_property(create_colimit(diagram1))

        # Test for loans
        diagram2 = create_loans_diagram(500.0, date)
        @test verify_universal_property(create_colimit(diagram2))

        # Test for bicycle purchase
        diagram3 = create_bicycle_purchase_diagram(200.0, date)
        @test verify_universal_property(create_colimit(diagram3))
    end
end

@testset "Category Axioms" begin
    # Test associativity: (h ∘ g) ∘ f = h ∘ (g ∘ f)
    @test begin
        cat = create_test_category()
        f = get_morphism(cat, "A", "B")
        g = get_morphism(cat, "B", "C")
        h = get_morphism(cat, "C", "D")
        comp1 = compose_morphisms(compose_morphisms(h, g), f)
        comp2 = compose_morphisms(h, compose_morphisms(g, f))
        comp1 == comp2
    end

    # Test identity: f ∘ id_A = f = id_B ∘ f
    @test begin
        cat = create_test_category()
        f = get_morphism(cat, "A", "B")
        id_A = identity_morphism(cat, "A")
        id_B = identity_morphism(cat, "B")
        comp1 = compose_morphisms(f, id_A)
        comp2 = compose_morphisms(id_B, f)
        (comp1 == f) && (comp2 == f)
    end
end

@testset "Pattern and Colimit Properties" begin
    # Test universal property of colimits
    @test begin
        pattern = create_test_pattern()
        colimit = create_colimit(pattern)
        verify_universal_property(colimit)
    end

    # Test pattern binding
    @test begin
        pattern1 = create_test_pattern()
        pattern2 = create_bound_pattern(pattern1)
        verify_binding_relationship(pattern1, pattern2)
    end

    # Test multiplicity principle
    @test begin
        diagram = create_test_diagram()
        verify_multiplicity_principle(diagram)
    end
end

@testset "Functorial Evolution" begin
    # Test functor properties
    @test begin
        F = create_test_functor()
        verify_functor_properties(F)
    end

    # Test natural transformation properties
    @test begin
        F = create_test_functor()
        G = create_test_functor()
        eta = create_natural_transformation(F, G)
        verify_naturality(eta)
    end
end

@testset "Memory Dynamics" begin
    # Test memory evolution equation: M_{t+1} = F(M_t, P_t)
    @test begin
        memory = create_test_memory()
        procedure = create_test_procedure()
        evolved = evolve_memory!(memory, procedure)
        verify_memory_evolution(memory, evolved)
    end

    # Test hierarchical consistency
    @test begin
        hierarchy = create_test_hierarchy()
        verify_level_consistency(hierarchy)
    end
end

@testset "Fractures and Resynchronization" begin
    # Test fracture detection
    @testset "Fracture Detection" begin
        # Create landscape with intentional imbalance
        landscape = create_test_landscape()

        # Create imbalance by modifying one side of relationship
        banks = landscape.agents["Banks"]
        update_account!(banks.accounts["Deposits at Bankb"], 100.0, "debit", today())

        # Detect fractures
        fractures = detect_fractures(landscape)
        @test !isempty(fractures)
        @test haskey(fractures, "Deposits at Bankb ↔ Deposits from Banks")
        @test fractures["Deposits at Bankb ↔ Deposits from Banks"] ≈ 100.0
    end

    # Test resynchronization
    @testset "Resynchronization" begin
        landscape = create_test_landscape()

        # Create multiple imbalances
        banks = landscape.agents["Banks"]
        bankb = landscape.agents["Bankb"]

        # Imbalance 1: Deposits
        update_account!(banks.accounts["Deposits at Bankb"], 100.0, "debit", today())

        # Imbalance 2: BOE
        update_account!(banks.accounts["Receivable from BOE"], 50.0, "debit", today())

        # Verify fractures exist
        @test !isempty(detect_fractures(landscape))

        # Attempt resynchronization
        @test resynchronize!(landscape)

        # Verify all fractures resolved
        @test isempty(detect_fractures(landscape))
    end

    # Test multiple resolution paths
    @testset "Resolution Paths" begin
        landscape = create_test_landscape()

        # Create test fracture
        fracture = Dict(
            "type" => "deposit_imbalance",
            "amount" => 100.0,
            "accounts" => ("Deposits at Bankb", "Deposits from Banks")
        )

        # Create imbalance
        banks = landscape.agents["Banks"]
        update_account!(banks.accounts["Deposits at Bankb"], 100.0, "debit", today())

        # Verify multiple paths can resolve
        @test verify_resolution_paths(landscape, fracture)
    end
end

@testset "Money Emergence" begin
    # Test deposit money emergence
    @testset "Deposit Money Creation" begin
        landscape = create_test_landscape()

        # Create micro-level entries that should create deposit money
        banks = landscape.agents["Banks"]
        bankb = landscape.agents["Bankb"]

        # Bank A records deposit at Bank B
        update_account!(banks.accounts["Deposits at Bankb"], 100.0, "debit", today())
        # Bank B records deposit from Bank A
        update_account!(bankb.accounts["Deposits from Banks"], 100.0, "credit", today())

        # Detect emergent money
        emergent_money = detect_money_emergence(landscape)

        # Verify deposit money emerged
        @test haskey(emergent_money, "Bank Deposits")
        @test length(emergent_money["Bank Deposits"]) == 1

        # Verify pattern properties
        pattern = emergent_money["Bank Deposits"][1]
        @test pattern.macro_property == "Bank Deposits"
        @test pattern.binding_mechanism == "Deposit Creation"
        @test verify_money_emergence(pattern)
    end

    # Test reserve money emergence
    @testset "Reserve Money Creation" begin
        landscape = create_test_landscape()

        # Create micro-level entries that should create reserve money
        cb = landscape.agents["CB"]
        banks = landscape.agents["Banks"]

        # Add required accounts
        cb.accounts["Bank Reserve Account"] = Account("Bank Reserve Account")
        banks.accounts["CB Reserve"] = Account("CB Reserve")

        # CB credits bank's reserve account
        update_account!(cb.accounts["Bank Reserve Account"], 100.0, "credit", today())
        # Bank records reserve claim
        update_account!(banks.accounts["CB Reserve"], 100.0, "debit", today())

        # Detect emergent money
        emergent_money = detect_money_emergence(landscape)

        # Verify reserve money emerged
        @test haskey(emergent_money, "Central Bank Money")
        @test length(emergent_money["Central Bank Money"]) == 1

        # Verify pattern properties
        pattern = emergent_money["Central Bank Money"][1]
        @test pattern.macro_property == "Central Bank Money"
        @test pattern.binding_mechanism == "Reserve Creation"
        @test verify_money_emergence(pattern)
    end

    # Test BOE emergence
    @testset "Bills of Exchange Creation" begin
        landscape = create_test_landscape()

        # Create micro-level entries that should create BOE
        banks = landscape.agents["Banks"]
        bankb = landscape.agents["Bankb"]

        # Bank A records BOE receivable
        update_account!(banks.accounts["Receivable from BOE"], 100.0, "debit", today())
        # Bank B records BOE liability
        update_account!(bankb.accounts["Liability from BOE"], 100.0, "credit", today())

        # Detect emergent money
        emergent_money = detect_money_emergence(landscape)

        # Verify BOE emerged
        @test haskey(emergent_money, "Bills of Exchange")
        @test length(emergent_money["Bills of Exchange"]) == 1

        # Verify pattern properties
        pattern = emergent_money["Bills of Exchange"][1]
        @test pattern.macro_property == "Bills of Exchange"
        @test pattern.binding_mechanism == "BOE Creation"
        @test verify_money_emergence(pattern)
    end

    # Test money supply calculation
    @testset "Money Supply" begin
        landscape = create_test_landscape()

        # Create various types of money
        # 1. Deposits
        banks = landscape.agents["Banks"]
        bankb = landscape.agents["Bankb"]
        update_account!(banks.accounts["Deposits at Bankb"], 100.0, "debit", today())
        update_account!(bankb.accounts["Deposits from Banks"], 100.0, "credit", today())

        # 2. BOE
        update_account!(banks.accounts["Receivable from BOE"], 50.0, "debit", today())
        update_account!(bankb.accounts["Liability from BOE"], 50.0, "credit", today())

        # Calculate money supply
        money_supply = get_money_supply(landscape)

        # Verify amounts
        @test haskey(money_supply, "Bank Deposits")
        @test money_supply["Bank Deposits"] ≈ 100.0
        @test haskey(money_supply, "Bills of Exchange")
        @test money_supply["Bills of Exchange"] ≈ 50.0
    end
end

# Helper functions for creating test structures

function create_test_category()
    objects = ["A", "B", "C", "D"]
    morphisms = Dict(
        ("A", "B") => ["f"],
        ("B", "C") => ["g"],
        ("C", "D") => ["h"]
    )
    composition = Dict(
        ("A", "B", "C") => true,
        ("B", "C", "D") => true
    )
    Category{String}(objects, morphisms, composition)
end

function create_test_pattern()
    cat = create_test_category()
    objects = ["A", "B"]
    links = [("A", "B")]
    Pattern(cat, objects, links)
end

function create_test_functor()
    source_cat = create_test_category()
    target_cat = create_test_category()
    object_map = Dict("A" => "A'", "B" => "B'")
    morphism_map = Dict("f" => "f'")
    MicroMacroFunctor(object_map, morphism_map)
end

function create_test_memory()
    states = Dict{DateTime,Dict}()
    procedures = Function[]
    MemorySystem(states, procedures)
end

# Helper function to create test landscape
function create_test_landscape()
    # Create agents
    agents = Dict{String,Agent}()

    # CB
    cb = Agent("CB", Dict{String,Account}())
    cb.accounts["Paper Money"] = Account("Paper Money")
    cb.accounts["Paper Money in Circulation"] = Account("Paper Money in Circulation")
    agents["CB"] = cb

    # Banks
    banks = Agent("Banks", Dict{String,Account}())
    banks.accounts["Deposits at Bankb"] = Account("Deposits at Bankb")
    banks.accounts["Receivable from BOE"] = Account("Receivable from BOE")
    agents["Banks"] = banks

    # Bankb
    bankb = Agent("Bankb", Dict{String,Account}())
    bankb.accounts["Deposits from Banks"] = Account("Deposits from Banks")
    bankb.accounts["Liability from BOE"] = Account("Liability from BOE")
    agents["Bankb"] = bankb

    MOMALandscape(agents, [], DataFrame())
end
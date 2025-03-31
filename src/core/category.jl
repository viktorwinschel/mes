using Parameters
using DataFrames

# Basic category definition
abstract type CategoryObject end
abstract type CategoryMorphism end

"""
    Category{Ob<:CategoryObject, Mor<:CategoryMorphism}

Abstract type for categories with objects of type Ob and morphisms of type Mor.
"""
abstract type Category{Ob<:CategoryObject,Mor<:CategoryMorphism} end

"""
    ConcreteCategory{Ob<:CategoryObject,Mor<:CategoryMorphism}

A concrete implementation of Category with objects of type Ob and morphisms of type Mor.
"""
struct ConcreteCategory{Ob<:CategoryObject,Mor<:CategoryMorphism} <: Category{Ob,Mor}
    objects::Vector{Ob}
    morphisms::Vector{Mor}
    composition::Dict{Tuple{Mor,Mor},Mor}  # Composition of morphisms
    identity::Dict{Ob,Mor}                 # Identity morphisms
end

"""
    create_category(objects, morphisms)

Create a category from given objects and morphisms.
"""
function create_category(objects::Vector{Ob}, morphisms::Vector{Mor}) where {Ob<:CategoryObject,Mor<:CategoryMorphism}
    composition = Dict{Tuple{Mor,Mor},Mor}()
    identity = Dict{Ob,Mor}()
    ConcreteCategory{Ob,Mor}(objects, morphisms, composition, identity)
end

"""
    add_morphism!(category, morphism)

Add a morphism to a category.
"""
function add_morphism!(category::Category, morphism::CategoryMorphism)
    push!(category.morphisms, morphism)
end

"""
    compose_morphisms!(category, f, g)

Add a composition rule to the category.
"""
function compose_morphisms!(category::Category, f::CategoryMorphism, g::CategoryMorphism)
    category.composition[(f, g)] = g
end

# Economic objects
struct Agent <: CategoryObject
    name::String
    type::String  # "LABOR", "RESOURCE", "COMPANY", "CAPITAL", "BANK"
    accounts::Vector{String}  # List of account names
end

struct Account <: CategoryObject
    name::String
    agent::String
    type::String  # "BANK", "STOCK", "GOOD", "LOAN", "DIV"
    balance::Float64
end

struct Flow <: CategoryObject
    name::String
    type::String  # "CONSUMPTION", "INVESTMENT", "PAYMENT", "DIVIDEND"
    source::String
    target::String
    value::Float64
end

# Economic morphisms
struct Transaction <: CategoryMorphism
    name::String
    source::CategoryObject
    target::CategoryObject
    amount::Float64
    flow_type::String
end

struct StateTransition <: CategoryMorphism
    name::String
    source::Vector{Account}
    target::Vector{Account}
    flows::Vector{Flow}
    period::Int
end

"""
    FinancialCategory

Category for financial objects and transactions.
"""
struct FinancialCategory <: Category{CategoryObject,CategoryMorphism}
    objects::Vector{CategoryObject}
    morphisms::Vector{CategoryMorphism}
    composition::Dict{Tuple{CategoryMorphism,CategoryMorphism},CategoryMorphism}
    identity::Dict{CategoryObject,CategoryMorphism}
end

"""
    create_financial_category(df::DataFrame, period::Int)

Create a financial category from MoMaSCF data for a specific period.
"""
function create_financial_category(df::DataFrame, period::Int)
    # Create agents
    agents = [
        Agent("LABOR", "LABOR", ["BANK", "STOCK", "GOOD"]),
        Agent("RESOURCE", "RESOURCE", ["BANK", "STOCK", "GOOD"]),
        Agent("COMPANY", "COMPANY", ["BANK", "LOAN", "DIV", "RESOURCE", "LABOR", "GOOD"]),
        Agent("CAPITAL", "CAPITAL", ["BANK", "DIV", "GOOD"]),
        Agent("BANK", "BANK", ["COMPANY_LOAN", "COMPANY_BANK", "LABOR_BANK", "RESOURCE_BANK", "CAPITAL_BANK"])
    ]

    # Create accounts from data
    accounts = CategoryObject[]
    row = df[period, :]

    # Add accounts for each agent
    for agent in agents
        for acc_type in agent.accounts
            acc_name = "$(agent.name)_$(acc_type)"
            if acc_name in names(df)
                push!(accounts, Account(acc_name, agent.name, acc_type, row[acc_name]))
            end
        end
    end

    # Create flows from data
    flows = CategoryObject[]
    flow_prefixes = ["FLOW_CONSUMPTION", "FLOW_INVESTMENT", "FLOW_PAYMENT", "FLOW_DIVIDEND"]

    for prefix in flow_prefixes
        for col in names(df)
            if startswith(string(col), prefix)
                value = row[col]
                # Extract flow type and participants from column name
                parts = split(string(col), "_")
                flow_type = parts[2]
                if length(parts) > 2
                    source = length(parts) > 3 ? parts[3] : "COMPANY"
                    target = length(parts) > 4 ? parts[4] : parts[3]
                    push!(flows, Flow(string(col), flow_type, source, target, value))
                end
            end
        end
    end

    # Create morphisms (transactions and state transitions)
    morphisms = CategoryMorphism[]

    # Add transactions from flows
    for flow in flows
        if flow.value != 0.0
            source_acc = findfirst(a -> a isa Account && a.agent == flow.source, accounts)
            target_acc = findfirst(a -> a isa Account && a.agent == flow.target, accounts)
            if source_acc !== nothing && target_acc !== nothing
                push!(morphisms, Transaction(
                    flow.name,
                    accounts[source_acc],
                    accounts[target_acc],
                    flow.value,
                    flow.type
                ))
            end
        end
    end

    # Create identity morphisms
    identities = Dict{CategoryObject,CategoryMorphism}()
    for obj in vcat(accounts, flows)
        if obj isa Account
            identities[obj] = Transaction("id_$(obj.name)", obj, obj, 0.0, "IDENTITY")
        elseif obj isa Flow
            identities[obj] = Transaction("id_$(obj.name)", obj, obj, 0.0, "IDENTITY")
        end
    end

    # Create composition dictionary
    composition = Dict{Tuple{CategoryMorphism,CategoryMorphism},CategoryMorphism}()

    # Return the category
    FinancialCategory(
        vcat(accounts, flows),
        morphisms,
        composition,
        identities
    )
end

"""
    create_time_series_functor(df::DataFrame)

Create a functor that maps time periods to financial categories.
"""
function create_time_series_functor(df::DataFrame)
    categories = Dict{Int,FinancialCategory}()

    for period in 1:nrow(df)
        categories[period] = create_financial_category(df, period)
    end

    return categories
end

"""
    create_price_natural_transformation(df::DataFrame)

Create a natural transformation for price adjustments between time periods.
"""
function create_price_natural_transformation(df::DataFrame)
    price_changes = Dict{Int,Float64}()

    for period in 2:nrow(df)
        prev_price = df[period-1, :PRICE_GOOD]
        curr_price = df[period, :PRICE_GOOD]
        price_changes[period] = curr_price / prev_price
    end

    return price_changes
end

"""
    verify_conservation_laws(category::FinancialCategory)

Verify that financial conservation laws hold in the category.
"""
function verify_conservation_laws(category::FinancialCategory)
    # Get all accounts
    accounts = filter(obj -> obj isa Account, category.objects)
    if isempty(accounts)
        return (bank_balance=false, loan_balance=false)
    end

    # Check bank account balances (debit - credit should sum to zero)
    # For each agent's bank accounts, debit - credit should sum to their net position
    company_bank = filter(acc -> acc.agent == "COMPANY" && acc.type == "BANK", accounts)
    bank_company = filter(acc -> acc.agent == "BANK" && acc.type == "COMPANY_BANK", accounts)
    household_bank = filter(acc -> acc.agent == "HOUSEHOLD" && acc.type == "BANK", accounts)

    # Calculate net positions
    company_net = !isempty(company_bank) ? sum(endswith(acc.name, "_DEBIT") ? acc.balance : -acc.balance for acc in company_bank) : 0.0
    bank_net = !isempty(bank_company) ? sum(endswith(acc.name, "_DEBIT") ? acc.balance : -acc.balance for acc in bank_company) : 0.0
    household_net = !isempty(household_bank) ? sum(endswith(acc.name, "_DEBIT") ? acc.balance : -acc.balance for acc in household_bank) : 0.0

    # Total bank balance should sum to zero
    bank_balance = company_net + bank_net + household_net

    # Check loan balances match between bank and company
    company_loans = filter(acc -> acc.agent == "COMPANY" && acc.type == "LOAN", accounts)
    bank_loans = filter(acc -> acc.agent == "BANK" && acc.type == "COMPANY_LOAN", accounts)

    # Calculate net loan positions
    company_loan_net = !isempty(company_loans) ? sum(endswith(acc.name, "_DEBIT") ? acc.balance : -acc.balance for acc in company_loans) : 0.0
    bank_loan_net = !isempty(bank_loans) ? sum(endswith(acc.name, "_DEBIT") ? acc.balance : -acc.balance for acc in bank_loans) : 0.0

    # Loan balances should be equal and opposite
    loan_balance = company_loan_net + bank_loan_net

    # Print debug information
    println("Bank balances:")
    println("Company net: ", company_net)
    println("Bank net: ", bank_net)
    println("Household net: ", household_net)
    println("Total bank balance: ", bank_balance)
    println("\nLoan balances:")
    println("Company loan net: ", company_loan_net)
    println("Bank loan net: ", bank_loan_net)
    println("Total loan balance: ", loan_balance)

    return (bank_balance=isapprox(bank_balance, 0.0, atol=1e-10), loan_balance=isapprox(loan_balance, 0.0, atol=1e-10))
end

"""
    verify_category(category::Category)

Verify that a category satisfies the category axioms:
1. Composition closure
2. Identity existence
3. Associativity
4. Identity laws
"""
function verify_category(category::Category)
    verify_composition_closure(category) &&
        verify_identity_existence(category) &&
        verify_associativity(category) &&
        verify_identity_laws(category)
end

"""
    verify_composition_closure(category::Category)

Verify that morphism composition is closed in the category.
"""
function verify_composition_closure(category::Category)
    for f in category.morphisms
        for g in category.morphisms
            if haskey(category.composition, (f, g))
                comp = category.composition[(f, g)]
                if !(comp in category.morphisms)
                    return false
                end
            end
        end
    end
    return true
end

"""
    verify_identity_existence(category::Category)

Verify that each object has an identity morphism.
"""
function verify_identity_existence(category::Category)
    for obj in category.objects
        if !haskey(category.identity, obj)
            return false
        end
    end
    return true
end

"""
    verify_associativity(category::Category)

Verify that morphism composition is associative.
"""
function verify_associativity(category::Category)
    for f in category.morphisms
        for g in category.morphisms
            for h in category.morphisms
                if haskey(category.composition, (f, g)) && haskey(category.composition, (g, h))
                    # (f ∘ g) ∘ h
                    fg = category.composition[(f, g)]
                    fgh1 = category.composition[(fg, h)]

                    # f ∘ (g ∘ h)
                    gh = category.composition[(g, h)]
                    fgh2 = category.composition[(f, gh)]

                    if fgh1 != fgh2
                        return false
                    end
                end
            end
        end
    end
    return true
end

"""
    verify_identity_laws(category::Category)

Verify that identity morphisms satisfy the identity laws.
"""
function verify_identity_laws(category::Category)
    for f in category.morphisms
        source_id = category.identity[f.source]
        target_id = category.identity[f.target]

        # Left identity: id ∘ f = f
        if haskey(category.composition, (source_id, f))
            if category.composition[(source_id, f)] != f
                return false
            end
        end

        # Right identity: f ∘ id = f
        if haskey(category.composition, (f, target_id))
            if category.composition[(f, target_id)] != f
                return false
            end
        end
    end
    return true
end

"""
    get_source(morphism::CategoryMorphism)

Get the source object of a morphism.
"""
function get_source(morphism::CategoryMorphism)
    morphism.source
end

"""
    get_target(morphism::CategoryMorphism)

Get the target object of a morphism.
"""
function get_target(morphism::CategoryMorphism)
    morphism.target
end

"""
    get_identity(category::Category, object::CategoryObject)

Get the identity morphism for an object.
"""
function get_identity(category::Category, object::CategoryObject)
    category.identity[object]
end

"""
    compose(category::Category, f::CategoryMorphism, g::CategoryMorphism)

Compose two morphisms if they are composable.
"""
function compose(category::Category, f::CategoryMorphism, g::CategoryMorphism)
    if haskey(category.composition, (f, g))
        category.composition[(f, g)]
    else
        throw(ArgumentError("Morphisms are not composable"))
    end
end

"""
    Functor{C<:Category,D<:Category}

A functor between categories C and D, consisting of:
- object_map: Maps objects from C to D
- morphism_map: Maps morphisms from C to D
"""
struct Functor{C<:Category,D<:Category}
    source::C
    target::D
    object_map::Dict{CategoryObject,CategoryObject}
    morphism_map::Dict{CategoryMorphism,CategoryMorphism}
end

"""
    NaturalTransformation{C<:Category,D<:Category}

A natural transformation between functors F,G: C → D, consisting of:
- components: Component morphisms for each object in C
"""
struct NaturalTransformation{C<:Category,D<:Category}
    source_functor::Functor{C,D}
    target_functor::Functor{C,D}
    components::Dict{CategoryObject,CategoryMorphism}
end

"""
    create_functor(source::C, target::D, 
                  object_map::Dict{CategoryObject,CategoryObject},
                  morphism_map::Dict{CategoryMorphism,CategoryMorphism}) where {C<:Category,D<:Category}

Create a functor between two categories.

# Arguments
- `source::Category`: Source category
- `target::Category`: Target category
- `object_map::Dict{CategoryObject,CategoryObject}`: Mapping of objects
- `morphism_map::Dict{CategoryMorphism,CategoryMorphism}`: Mapping of morphisms

# Examples
```julia
F = create_functor(C, D, object_map, morphism_map)
```
"""
function create_functor(source::C, target::D,
    object_map::Dict{CategoryObject,CategoryObject},
    morphism_map::Dict{CategoryMorphism,CategoryMorphism}) where {C<:Category,D<:Category}
    # Verify functoriality
    for f in source.morphisms
        for g in source.morphisms
            if haskey(source.composition, (f, g))
                h = source.composition[(f, g)]
                Ff = morphism_map[f]
                Fg = morphism_map[g]
                Fh = morphism_map[h]
                if !haskey(target.composition, (Ff, Fg)) ||
                   target.composition[(Ff, Fg)] != Fh
                    throw(ArgumentError("Mapping does not preserve composition"))
                end
            end
        end
    end

    # Verify identity preservation
    for obj in source.objects
        id = source.identity[obj]
        Fid = morphism_map[id]
        Fobj = object_map[obj]
        if target.identity[Fobj] != Fid
            throw(ArgumentError("Mapping does not preserve identities"))
        end
    end

    Functor{C,D}(source, target, object_map, morphism_map)
end

"""
    create_natural_transformation(F::Functor{C,D}, G::Functor{C,D},
                                components::Dict{CategoryObject,CategoryMorphism}) where {C<:Category,D<:Category}

Create a natural transformation between two functors.

# Arguments
- `F::Functor{C,D}`: Source functor
- `G::Functor{C,D}`: Target functor
- `components::Dict{CategoryObject,CategoryMorphism}`: Component morphisms

# Examples
```julia
α = create_natural_transformation(F, G, components)
```
"""
function create_natural_transformation(F::Functor{C,D}, G::Functor{C,D},
    components::Dict{CategoryObject,CategoryMorphism}) where {C<:Category,D<:Category}
    # Verify naturality condition
    for f in F.source.morphisms
        source_obj = get_source(f)
        target_obj = get_target(f)

        # Get component morphisms
        α_source = components[source_obj]
        α_target = components[target_obj]

        # Get functor images
        Ff = F.morphism_map[f]
        Gf = G.morphism_map[f]

        # Check naturality square commutes
        if !haskey(F.target.composition, (α_source, Gf)) ||
           !haskey(F.target.composition, (Ff, α_target)) ||
           F.target.composition[(α_source, Gf)] != F.target.composition[(Ff, α_target)]
            throw(ArgumentError("Naturality condition not satisfied"))
        end
    end

    NaturalTransformation{C,D}(F, G, components)
end

"""
    apply_functor(F::Functor, x::Union{CategoryObject,CategoryMorphism})

Apply a functor to an object or morphism.
"""
function apply_functor(F::Functor, x::CategoryObject)
    F.object_map[x]
end

function apply_functor(F::Functor, f::CategoryMorphism)
    F.morphism_map[f]
end

"""
    apply_natural_transformation(α::NaturalTransformation, x::CategoryObject)

Apply a natural transformation to an object.
"""
function apply_natural_transformation(α::NaturalTransformation, x::CategoryObject)
    α.components[x]
end

"""
    SimpleObject <: CategoryObject

A simple category object that wraps a string name.
"""
struct SimpleObject <: CategoryObject
    name::String
end

Base.:(==)(a::SimpleObject, b::SimpleObject) = a.name == b.name

"""
    SimpleMorphism <: CategoryMorphism

A simple category morphism between string-named objects.
"""
struct SimpleMorphism <: CategoryMorphism
    name::String
    source::SimpleObject
    target::SimpleObject
end

"""
    create_category(objects::Vector{String}, morphisms::Dict{String,Tuple{String,String}})

Create a category from string names of objects and morphisms.

# Arguments
- `objects::Vector{String}`: Vector of object names
- `morphisms::Dict{String,Tuple{String,String}}`: Dictionary mapping morphism names to (source, target) pairs

# Examples
```julia
objects = ["A", "B", "C"]
morphisms = Dict("f" => ("A", "B"), "g" => ("B", "C"))
category = create_category(objects, morphisms)
```
"""
function create_category(objects::Vector{String}, morphisms::Dict{String,Tuple{String,String}})
    # Convert strings to objects
    cat_objects = [SimpleObject(name) for name in objects]

    # Convert morphism descriptions to morphisms
    cat_morphisms = SimpleMorphism[]
    for (name, (src, tgt)) in morphisms
        source = SimpleObject(src)
        target = SimpleObject(tgt)
        if source in cat_objects && target in cat_objects
            push!(cat_morphisms, SimpleMorphism(name, source, target))
        end
    end

    # Create identity morphisms
    identities = Dict{SimpleObject,SimpleMorphism}()
    for obj in cat_objects
        identities[obj] = SimpleMorphism("id_$(obj.name)", obj, obj)
    end

    # Create composition dictionary
    composition = Dict{Tuple{SimpleMorphism,SimpleMorphism},SimpleMorphism}()

    # Add basic compositions (including with identities)
    for f in cat_morphisms
        source_id = identities[f.source]
        target_id = identities[f.target]

        # id ∘ f = f
        composition[(source_id, f)] = f
        # f ∘ id = f
        composition[(f, target_id)] = f
    end

    # Create the category
    ConcreteCategory{SimpleObject,SimpleMorphism}(
        cat_objects,
        cat_morphisms,
        composition,
        identities
    )
end
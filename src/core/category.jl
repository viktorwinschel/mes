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

    # Check bank account balances sum to zero
    bank_accounts = filter(acc -> acc.type == "BANK", accounts)
    bank_balance = sum(acc.balance for acc in bank_accounts)

    # Check loan balances match between bank and company
    company_loans = filter(acc -> acc.name == "COMPANY_LOAN", accounts)
    bank_loans = filter(acc -> acc.name == "BANK_COMPANY_LOAN", accounts)
    loan_balance = sum(acc.balance for acc in company_loans) +
                   sum(acc.balance for acc in bank_loans)

    return (
        bank_balance=isapprox(bank_balance, 0.0, atol=1e-10),
        loan_balance=isapprox(loan_balance, 0.0, atol=1e-10)
    )
end

"""
    verify_category(category)

Verify that a category satisfies the category axioms.
"""
function verify_category(category::Category)
    verify_composition_closure(category) &&
        verify_identity_existence(category)
end

"""
    verify_composition_closure(category)

Verify that morphism composition is closed in the category.
"""
function verify_composition_closure(category::Category)
    for f in category.morphisms
        for g in category.morphisms
            if haskey(category.composition, (f, g))
                h = category.composition[(f, g)]
                if !(h in category.morphisms)
                    return false
                end
            end
        end
    end
    return true
end

"""
    verify_identity_existence(category)

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
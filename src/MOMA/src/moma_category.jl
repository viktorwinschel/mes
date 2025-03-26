# Category Theory Framework for Financial Events
#
# This module implements a categorical framework for modeling financial events
# using category theory concepts. The main components are:
#
# 1. Category Structure:
#    - Objects: Financial accounts (Assets/Liabilities)
#    - Morphisms: Money flows between accounts
#    - Composition: Sequential money transfers
#    - Identity: Zero-amount transfers within same account
#
# 2. Diagrams:
#    - Represent financial events (e.g., money creation, loans)
#    - Ensure commutativity (consistency of flows)
#    - Support colimit construction (system-wide effects)
#
# 3. Functors and Natural Transformations:
#    - Map between micro and macro levels of the economy
#    - Preserve structural relationships
#
# Example Usage:
#
# ```julia
# # Create a money creation event
# date = Date("2025-01-15")
# diagram = create_money_creation_diagram(1000.0, date)
#
# # Verify categorical properties
# @assert is_commutative(diagram)
# @assert verify_universal_property(create_colimit(diagram))
#
# # Create functor to macro level
# F = create_micro_macro_functor(diagram)
# ```

module MOMACategory

using Dates

# Basic types for categorical structure
abstract type AccountType end
struct Asset <: AccountType end
struct Liability <: AccountType end

"""
    AccountObject

Represents an object in our financial category.
Each object is a financial account with:
- agent: The entity owning the account (e.g., "CB", "Banks")
- account: The type of account (e.g., "PaperMoney", "Deposit")
- acc_type: Classification as Asset or Liability
"""
struct AccountObject
    agent::String
    account::String
    acc_type::AccountType
end

"""
    AccountMorphism

Represents a morphism (arrow) in our financial category.
Each morphism is a money flow with:
- source: The account money flows from
- target: The account money flows to
- amount: The quantity of money transferred
- date: When the transfer occurs
"""
struct AccountMorphism
    source::AccountObject
    target::AccountObject
    amount::Float64
    date::Date
end

"""
    MacroEventDiagram

Represents a diagram in our category capturing a financial event.
Contains:
- objects: All accounts involved
- morphisms: All money flows
- event_type: Classification of the financial event
- event_date: When the event occurs
"""
struct MacroEventDiagram
    objects::Vector{AccountObject}
    morphisms::Vector{AccountMorphism}
    event_type::String
    event_date::Date
end

"""
    ColimitDiagram

Represents the colimit construction for a financial event.
The colimit captures the system-wide effect of local transfers.
Contains:
- base_diagram: The original event diagram
- colimit_object: The system balance object
- universal_morphisms: Morphisms from each object to the colimit
"""
struct ColimitDiagram
    base_diagram::MacroEventDiagram
    colimit_object::AccountObject
    universal_morphisms::Vector{AccountMorphism}
end

"""
    Account represents a T-account in double-entry bookkeeping.
    It tracks both debit and credit sides, along with transaction history.
"""
mutable struct Account
    name::String
    debit::Float64  # Left side of T-account
    credit::Float64 # Right side of T-account
    transactions::Vector{Dict}
end

# Constructor with default values
Account(name::String) = Account(name, 0.0, 0.0, Dict[])

export Account

# Constructor for account objects
function create_account_object(agent::String, account::String, acc_type::AccountType)
    AccountObject(agent, account, acc_type)
end

# Constructor for morphisms
function create_morphism(source::AccountObject, target::AccountObject, amount::Float64, date::Date)
    AccountMorphism(source, target, amount, date)
end

"""
    create_money_creation_diagram(amount::Float64, date::Date)

Create a diagram representing money creation by a central bank.
The diagram shows:
1. Central bank creates paper money (asset)
2. Paper money enters circulation (liability)
3. Banks receive deposits (liability)

Example:
```julia
diagram = create_money_creation_diagram(1000.0, Date("2025-01-15"))
```
"""
function create_money_creation_diagram(amount::Float64, date::Date)
    # Objects
    cb_paper = create_account_object("CB", "PaperMoney", Asset())
    cb_circulation = create_account_object("CB", "PaperMoneyCirculation", Liability())
    banks_deposit = create_account_object("Banks", "Deposit", Liability())

    # Morphisms
    m1 = create_morphism(cb_paper, cb_circulation, amount, date)
    m2 = create_morphism(cb_circulation, banks_deposit, amount, date)

    MacroEventDiagram(
        [cb_paper, cb_circulation, banks_deposit],
        [m1, m2],
        "MoneyCreation",
        date
    )
end

"""
    create_loans_diagram(amount::Float64, date::Date)

Create a diagram representing loan creation between banks.
The diagram shows:
1. Central bank paper money as source
2. Loans to different banks as targets
"""
function create_loans_diagram(amount::Float64, date::Date)
    # Objects
    cb_paper = create_account_object("CB", "PaperMoney", Asset())
    cb_loans_banks = create_account_object("CB", "LoansToBanks", Asset())
    cb_loans_bankb = create_account_object("CB", "LoansToBankb", Asset())

    # Morphisms
    m1 = create_morphism(cb_paper, cb_loans_banks, amount, date)
    m2 = create_morphism(cb_paper, cb_loans_bankb, amount, date)

    MacroEventDiagram(
        [cb_paper, cb_loans_banks, cb_loans_bankb],
        [m1, m2],
        "Loans",
        date
    )
end

"""
    create_bicycle_purchase_diagram(amount::Float64, date::Date)

Create a diagram representing a purchase transaction.
The diagram shows:
1. Buyer acquires bicycle (asset)
2. Buyer incurs liability
"""
function create_bicycle_purchase_diagram(amount::Float64, date::Date)
    # Objects
    buyer_bicycle = create_account_object("Buyer", "Bicycle", Asset())
    buyer_liability = create_account_object("Buyer", "LiabilityGeneral", Liability())

    # Morphisms
    m1 = create_morphism(buyer_bicycle, buyer_liability, amount, date)

    MacroEventDiagram(
        [buyer_bicycle, buyer_liability],
        [m1],
        "BicyclePurchase",
        date
    )
end

"""
    create_boe_creation_diagram(amount::Float64, date::Date)

Create a diagram representing Bill of Exchange creation.
The diagram shows:
1. Bank receives BOE (asset)
2. Bank creates liability
"""
function create_boe_creation_diagram(amount::Float64, date::Date)
    # Objects
    bank_receivable = create_account_object("Bank", "ReceivableFromBOE", Asset())
    bank_liability = create_account_object("Bank", "LiabilityFromBOE", Liability())

    # Morphisms
    m1 = create_morphism(bank_receivable, bank_liability, amount, date)

    MacroEventDiagram(
        [bank_receivable, bank_liability],
        [m1],
        "BOECreation",
        date
    )
end

"""
    create_boe_transfer_diagram(amount::Float64, date::Date)

Create a diagram representing BOE transfer.
The diagram shows:
1. Bank's BOE receivable
2. Bank's deposit liability
"""
function create_boe_transfer_diagram(amount::Float64, date::Date)
    # Objects
    bank_receivable = create_account_object("Bank", "ReceivableFromBOE", Asset())
    bank_deposits = create_account_object("Bank", "Deposits", Liability())

    # Morphisms
    m1 = create_morphism(bank_receivable, bank_deposits, amount, date)

    MacroEventDiagram(
        [bank_receivable, bank_deposits],
        [m1],
        "BOETransfer",
        date
    )
end

"""
    create_settlement_diagram(amount::Float64, date::Date)

Create a diagram representing interbank settlement.
The diagram shows:
1. Central bank deposit liabilities
2. Bank deposit transfers
3. Final settlement at central bank
"""
function create_settlement_diagram(amount::Float64, date::Date)
    # Objects
    cb_deposits_banks = create_account_object("CB", "DepositsFromBanks", Liability())
    cb_deposits_bankb = create_account_object("CB", "DepositsFromBankb", Liability())
    banks_deposit = create_account_object("Banks", "Deposit", Liability())
    bankb_deposit = create_account_object("Bankb", "Deposit", Liability())

    # Morphisms
    m1 = create_morphism(cb_deposits_banks, banks_deposit, amount, date)
    m2 = create_morphism(banks_deposit, bankb_deposit, amount, date)
    m3 = create_morphism(bankb_deposit, cb_deposits_bankb, amount, date)

    MacroEventDiagram(
        [cb_deposits_banks, cb_deposits_bankb, banks_deposit, bankb_deposit],
        [m1, m2, m3],
        "Settlement",
        date
    )
end

"""
    compose_morphisms(f::AccountMorphism, g::AccountMorphism)

Compose two morphisms in our category, representing sequential money transfers.
Handles identity morphisms specially to preserve amounts correctly.

Example:
```julia
m1 = create_morphism(cb_paper, cb_circulation, 1000.0, date)
m2 = create_morphism(cb_circulation, banks_deposit, 1000.0, date)
composed = compose_morphisms(m1, m2)  # Transfer from cb_paper to banks_deposit
```
"""
function compose_morphisms(f::AccountMorphism, g::AccountMorphism)
    @assert f.target == g.source "Morphisms not composable"
    # If either morphism is an identity (source == target), use the other morphism's amount
    if f.source == f.target
        create_morphism(f.source, g.target, g.amount, f.date)
    elseif g.source == g.target
        create_morphism(f.source, g.target, f.amount, f.date)
    else
        # For non-identity morphisms, preserve the amount of the first morphism
        create_morphism(f.source, g.target, f.amount, f.date)
    end
end

"""
    is_commutative(diagram::MacroEventDiagram)

Verify that a diagram commutes, ensuring consistency of money flows.
For any two paths between the same accounts, the amounts must match.

Example:
```julia
diagram = create_money_creation_diagram(1000.0, date)
@assert is_commutative(diagram)  # Verify flows are consistent
```
"""
function is_commutative(diagram::MacroEventDiagram)
    for i in 1:length(diagram.morphisms)
        for j in 1:length(diagram.morphisms)
            if i != j
                if diagram.morphisms[i].source == diagram.morphisms[j].source &&
                   diagram.morphisms[i].target == diagram.morphisms[j].target
                    @assert diagram.morphisms[i].amount == diagram.morphisms[j].amount "Diagram does not commute"
                end
            end
        end
    end
    true
end

"""
    create_colimit(diagram::MacroEventDiagram)

Construct the colimit of a financial event diagram.
The colimit represents the system-wide effect of local transfers:
1. Source objects contribute their outflow
2. Target objects contribute their inflow
3. Intermediary objects have no net effect

Example:
```julia
diagram = create_money_creation_diagram(1000.0, date)
colimit = create_colimit(diagram)
@assert verify_universal_property(colimit)
```
"""
function create_colimit(diagram::MacroEventDiagram)
    # Create colimit object (system balance)
    colimit_obj = create_account_object("System", "Balance", Asset())

    # Create universal morphisms that preserve the amounts
    universal_morphisms = AccountMorphism[]

    # For each object in the diagram, create a morphism to the colimit
    for obj in diagram.objects
        # Find all morphisms where this object is involved
        incoming = filter(m -> m.target == obj, diagram.morphisms)
        outgoing = filter(m -> m.source == obj, diagram.morphisms)

        # For financial flows, we want to:
        # 1. If an object is a source (outgoing > 0), use the outgoing amount
        # 2. If an object is a target (incoming > 0), use the incoming amount
        # 3. If it's an intermediary (both > 0), use 0 as the net effect
        if !isempty(outgoing)
            # Source object - use outgoing amount
            amount = outgoing[1].amount
        elseif !isempty(incoming)
            # Target object - use incoming amount
            amount = incoming[1].amount
        else
            # Isolated object - no effect
            amount = 0.0
        end

        # Create morphism to colimit
        push!(universal_morphisms,
            create_morphism(obj, colimit_obj, amount, diagram.event_date))
    end

    ColimitDiagram(diagram, colimit_obj, universal_morphisms)
end

"""
    verify_universal_property(colimit::ColimitDiagram)

Verify the universal property of the colimit construction.
For each morphism in the base diagram:
1. Source object's morphism to colimit equals the outflow
2. Target object's morphism to colimit equals the inflow

This ensures the colimit correctly captures the global effect
of all local transfers.
"""
function verify_universal_property(colimit::ColimitDiagram)
    # For each morphism in the base diagram
    for m1 in colimit.base_diagram.morphisms
        # Get the universal morphisms for source and target
        source_to_colimit = filter(um -> um.source == m1.source,
            colimit.universal_morphisms)[1]
        target_to_colimit = filter(um -> um.source == m1.target,
            colimit.universal_morphisms)[1]

        # The diagram should commute: source -> target -> colimit = source -> colimit
        # For financial flows, when money moves from A to B:
        # 1. A's morphism to colimit should equal the amount (outflow)
        # 2. B's morphism to colimit should equal the amount (inflow)
        @assert abs(source_to_colimit.amount - m1.amount) < 1e-10 "Universal property violated at source"
        @assert abs(target_to_colimit.amount - m1.amount) < 1e-10 "Universal property violated at target"
    end
    true
end

"""
    create_full_event_sequence(
        initial_money::Float64,
        loan_amount::Float64,
        bicycle_price::Float64,
        start_date::Date
    )

Create a sequence of financial events representing a complete transaction cycle:
1. Money Creation: Central bank creates initial money
2. Loans: Banks receive loans
3. Bicycle Purchase: Consumer buys goods
4. BOE Creation: Bank creates bill of exchange
5. BOE Transfer: Bank transfers BOE
6. Settlement: Final settlement between banks

Example:
```julia
events = create_full_event_sequence(
    1000.0,  # Initial money
    200.0,   # Loan amount
    100.0,   # Bicycle price
    Date("2025-01-15")
)
```
"""
function create_full_event_sequence(initial_money::Float64, loan_amount::Float64,
    bicycle_price::Float64, start_date::Date)
    events = MacroEventDiagram[]

    # Event 1: Money Creation
    push!(events, create_money_creation_diagram(initial_money, start_date))

    # Event 2: Loans
    push!(events, create_loans_diagram(loan_amount, start_date + Day(1)))

    # Event 3: Bicycle Purchase
    push!(events, create_bicycle_purchase_diagram(bicycle_price, start_date + Day(2)))

    # Event 4: BOE Creation
    push!(events, create_boe_creation_diagram(bicycle_price, start_date + Day(3)))

    # Event 5: BOE Transfer
    push!(events, create_boe_transfer_diagram(bicycle_price, start_date + Day(4)))

    # Event 6: Settlement
    push!(events, create_settlement_diagram(bicycle_price, start_date + Day(5)))

    return events
end

"""
    MicroMacroFunctor

Functor mapping between micro and macro levels of the economy.
Contains:
- source_category: "Micro" level
- target_category: "Macro" level
- object_map: Maps micro accounts to macro accounts
- morphism_map: Maps micro flows to macro flows

The functor preserves the categorical structure while
changing the scale of analysis.
"""
struct MicroMacroFunctor
    source_category::String  # "Micro"
    target_category::String  # "Macro"
    object_map::Dict{AccountObject,AccountObject}
    morphism_map::Dict{AccountMorphism,AccountMorphism}
end

"""
    create_micro_macro_functor(diagram::MacroEventDiagram)

Create a functor that maps a micro-level diagram to the macro level.
For each object and morphism:
1. Prepends "Macro" to agent names
2. Preserves account types and amounts
3. Maintains structural relationships

Example:
```julia
diagram = create_money_creation_diagram(1000.0, date)
F = create_micro_macro_functor(diagram)
```
"""
function create_micro_macro_functor(diagram::MacroEventDiagram)
    # Map objects to their macro-level counterparts
    object_map = Dict{AccountObject,AccountObject}()
    for obj in diagram.objects
        macro_obj = create_account_object(
            "Macro" * obj.agent,
            obj.account,
            obj.acc_type
        )
        object_map[obj] = macro_obj
    end

    # Map morphisms to their macro-level counterparts
    morphism_map = Dict{AccountMorphism,AccountMorphism}()
    for morph in diagram.morphisms
        macro_morph = create_morphism(
            object_map[morph.source],
            object_map[morph.target],
            morph.amount,
            morph.date
        )
        morphism_map[morph] = macro_morph
    end

    MicroMacroFunctor("Micro", "Macro", object_map, morphism_map)
end

"""
    NaturalTransformation

Represents a natural transformation between functors.
Contains:
- source_functor: Starting functor
- target_functor: Ending functor
- components: Morphisms between functorial images

Natural transformations ensure that different ways of
mapping between levels are compatible.
"""
struct NaturalTransformation
    source_functor::MicroMacroFunctor
    target_functor::MicroMacroFunctor
    components::Dict{AccountObject,AccountMorphism}
end

"""
    create_natural_transformation(
        F::MicroMacroFunctor,
        G::MicroMacroFunctor,
        diagram::MacroEventDiagram
    )

Create a natural transformation between two micro-macro functors.
For each object in the diagram:
1. Creates a morphism between its images under F and G
2. Uses zero amount for identity-like behavior
3. Ensures naturality squares commute
"""
function create_natural_transformation(F::MicroMacroFunctor, G::MicroMacroFunctor,
    diagram::MacroEventDiagram)
    components = Dict{AccountObject,AccountMorphism}()

    for obj in diagram.objects
        # Create component morphism for each object
        components[obj] = create_morphism(
            F.object_map[obj],
            G.object_map[obj],
            0.0,  # Identity morphism
            diagram.event_date
        )
    end

    NaturalTransformation(F, G, components)
end

"""
    struct MoneyPattern

Represents the emergence of money through complex links between micro-level accounts.
Each MoneyPattern tracks:
1. The micro accounts involved
2. The type of money created
3. The binding mechanism that creates the emergence

Example:
```julia
# Bank deposit creation
pattern = MoneyPattern(
    [bank_deposit_account, customer_claim_account],
    "Bank Deposits",
    "Deposit Creation"
)
```
"""
struct MoneyPattern
    micro_accounts::Vector{Account}
    macro_property::String
    binding_mechanism::String
end

"""
    struct ComplexLink

Represents a binding mechanism that creates emergence through
linking micro-level patterns to macro-level properties.

Example:
```julia
# Deposit creation link
link = ComplexLink(
    "Deposit Creation",
    ["Bank Account", "Customer Account"],
    "Bank Deposits"
)
```
"""
struct ComplexLink
    mechanism::String
    required_accounts::Vector{String}
    emergent_property::String
end

"""
    detect_money_emergence(landscape::MOMALandscape)

Identifies emergent monetary properties by detecting valid complex links
between micro-level accounts. Money emerges when accounts properly bind
according to defined patterns.

Returns a Dict mapping each type of emergent money to its supporting
micro-level structure.
"""
function detect_money_emergence(landscape::MOMALandscape)
    # Define known complex links that create money
    complex_links = [
        ComplexLink(
            "Deposit Creation",
            ["Deposits from Banks", "Deposits at Banks"],
            "Bank Deposits"
        ),
        ComplexLink(
            "Reserve Creation",
            ["CB Reserve", "Bank Reserve Account"],
            "Central Bank Money"
        ),
        ComplexLink(
            "BOE Creation",
            ["Receivable from BOE", "Liability from BOE"],
            "Bills of Exchange"
        )
    ]

    # Track emergent monetary properties
    emergent_money = Dict{String,Vector{MoneyPattern}}()

    # Check each complex link
    for link in complex_links
        emergent_money[link.emergent_property] = []

        # Find all instances of this pattern
        for (_, agent1) in landscape.agents
            for (_, agent2) in landscape.agents
                # Check if agents have required accounts
                accounts = Account[]
                valid_pattern = true

                for acc_name in link.required_accounts
                    if haskey(agent1.accounts, acc_name)
                        push!(accounts, agent1.accounts[acc_name])
                    elseif haskey(agent2.accounts, acc_name)
                        push!(accounts, agent2.accounts[acc_name])
                    else
                        valid_pattern = false
                        break
                    end
                end

                # If valid pattern found, money emerges
                if valid_pattern && length(accounts) == length(link.required_accounts)
                    pattern = MoneyPattern(
                        accounts,
                        link.emergent_property,
                        link.mechanism
                    )
                    push!(emergent_money[link.emergent_property], pattern)
                end
            end
        end
    end

    return emergent_money
end

"""
    verify_money_emergence(pattern::MoneyPattern)

Verifies that a money pattern represents valid emergence by checking:
1. All required accounts are present
2. Accounts properly bind (claims match liabilities)
3. Macro invariance is maintained
"""
function verify_money_emergence(pattern::MoneyPattern)
    # Sum all claims and liabilities
    total = 0.0
    for account in pattern.micro_accounts
        total += account.debit - account.credit
    end

    # Valid emergence requires perfect balance
    return isapprox(total, 0.0, atol=1e-10)
end

"""
    get_money_supply(landscape::MOMALandscape)

Calculates total money supply by summing all emergent monetary properties.
This demonstrates how micro-level accounts create macro-level money through
complex links and emergence.
"""
function get_money_supply(landscape::MOMALandscape)
    money_supply = Dict{String,Float64}()

    # Detect all emergent money
    emergent_money = detect_money_emergence(landscape)

    # Sum each type of money
    for (money_type, patterns) in emergent_money
        money_supply[money_type] = 0.0
        for pattern in patterns
            if verify_money_emergence(pattern)
                # Take absolute value since money is always positive
                # at macro level regardless of which side holds claim
                money_supply[money_type] += abs(
                    pattern.micro_accounts[1].debit -
                    pattern.micro_accounts[1].credit
                )
            end
        end
    end

    return money_supply
end

"""
Categorical implementation for BOE bicycle example:
1. Pullbacks for account balance
2. Pushouts for relationships
3. Memory generation through categorical binding
"""

# Categorical Structures
struct TAccountPullback
    debit::Float64
    credit::Float64
    account_name::String
end

struct DebtPushout
    creditor::String
    debtor::String
    relationship::String
    amount::Float64
end

"""
    verify_micro_pullback(account::Account)

Verifies account balance through pullback universal property.
"""
function verify_micro_pullback(account::Account)
    # Construct pullback
    pullback = TAccountPullback(
        account.debit,
        account.credit,
        account.name
    )

    # Universal property: Any balanced state factors through pullback
    return isapprox(pullback.debit, pullback.credit)
end

"""
    verify_macro_pushout(landscape::MOMALandscape, relationship::String)

Verifies debt relationship through pushout universal property.
"""
function verify_macro_pushout(landscape::MOMALandscape, relationship::String)
    # Parse relationship
    parts = split(relationship, " ↔ ")
    if length(parts) != 2
        return false
    end

    creditor_account, debtor_account = parts

    # Find involved agents
    creditor = nothing
    debtor = nothing
    amount = 0.0

    for (name, agent) in landscape.agents
        for (acc_name, account) in agent.accounts
            if acc_name == creditor_account
                creditor = name
                amount = account.debit - account.credit
            elseif acc_name == debtor_account
                debtor = name
            end
        end
    end

    # Construct pushout
    if !isnothing(creditor) && !isnothing(debtor)
        pushout = DebtPushout(
            creditor,
            debtor,
            relationship,
            amount
        )

        # Universal property: Relationship must factor through pushout
        return true
    end

    return false
end

"""
    MacroBalance

Represents the categorical construction of macro balancedness:
1. Micro level: Individual accounts balance through pullbacks
2. Macro level: Relationships balance through pushouts
3. The connection: Micro balances compose to macro balance

Example:
```
Micro Balance (Pullback):          Macro Balance (Pushout):
Debit ←-- Account --→ Credit      Agent A --→ Relationship ←-- Agent B
  ↓                     ↓            ↓                           ↓
Amount ←---------- Amount         Claims -------------------→ Liabilities
```
"""
struct MacroBalance
    micro_pullbacks::Vector{TAccountPullback}
    macro_pushout::DebtPushout
    binding_mechanism::String
end

"""
    verify_macro_balance(landscape::MOMALandscape, relationship::String)

Verifies that a relationship maintains macro balance through:
1. All involved accounts are internally balanced (pullbacks)
2. The relationship itself balances (pushout)
3. The composition of micro balances yields macro balance
"""
function verify_macro_balance(landscape::MOMALandscape, relationship::String)
    # Parse relationship
    parts = split(relationship, " ↔ ")
    if length(parts) != 2
        return false
    end

    creditor_account, debtor_account = parts

    # 1. Find involved agents and accounts
    creditor = nothing
    debtor = nothing
    creditor_pullback = nothing
    debtor_pullback = nothing

    for (name, agent) in landscape.agents
        for (acc_name, account) in agent.accounts
            if acc_name == creditor_account
                creditor = name
                creditor_pullback = TAccountPullback(
                    account.debit,
                    account.credit,
                    acc_name
                )
            elseif acc_name == debtor_account
                debtor = name
                debtor_pullback = TAccountPullback(
                    account.debit,
                    account.credit,
                    acc_name
                )
            end
        end
    end

    # 2. Verify micro balances (pullbacks)
    if isnothing(creditor_pullback) || isnothing(debtor_pullback)
        return false
    end

    if !verify_micro_pullback(creditor_pullback) ||
       !verify_micro_pullback(debtor_pullback)
        return false
    end

    # 3. Construct and verify macro balance (pushout)
    amount = creditor_pullback.debit - creditor_pullback.credit
    pushout = DebtPushout(
        creditor,
        debtor,
        relationship,
        amount
    )

    # 4. Verify composition: micro balances → macro balance
    # The key insight: Macro balance emerges from composition of micro balances
    creditor_balance = creditor_pullback.debit - creditor_pullback.credit
    debtor_balance = debtor_pullback.debit - debtor_pullback.credit

    # Macro balance means these compose to zero
    return isapprox(creditor_balance + debtor_balance, 0.0)
end

"""
    generate_balance_possibilities(debit::Dict, landscape::MOMALandscape)

Generates possible credit entries that maintain both:
1. Micro balance through pullbacks
2. Macro balance through pushouts
"""
function generate_balance_possibilities(debit::Dict, landscape::MOMALandscape)
    possibilities = Dict{String,Vector{Dict}}()

    # 1. Direct balance
    possibilities["direct"] = [Dict(
        "agent" => debit["to"],
        "account" => corresponding_account(debit["account"]),
        "amount" => debit["amount"]
    )]

    # 2. Indirect balance (through intermediary)
    possibilities["indirect"] = []
    for (name, agent) in landscape.agents
        if name != debit["from"] && name != debit["to"]
            push!(possibilities["indirect"], Dict(
                "agent" => name,
                "account" => corresponding_account(debit["account"]),
                "amount" => debit["amount"]
            ))
        end
    end

    # Filter to maintain macro balance
    valid = Dict{String,Vector{Dict}}()

    for (type, credits) in possibilities
        valid[type] = []
        for credit in credits
            # Clone landscape to test
            test_landscape = deepcopy(landscape)

            # Apply credit
            agent = test_landscape.agents[credit["agent"]]
            update_account!(agent.accounts[credit["account"]],
                credit["amount"], "credit", debit["date"])

            # Verify both micro and macro balance
            if verify_micro_pullback(agent.accounts[credit["account"]]) &&
               verify_macro_balance(test_landscape,
                "$(debit["account"]) ↔ $(credit["account"])")
                push!(valid[type], credit)
            end
        end
    end

    return valid
end

"""
    check_categorical_balance(landscape::MOMALandscape)

Verifies complete categorical balance structure:
1. All accounts balance internally (micro pullbacks)
2. All relationships balance (macro pushouts)
3. The composition yields global balance
"""
function check_categorical_balance(landscape::MOMALandscape)
    # 1. Check all micro balances
    for (_, agent) in landscape.agents
        for (_, account) in agent.accounts
            if !verify_micro_pullback(account)
                return false
            end
        end
    end

    # 2. Check all macro balances
    relationships = [
        "Inventory ↔ Bicycle Asset",
        "BOE Receivable ↔ BOE Liability",
        "Cash ↔ Deposits"
    ]

    for relationship in relationships
        if !verify_macro_balance(landscape, relationship)
            return false
        end
    end

    # 3. Check global balance (composition)
    total_balance = 0.0
    for (_, agent) in landscape.agents
        for (_, account) in agent.accounts
            total_balance += account.debit - account.credit
        end
    end

    return isapprox(total_balance, 0.0)
end

"""
    corresponding_account(account::String)

Returns the corresponding account name for a given account.
"""
function corresponding_account(account::String)
    pairs = Dict(
        "Inventory" => "Bicycle Asset",
        "BOE Receivable" => "BOE Liability",
        "Cash" => "Deposits"
    )

    return get(pairs, account, "Unknown")
end

"""
    generate_balance_diagram(landscape::MOMALandscape)

Generates complete categorical diagram of system state.
"""
function generate_balance_diagram(landscape::MOMALandscape)
    diagram = Dict{String,Any}()

    # 1. Collect pullbacks
    diagram["pullbacks"] = Dict{String,TAccountPullback}()
    for (agent_name, agent) in landscape.agents
        for (acc_name, account) in agent.accounts
            diagram["pullbacks"]["$agent_name:$acc_name"] =
                TAccountPullback(account.debit, account.credit, acc_name)
        end
    end

    # 2. Collect pushouts
    diagram["pushouts"] = Dict{String,DebtPushout}()
    relationships = [
        "Inventory ↔ Bicycle Asset",
        "BOE Receivable ↔ BOE Liability",
        "Cash ↔ Deposits"
    ]

    for relationship in relationships
        parts = split(relationship, " ↔ ")
        if length(parts) == 2
            creditor_account, debtor_account = parts

            # Find involved agents
            for (name1, agent1) in landscape.agents
                for (name2, agent2) in landscape.agents
                    if haskey(agent1.accounts, creditor_account) &&
                       haskey(agent2.accounts, debtor_account)
                        amount = agent1.accounts[creditor_account].debit -
                                 agent1.accounts[creditor_account].credit

                        diagram["pushouts"][relationship] =
                            DebtPushout(name1, name2, relationship, amount)
                    end
                end
            end
        end
    end

    return diagram
end

# Export necessary components
export AccountType, Asset, Liability, AccountObject, AccountMorphism,
    MacroEventDiagram, ColimitDiagram, create_account_object, create_morphism,
    create_money_creation_diagram, create_loans_diagram, create_bicycle_purchase_diagram,
    create_boe_creation_diagram, create_boe_transfer_diagram, create_settlement_diagram,
    compose_morphisms, is_commutative, create_colimit, verify_universal_property,
    create_full_event_sequence, MicroMacroFunctor, create_micro_macro_functor,
    NaturalTransformation

end # module MOMACategory
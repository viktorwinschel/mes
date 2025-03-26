"""
This module implements the event-based dynamics of Memory Evolutive Systems (MES)
as described in Ehresmann & Vanbremeersch (2007).

Key concepts:
- Event sequences and their composition
- Memory dynamics and evolution
- Pattern binding and emergence
- Hierarchical complexification

See `docs/src/theory/mes07_formulas.md` for detailed mathematical formulas.

Memory in MOMA actively generates financial data through event processing:
1. Each event creates new account states (micro memory)
2. These combine to form system-wide patterns (macro memory)
3. Memory evolution tracks both states and their relationships
"""
module MOMAEvents

using Dates
using DataFrames
using ..MOMACategory
using ..MOMASimulation: MOMALandscape, Agent, Account

export create_event_sequence, compose_events, verify_event_closure

# Process a single event in the simulation
function process_event!(landscape::MOMALandscape, event::Dict)
    """
    Process financial events while maintaining both micro and macro invariance.

    Each event creates corresponding bookings in affected agents' accounts:
    1. Micro level: Each agent records debits and credits in their own books
    2. Macro level: Debt relationships between agents must cancel out

    Example - Loan event:
    - CB's books (micro): DR Loans to Banks, CR Deposits from Banks
    - Bank's books (micro): DR CB Reserve, CR Loans from CB
    - Macro level: "Loans to Banks" ↔ "Loans from CB" nets to zero
    """
    date = event["date"]
    agent_name = event["agent"]
    accounts = event["accounts"]
    amount = event["amount"]

    # Process different event types
    if event["type"] == "money_creation"
        # Single macro booking becomes two micro bookings
        agent = landscape.agents["CB"]
        # CB's perspective: Debit Paper Money
        update_account!(agent.accounts["Paper Money"], amount, "debit", date)
        # CB's perspective: Credit Paper Money in Circulation
        update_account!(agent.accounts["Paper Money in Circulation"], amount, "credit", date)
        # Record both sides of the T-account entry
        record_transaction!(landscape, date, "CB", "Paper Money", amount)
        record_transaction!(landscape, date, "CB", "Paper Money in Circulation", amount)

    elseif event["type"] == "loans"
        # CB to Banks loan - two sets of micro bookings
        cb = landscape.agents["CB"]
        banks = landscape.agents["Banks"]

        # CB's perspective
        update_account!(cb.accounts["Loans to Banks"], amount, "debit", date)
        update_account!(cb.accounts["Deposits from Banks"], amount, "credit", date)
        record_transaction!(landscape, date, "CB", "Loans to Banks", amount)
        record_transaction!(landscape, date, "CB", "Deposits from Banks", amount)

        # Banks' perspective
        update_account!(banks.accounts["CB Reserve"], amount, "debit", date)
        update_account!(banks.accounts["Loans from CB"], amount, "credit", date)
        record_transaction!(landscape, date, "Banks", "CB Reserve", amount)
        record_transaction!(landscape, date, "Banks", "Loans from CB", amount)

        # CB to Bankb loan - two sets of micro bookings
        bankb = landscape.agents["Bankb"]

        # CB's perspective
        update_account!(cb.accounts["Loans to Bankb"], amount, "debit", date)
        update_account!(cb.accounts["Deposits from Bankb"], amount, "credit", date)
        record_transaction!(landscape, date, "CB", "Loans to Bankb", amount)
        record_transaction!(landscape, date, "CB", "Deposits from Bankb", amount)

        # Bankb's perspective
        update_account!(bankb.accounts["CB Reserve"], amount, "debit", date)
        update_account!(bankb.accounts["Loans from CB"], amount, "credit", date)
        record_transaction!(landscape, date, "Bankb", "CB Reserve", amount)
        record_transaction!(landscape, date, "Bankb", "Loans from CB", amount)

    elseif event["type"] == "bicycle_purchase"
        # Buyer bookings
        buyer = landscape.agents["B"]
        # Debit Bicycle (asset)
        update_account!(buyer.accounts["Bicycle"], amount, "debit", date)
        # Credit Liability General (liability)
        update_account!(buyer.accounts["Liability General"], amount, "credit", date)
        # Record Buyer transactions
        record_transaction!(landscape, date, "B", "Bicycle", amount)
        record_transaction!(landscape, date, "B", "Liability General", amount)

        # Seller bookings
        seller = landscape.agents["S"]
        # Debit Receivable General (asset)
        update_account!(seller.accounts["Receivable General"], amount, "debit", date)
        # Credit Bicycle (asset)
        update_account!(seller.accounts["Bicycle"], amount, "credit", date)
        # Record Seller transactions
        record_transaction!(landscape, date, "S", "Receivable General", amount)
        record_transaction!(landscape, date, "S", "Bicycle", amount)

    elseif event["type"] == "boe_creation"
        """
        BOE Creation - Initial Debt Relationship:

        Micro level (S's books):
        DR Receivable from BOE | amount
        CR Liability from BOE  | amount

        Micro level (B's books):
        DR Liability General   | amount
        CR Liability from BOE  | amount

        Macro level:
        - S's claim on B (Receivable) exactly matches B's obligation (Liability)
        - The BOE itself represents this claim/obligation relationship
        """
        # Seller bookings
        seller = landscape.agents["S"]
        update_account!(seller.accounts["Receivable from BOE"], amount, "debit", date)
        update_account!(seller.accounts["Liability from BOE"], amount, "credit", date)
        record_transaction!(landscape, date, "S", "Receivable from BOE", amount)
        record_transaction!(landscape, date, "S", "Liability from BOE", amount)

        # Buyer bookings
        buyer = landscape.agents["B"]
        update_account!(buyer.accounts["Liability General"], amount, "debit", date)
        update_account!(buyer.accounts["Liability from BOE"], amount, "credit", date)
        record_transaction!(landscape, date, "B", "Liability General", amount)
        record_transaction!(landscape, date, "B", "Liability from BOE", amount)

        # Verify BOE macro invariance after creation
        check_boe_macro_invariance(landscape)

    elseif event["type"] == "boe_bank_transfer"
        """
        BOE Bank Transfer - Debt Relationship Transfer:

        When transferred to Banks:
        Micro level (Banks' books):
        DR Receivable from BOE | amount
        CR Deposits from S     | amount

        Micro level (S's books):
        DR Deposits at Banks   | amount
        CR Receivable from BOE | amount

        Macro level:
        - Original BOE claim is replaced by bank deposit relationship
        - Total claims in system remain unchanged
        - All debtor-creditor relationships still net to zero
        """
        if agent_name == "Banks"
            # Banks bookings (S's bank)
            banks = landscape.agents["Banks"]
            update_account!(banks.accounts["Receivable from BOE"], amount, "debit", date)
            update_account!(banks.accounts["Deposits from S"], amount, "credit", date)
            record_transaction!(landscape, date, "Banks", "Receivable from BOE", amount)
            record_transaction!(landscape, date, "Banks", "Deposits from S", amount)

            # Seller bookings
            seller = landscape.agents["S"]
            update_account!(seller.accounts["Deposits at Banks"], amount, "debit", date)
            update_account!(seller.accounts["Receivable from BOE"], amount, "credit", date)
            record_transaction!(landscape, date, "S", "Deposits at Banks", amount)
            record_transaction!(landscape, date, "S", "Receivable from BOE", amount)
        else
            """
            When transferred to Bankb:
            Macro level:
            - BOE claim moves between banks
            - Interbank deposit relationship is created
            - Total claims in system remain unchanged
            """
            # Bankb bookings
            bankb = landscape.agents["Bankb"]
            update_account!(bankb.accounts["Receivable from BOE"], amount, "debit", date)
            update_account!(bankb.accounts["Deposits from Banks"], amount, "credit", date)
            record_transaction!(landscape, date, "Bankb", "Receivable from BOE", amount)
            record_transaction!(landscape, date, "Bankb", "Deposits from Banks", amount)

            # Banks bookings
            banks = landscape.agents["Banks"]
            update_account!(banks.accounts["Deposits at Bankb"], amount, "debit", date)
            update_account!(banks.accounts["Receivable from BOE"], amount, "credit", date)
            record_transaction!(landscape, date, "Banks", "Deposits at Bankb", amount)
            record_transaction!(landscape, date, "Banks", "Receivable from BOE", amount)
        end

        # Verify BOE macro invariance after transfer
        check_boe_macro_invariance(landscape)

    elseif event["type"] == "settlement"
        # Banks bookings
        banks = landscape.agents["Banks"]
        # Debit Deposits at Bankb (asset)
        update_account!(banks.accounts["Deposits at Bankb"], amount, "debit", date)
        # Credit CB Reserve (asset)
        update_account!(banks.accounts["CB Reserve"], amount, "credit", date)
        # Record Banks transactions
        record_transaction!(landscape, date, "Banks", "Deposits at Bankb", amount)
        record_transaction!(landscape, date, "Banks", "CB Reserve", amount)

        # Bankb bookings
        bankb = landscape.agents["Bankb"]
        # Debit CB Reserve (asset)
        update_account!(bankb.accounts["CB Reserve"], amount, "debit", date)
        # Credit Deposits from Banks (liability)
        update_account!(bankb.accounts["Deposits from Banks"], amount, "credit", date)
        # Record Bankb transactions
        record_transaction!(landscape, date, "Bankb", "CB Reserve", amount)
        record_transaction!(landscape, date, "Bankb", "Deposits from Banks", amount)
    end
end

# Update account balance using T-account logic
function update_account!(account::Account, amount::Float64, type::String, date::Date)
    """
    Update T-account balances following double-entry bookkeeping principles.

    At micro level:
    - Debit increases left side of T-account
    - Credit increases right side of T-account
    - These must balance within each agent's books

    At macro level:
    - These entries contribute to debt relationships between agents
    - Each relationship must have equal and opposite entries in two agents' books
    """
    # T-account: always balance debit = credit
    if type == "debit"
        account.debit += amount
    else  # credit
        account.credit += amount
    end

    # Record transaction
    push!(account.transactions, Dict(
        "date" => date,
        "amount" => amount,
        "type" => type
    ))
end

# Record transaction in results DataFrame
function record_transaction!(landscape::MOMALandscape, date::Date, agent::String,
    account::String, amount::Float64)
    # Get current account
    acct = landscape.agents[agent].accounts[account]

    # For macro bookings, we only record the net effect on each agent's account
    # This represents the micro booking in that agent's T-account
    push!(landscape.results, (
        date,
        agent,
        account,
        acct.debit,  # Current debit balance
        acct.credit, # Current credit balance
        acct.debit - acct.credit  # Net position from agent's perspective
    ))
end

# Check micro invariance for an agent (all debits = all credits within each agent)
function check_micro_invariance(agent::Dict)
    """
    Micro Invariance: Within each agent's books, all debits must equal all credits.
    This is the fundamental principle of double-entry bookkeeping at the micro level.
    Every transaction affects two accounts, maintaining this balance.
    """
    total_debits = 0.0
    total_credits = 0.0

    # Sum over ALL accounts in micro accounting
    for (_, account) in agent.accounts
        total_debits += account.debit
        total_credits += account.credit
    end

    return isapprox(total_debits, total_credits, atol=1e-10)
end

# Check macro invariance (debtor-creditor pairs must cancel out)
function check_macro_invariance(landscape::MOMALandscape)
    """
    Macro Invariance: At the system level, all debt relationships must net to zero.
    This emerges from the fact that every debt has exactly one debtor and one creditor.

    Key insight: While individual agents see debits and credits in their books,
    at the macro level these are just two sides of the same relationship.
    There is no "net debt" in the system - only redistributions between agents.
    """
    # Define corresponding debtor-creditor account pairs
    # Each pair represents a complete debt relationship that must net to zero
    debt_pairs = [
        # Bank-Bank relationships (deposits)
        ("Deposits at Banks", "Deposits from Banks"),
        ("Deposits at Bankb", "Deposits from Bankb"),
        # Loan relationships
        ("Loans to Banks", "Loans from CB"),
        ("Loans to Bankb", "Loans from CB"),
        # BOE relationships
        ("Receivable from BOE", "Liability from BOE"),
        # General claims
        ("Receivable General", "Liability General")
    ]

    # For each debt relationship, verify that claims and liabilities cancel out
    for (claim_account, liability_account) in debt_pairs
        total_relationship = 0.0

        # Sum over all agents' positions in this debt relationship
        for (_, agent) in landscape.agents
            for (name, account) in agent.accounts
                if name == claim_account
                    # Add claim (positive position)
                    total_relationship += (account.debit - account.credit)
                elseif name == liability_account
                    # Add liability (negative position)
                    total_relationship += (account.debit - account.credit)
                end
            end
        end

        # Each debt relationship must net to zero at macro level
        if !isapprox(total_relationship, 0.0, atol=1e-10)
            error("Macro invariance violated: $claim_account and $liability_account do not net to zero. " *
                  "At macro level, every debt must have exactly one debtor and one creditor.")
        end
    end

    return true
end

# BOE (Bills of Exchange) specific macro invariance check
function check_boe_macro_invariance(landscape::MOMALandscape)
    """
    Check macro invariance specifically for BOE relationships.

    BOE creates a chain of claims that must net to zero at macro level:
    1. Initial BOE creation: B owes S (direct relationship)
    2. Bank transfer: Banks hold BOE claims, offsetting original relationship
    3. Final settlement: All BOE claims are settled through bank reserves

    At each stage, the sum of all BOE-related claims must be zero.
    """
    total_boe_position = 0.0

    # Sum all BOE-related accounts across agents
    for (_, agent) in landscape.agents
        for (name, account) in agent.accounts
            if name == "Receivable from BOE"
                total_boe_position += (account.debit - account.credit)
            elseif name == "Liability from BOE"
                total_boe_position += (account.debit - account.credit)
            end
        end
    end

    if !isapprox(total_boe_position, 0.0, atol=1e-10)
        error("BOE macro invariance violated: BOE claims do not net to zero")
    end

    return true
end

# Modified run_simulation! to provide better error messages about debt relationships
function run_simulation!(landscape::MOMALandscape)
    # Sort events by date
    sort!(landscape.events, by=x -> x["date"])

    # Process each event
    for event in landscape.events
        process_event!(landscape, event)

        # Check micro invariance for affected agents
        affected_agents = Set{String}()
        if event["type"] == "money_creation"
            push!(affected_agents, "CB")
        elseif event["type"] == "loans"
            push!(affected_agents, "CB", "Banks", "Bankb")
        elseif event["type"] == "bicycle_purchase"
            push!(affected_agents, "B", "S")
        elseif event["type"] == "boe_creation"
            push!(affected_agents, "S", "B")
        elseif event["type"] == "boe_bank_transfer"
            if event["agent"] == "Banks"
                push!(affected_agents, "Banks", "S")
            else
                push!(affected_agents, "Bankb", "Banks")
            end
        elseif event["type"] == "settlement"
            push!(affected_agents, "Banks", "Bankb")
        end

        # Check micro invariance (all accounts must balance) for each affected agent
        for agent_name in affected_agents
            if !check_micro_invariance(landscape.agents[agent_name])
                error("Micro invariance violated for agent $agent_name after $(event["type"]) event: Internal books must balance")
            end
        end

        # Check macro invariance (each debt relationship must net to zero)
        try
            check_macro_invariance(landscape)
        catch e
            error("After $(event["type"]) event: $(e.msg)")
        end
    end

    return landscape
end

# Modified generate_balance_sheet to use colimit properties
function generate_balance_sheet(landscape::MOMALandscape, agent_name::String)
    agent = landscape.agents[agent_name]

    # Verify micro invariance before generating balance sheet
    if !check_micro_invariance(agent)
        error("Cannot generate balance sheet: Micro invariance violated for agent $agent_name")
    end

    # Create assets and liabilities DataFrames based on account normal balances
    assets = DataFrame(
        account=String[],
        balance=Float64[]
    )

    liabilities = DataFrame(
        account=String[],
        balance=Float64[]
    )

    # Categorize accounts based on their normal balance
    # Assets: Debit > Credit
    # Liabilities: Credit > Debit
    for (name, account) in agent.accounts
        balance = account.debit - account.credit
        if name in ["Paper Money", "Loans to Banks", "Loans to Bankb", "CB Reserve",
            "Receivable from BOE", "Deposits at Banks", "Deposits at Bankb",
            "Bicycle", "Receivable General"]
            push!(assets, (name, abs(balance)))
        else
            push!(liabilities, (name, abs(balance)))
        end
    end

    # Calculate totals
    total_assets = nrow(assets) > 0 ? sum(assets.balance) : 0.0
    total_liabilities = nrow(liabilities) > 0 ? sum(liabilities.balance) : 0.0

    # Verify that balance sheet balances (another form of micro invariance)
    if !isapprox(total_assets - total_liabilities, sum(balance for (_, account) in agent.accounts
                                                       for balance in [account.debit - account.credit]), atol=1e-10)
        error("Balance sheet does not match T-account balances for agent $agent_name")
    end

    return Dict(
        "assets" => assets,
        "liabilities" => liabilities,
        "total_assets" => total_assets,
        "total_liabilities" => total_liabilities,
        "net_worth" => total_assets - total_liabilities
    )
end

"""
    create_event_sequence(events::Vector{Event})

Creates a sequence of financial events that forms a functor:
\$\$F: \\mathcal{C}(t) \\to \\mathcal{C}(t+1)\$\$

The sequence must preserve:
1. Object structure: \$F(A) = A'\$
2. Morphism structure: \$F(f: A \\to B) = f': A' \\to B'\$
3. Composition: \$F(g \\circ f) = F(g) \\circ F(f)\$
"""
function create_event_sequence(events::Vector{Event})
    # Implementation
end

"""
    compose_events(seq1::EventSequence, seq2::EventSequence)

Implements the composition of event sequences according to MES 2007:
\$\$F_{t+1,t+2} \\circ F_{t,t+1} = F_{t,t+2}\$\$

This composition must satisfy:
1. Associativity
2. Identity preservation
3. Structural coherence
"""
function compose_events(seq1::EventSequence, seq2::EventSequence)
    # Implementation
end

"""
    verify_event_closure(sequence::EventSequence)

Verifies that an event sequence satisfies the closure properties:
1. Pattern preservation: \$F(P) = P'\$
2. Colimit preservation: \$F(\\text{colim}(P)) = \\text{colim}(F(P))\$
3. Memory coherence: \$M_{t+1} = F(M_t, P_t)\$
"""
function verify_event_closure(sequence::EventSequence)
    # Implementation
end

"""
    create_macro_event(micro_events::Vector{Event})

Creates a macro-level event from micro-level events through colimit:
\$\$\\text{MacroEvent} = \\text{colim}(\\{\\text{MicroEvents}\\})\$\$

This implements the emergence principle where:
1. Multiple micro patterns can yield same macro state
2. Macro state maintains coherence with micro evolution
"""
function create_macro_event(micro_events::Vector{Event})
    # Implementation
end

"""
    verify_multiplicity_principle(diagram::MacroEventDiagram)

Verifies the multiplicity principle from MES 2007:
\$\$\\exists P, Q \\text{ such that } \\text{colim}(P) = \\text{colim}(Q)\$\$

This ensures that:
1. Different micro configurations can yield same macro state
2. System maintains robustness through degeneracy
"""
function verify_multiplicity_principle(diagram::MacroEventDiagram)
    # Implementation
end

"""
    detect_fractures(landscape::MOMALandscape)

Identifies points where macro invariance is broken, corresponding to
MES fractures where local and global views diverge.

Returns a Dict mapping each fracture to its imbalance amount.
"""
function detect_fractures(landscape::MOMALandscape)
    fractures = Dict{String,Float64}()

    # Define corresponding debtor-creditor account pairs
    debt_pairs = [
        ("Deposits at Banks", "Deposits from Banks"),
        ("Deposits at Bankb", "Deposits from Bankb"),
        ("Loans to Banks", "Loans from CB"),
        ("Loans to Bankb", "Loans from CB"),
        ("Receivable from BOE", "Liability from BOE"),
        ("Receivable General", "Liability General")
    ]

    # Check each debt relationship for imbalances
    for (claim_account, liability_account) in debt_pairs
        total_relationship = 0.0

        # Sum over all agents' positions
        for (_, agent) in landscape.agents
            for (name, account) in agent.accounts
                if name == claim_account
                    total_relationship += (account.debit - account.credit)
                elseif name == liability_account
                    total_relationship += (account.debit - account.credit)
                end
            end
        end

        # If relationship doesn't net to zero, it's a fracture
        if !isapprox(total_relationship, 0.0, atol=1e-10)
            fractures["$claim_account ↔ $liability_account"] = total_relationship
        end
    end

    return fractures
end

"""
    resynchronize!(landscape::MOMALandscape)

Attempts to restore macro invariance by processing settlement events
for detected fractures. This implements the MES resynchronization process
where system coherence is restored.
"""
function resynchronize!(landscape::MOMALandscape)
    # Detect current fractures
    fractures = detect_fractures(landscape)

    # No fractures - system is synchronized
    if isempty(fractures)
        return true
    end

    # Process each fracture
    for (relationship, imbalance) in fractures
        # Extract account names from relationship string
        claim_account, liability_account = split(relationship, " ↔ ")

        # Find agents involved in the fracture
        claim_agent = nothing
        liability_agent = nothing

        for (name, agent) in landscape.agents
            for (acc_name, _) in agent.accounts
                if acc_name == claim_account
                    claim_agent = name
                elseif acc_name == liability_account
                    liability_agent = name
                end
            end
        end

        # Create settlement event
        if !isnothing(claim_agent) && !isnothing(liability_agent)
            settlement_event = Dict(
                "type" => "settlement",
                "date" => today(),
                "amount" => abs(imbalance),
                "claim_agent" => claim_agent,
                "liability_agent" => liability_agent
            )

            # Process settlement
            process_event!(landscape, settlement_event)
        end
    end

    # Verify all fractures resolved
    return isempty(detect_fractures(landscape))
end

"""
    verify_resolution_paths(landscape::MOMALandscape, fracture::Dict)

Verifies that different settlement paths can resolve the same fracture,
implementing the MES multiplicity principle in resolution mechanisms.
"""
function verify_resolution_paths(landscape::MOMALandscape, fracture::Dict)
    # Clone landscape for testing different paths
    landscape1 = deepcopy(landscape)
    landscape2 = deepcopy(landscape)

    # Path 1: Direct bank transfer
    direct_transfer = Dict(
        "type" => "settlement",
        "date" => today(),
        "amount" => fracture["amount"],
        "agent" => "Banks"
    )
    process_event!(landscape1, direct_transfer)

    # Path 2: Central bank clearing
    cb_clearing = Dict(
        "type" => "settlement",
        "date" => today(),
        "amount" => fracture["amount"],
        "agent" => "CB"
    )
    process_event!(landscape2, cb_clearing)

    # Both paths should resolve fractures
    fractures1 = detect_fractures(landscape1)
    fractures2 = detect_fractures(landscape2)

    # Verify both paths achieve same macro state
    return isempty(fractures1) && isempty(fractures2)
end

"""
    process_boe_debit!(landscape::MOMALandscape, event::Dict)

Processes a BOE debit entry and generates possible credit resolutions:
1. Books initial debit entry
2. Memory generates possible credit counterparts
3. Each possibility maintains macro invariance
"""
function process_boe_debit!(landscape::MOMALandscape, event::Dict)
    # 1. Book initial debit entry
    from_bank = landscape.agents[event["from"]]
    amount = event["amount"]

    update_account!(from_bank.accounts["Receivable from BOE"],
        amount, "debit", event["date"])

    # 2. Generate possible credit resolutions
    possible_credits = Dict{String,Vector{Dict}}()

    # Pattern-based possibilities
    possible_credits["direct"] = [
        Dict(
            "agent" => event["to"],
            "account" => "Liability from BOE",
            "amount" => amount
        )
    ]

    # Complex link based possibilities
    possible_credits["indirect"] = [
        Dict(
            "agent" => "Banks",
            "account" => "Liability from BOE",
            "amount" => amount
        ),
        Dict(
            "agent" => "Bankb",
            "account" => "Liability from BOE",
            "amount" => amount
        )
    ]

    # Settlement based possibilities
    possible_credits["settlement"] = [
        Dict(
            "agent" => event["from"],
            "account" => "CB Reserve",
            "amount" => amount
        )
    ]

    # 3. Verify each possibility maintains invariance
    valid_possibilities = Dict{String,Vector{Dict}}()

    for (resolution_type, credits) in possible_credits
        # Clone landscape to test each possibility
        test_landscape = deepcopy(landscape)

        # Apply credits
        for credit in credits
            agent = test_landscape.agents[credit["agent"]]
            update_account!(agent.accounts[credit["account"]],
                credit["amount"], "credit", event["date"])
        end

        # Check if this possibility maintains invariance
        if check_macro_invariance(test_landscape)
            valid_possibilities[resolution_type] = credits
        end
    end

    return Dict(
        "debit_booked" => Dict(
            "agent" => event["from"],
            "account" => "Receivable from BOE",
            "amount" => amount
        ),
        "possible_credits" => valid_possibilities
    )
end

"""
    verify_possibility_principle(landscape::MOMALandscape, debit::Dict)

Verifies that multiple credit possibilities can resolve the same debit,
implementing the MES multiplicity principle in accounting resolutions.
"""
function verify_possibility_principle(landscape::MOMALandscape, debit::Dict)
    # Get all possible credit resolutions
    possibilities = process_boe_debit!(landscape, debit)

    # Each valid possibility should:
    # 1. Balance the debit entry
    # 2. Maintain macro invariance
    # 3. Lead to valid patterns

    valid_count = 0
    for (_, credits) in possibilities["possible_credits"]
        test_landscape = deepcopy(landscape)

        # Apply credits
        for credit in credits
            agent = test_landscape.agents[credit["agent"]]
            update_account!(agent.accounts[credit["account"]],
                credit["amount"], "credit", debit["date"])
        end

        # Verify this possibility
        if check_macro_invariance(test_landscape) &&
           !isempty(detect_current_patterns(test_landscape))
            valid_count += 1
        end
    end

    # Multiple valid possibilities should exist
    return valid_count > 1
end

end # module MOMAEvents
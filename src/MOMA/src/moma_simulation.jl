module MOMASimulation

using Dates
using DataFrames

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

# Create agent categories
mutable struct Agent
    name::String
    accounts::Dict{String,Account}
end

# Create landscape for MOMA simulation
mutable struct MOMALandscape
    parameters::Dict{String,Any}
    agents::Dict{String,Agent}
    accounts::Dict{String,Account}
    events::Vector{Dict}
    results::DataFrame
end

# Initialize simulation
function create_moma_simulation()
    # Define parameters
    parameters = Dict(
        "initial_money" => 1000.0,
        "loan_amount" => 200.0,
        "bicycle_price" => 100.0,
        "interest_rate" => 0.05,
        "start_date" => Date("2025-01-15")
    )

    # Create agents
    agents = Dict(
        "CB" => Agent("CentralBank", Dict()),
        "Banks" => Agent("SellerBank", Dict()),
        "Bankb" => Agent("BuyerBank", Dict()),
        "S" => Agent("Seller", Dict()),
        "B" => Agent("Buyer", Dict())
    )

    # Create accounts for each agent
    for (name, agent) in agents
        agent.accounts = create_agent_accounts(name)
    end

    # Create a dictionary to store all accounts
    accounts = Dict()
    for (agent_name, agent) in agents
        for (account_name, account) in agent.accounts
            accounts["$(agent_name)_$(account_name)"] = account
        end
    end

    # Define events
    events = [
        Dict(
            "date" => Date("2025-01-15"),
            "type" => "money_creation",
            "agent" => "CB",
            "accounts" => ["Paper Money", "Paper Money in Circulation"],
            "amount" => parameters["initial_money"]
        ),
        Dict(
            "date" => Date("2025-01-15"),
            "type" => "loans",
            "agent" => "CB",
            "accounts" => ["Loans to Banks", "Loans to Bankb", "Deposits from Banks", "Deposits from Bankb"],
            "amount" => parameters["loan_amount"]
        ),
        Dict(
            "date" => Date("2025-02-15"),
            "type" => "bicycle_purchase",
            "agent" => "B",
            "accounts" => ["Bicycle", "Liability General"],
            "amount" => parameters["bicycle_price"]
        ),
        Dict(
            "date" => Date("2025-03-15"),
            "type" => "boe_creation",
            "agent" => "S",
            "accounts" => ["Receivable from BOE", "Liability from BOE"],
            "amount" => parameters["bicycle_price"]
        ),
        Dict(
            "date" => Date("2025-04-15"),
            "type" => "boe_bank_transfer",
            "agent" => "Banks",
            "accounts" => ["Receivable from BOE", "Deposits from S"],
            "amount" => parameters["bicycle_price"]
        ),
        Dict(
            "date" => Date("2025-05-15"),
            "type" => "boe_bank_transfer",
            "agent" => "Bankb",
            "accounts" => ["Receivable from BOE", "Deposits from Banks"],
            "amount" => parameters["bicycle_price"]
        ),
        Dict(
            "date" => Date("2025-06-15"),
            "type" => "settlement",
            "agent" => "Banks",
            "accounts" => ["Deposits at Bankb", "CB Reserve"],
            "amount" => parameters["bicycle_price"]
        )
    ]

    # Create results DataFrame
    results = DataFrame(
        date=Date[],
        agent=String[],
        account=String[],
        debit=Float64[],
        credit=Float64[],
        balance=Float64[]
    )

    return MOMALandscape(parameters, agents, accounts, events, results)
end

# Create accounts for each agent
function create_agent_accounts(agent_name)
    accounts = Dict()

    if agent_name == "CB"
        accounts["Paper Money"] = Account("Paper Money")
        accounts["Paper Money in Circulation"] = Account("Paper Money in Circulation")
        accounts["Loans to Banks"] = Account("Loans to Banks")
        accounts["Loans to Bankb"] = Account("Loans to Bankb")
        accounts["Deposits from Banks"] = Account("Deposits from Banks")
        accounts["Deposits from Bankb"] = Account("Deposits from Bankb")
    elseif agent_name == "Banks"
        accounts["CB Reserve"] = Account("CB Reserve")
        accounts["Receivable from BOE"] = Account("Receivable from BOE")
        accounts["Deposits from S"] = Account("Deposits from S")
        accounts["Deposits at Bankb"] = Account("Deposits at Bankb")
        accounts["Deposits from Bankb"] = Account("Deposits from Bankb")
        accounts["Loans from CB"] = Account("Loans from CB")
    elseif agent_name == "Bankb"
        accounts["CB Reserve"] = Account("CB Reserve")
        accounts["Receivable from BOE"] = Account("Receivable from BOE")
        accounts["Deposits from Banks"] = Account("Deposits from Banks")
        accounts["Deposits at Banks"] = Account("Deposits at Banks")
        accounts["Loans from CB"] = Account("Loans from CB")
    elseif agent_name == "S"
        accounts["Bicycle"] = Account("Bicycle")
        accounts["Receivable General"] = Account("Receivable General")
        accounts["Liability General"] = Account("Liability General")
        accounts["Receivable from BOE"] = Account("Receivable from BOE")
        accounts["Liability from BOE"] = Account("Liability from BOE")
        accounts["Deposits at Banks"] = Account("Deposits at Banks")
    elseif agent_name == "B"
        accounts["Bicycle"] = Account("Bicycle")
        accounts["Receivable General"] = Account("Receivable General")
        accounts["Liability General"] = Account("Liability General")
        accounts["Receivable from BOE"] = Account("Receivable from BOE")
        accounts["Liability from BOE"] = Account("Liability from BOE")
    end

    return accounts
end

# Export necessary components
export MOMALandscape, Agent, Account, create_moma_simulation, create_agent_accounts

end # module MOMASimulation
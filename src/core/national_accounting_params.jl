using ..MES
using ..Category
using ..Types
using ..NationalAccounting
using Random
using Distributions

"""
    EconomicParameters

Parameters for economic agents and relationships.
"""
struct EconomicParameters
    # Agent parameters
    n_households::Int
    n_firms::Int
    n_banks::Int

    # Economic parameters
    initial_gdp::Float64
    initial_inflation::Float64
    initial_interest_rate::Float64
    initial_wages::Float64
    initial_profits::Float64

    # Behavioral parameters
    consumption_propensity::Float64
    investment_propensity::Float64
    savings_rate::Float64
    price_elasticity::Float64

    # Stochastic parameters
    gdp_growth_rate::Float64
    gdp_volatility::Float64
    inflation_target::Float64
    inflation_volatility::Float64
end

"""
    AgentState

State of an individual economic agent.
"""
struct AgentState
    id::Int
    type::String
    wealth::Float64
    income::Float64
    consumption::Float64
    investment::Float64
    savings::Float64
    debt::Float64
    assets::Float64
end

"""
    MarketState

State of a market or sector.
"""
struct MarketState
    id::Int
    type::String
    price_level::Float64
    quantity::Float64
    demand::Float64
    supply::Float64
    equilibrium_price::Float64
end

"""
    generate_agent_states(params::EconomicParameters)

Generates initial states for all economic agents.
"""
function generate_agent_states(params::EconomicParameters)
    states = Dict{String,Vector{AgentState}}()

    # Generate household states
    household_states = Vector{AgentState}()
    for i in 1:params.n_households
        wealth = rand(Normal(params.initial_gdp / params.n_households, 0.1))
        income = rand(Normal(params.initial_wages, 0.1))
        push!(household_states, AgentState(
            i, "household", wealth, income, 0.0, 0.0, 0.0, 0.0, wealth
        ))
    end

    # Generate firm states
    firm_states = Vector{AgentState}()
    for i in 1:params.n_firms
        wealth = rand(Normal(params.initial_gdp / params.n_firms, 0.1))
        income = rand(Normal(params.initial_profits, 0.1))
        push!(firm_states, AgentState(
            i, "firm", wealth, income, 0.0, 0.0, 0.0, 0.0, wealth
        ))
    end

    # Generate bank states
    bank_states = Vector{AgentState}()
    for i in 1:params.n_banks
        wealth = rand(Normal(params.initial_gdp / params.n_banks, 0.1))
        income = rand(Normal(params.initial_interest_rate, 0.1))
        push!(bank_states, AgentState(
            i, "bank", wealth, income, 0.0, 0.0, 0.0, 0.0, wealth
        ))
    end

    states["households"] = household_states
    states["firms"] = firm_states
    states["banks"] = bank_states

    return states
end

"""
    generate_market_states(params::EconomicParameters)

Generates initial states for markets and sectors.
"""
function generate_market_states(params::EconomicParameters)
    states = Dict{String,Vector{MarketState}}()

    # Generate goods market
    goods_market = MarketState(
        1, "goods", 1.0, params.initial_gdp,
        params.initial_gdp * params.consumption_propensity,
        params.initial_gdp * (1 - params.consumption_propensity),
        1.0
    )

    # Generate financial market
    financial_market = MarketState(
        2, "financial", 1.0, params.initial_gdp,
        params.initial_gdp * params.savings_rate,
        params.initial_gdp * (1 - params.savings_rate),
        params.initial_interest_rate
    )

    states["goods"] = [goods_market]
    states["financial"] = [financial_market]

    return states
end

"""
    update_agent_states(states::Dict{String, Vector{AgentState}}, 
                       market_states::Dict{String, Vector{MarketState}},
                       params::EconomicParameters)

Updates agent states based on market conditions and behavioral parameters.
"""
function update_agent_states(states::Dict{String,Vector{AgentState}},
    market_states::Dict{String,Vector{MarketState}},
    params::EconomicParameters)
    # Update household states
    for household in states["households"]
        # Calculate consumption based on income and propensity
        household.consumption = household.income * params.consumption_propensity

        # Calculate savings
        household.savings = household.income - household.consumption

        # Update wealth
        household.wealth += household.savings
        household.assets = household.wealth
    end

    # Update firm states
    for firm in states["firms"]
        # Calculate investment based on profits and propensity
        firm.investment = firm.income * params.investment_propensity

        # Update wealth
        firm.wealth += firm.income - firm.investment
        firm.assets = firm.wealth
    end

    # Update bank states
    for bank in states["banks"]
        # Calculate interest income
        bank.income = bank.wealth * params.initial_interest_rate

        # Update wealth
        bank.wealth += bank.income
        bank.assets = bank.wealth
    end
end

"""
    update_market_states(market_states::Dict{String, Vector{MarketState}},
                        agent_states::Dict{String, Vector{AgentState}},
                        params::EconomicParameters)

Updates market states based on agent behavior and economic parameters.
"""
function update_market_states(market_states::Dict{String,Vector{MarketState}},
    agent_states::Dict{String,Vector{AgentState}},
    params::EconomicParameters)
    # Update goods market
    goods_market = market_states["goods"][1]
    total_consumption = sum(h.consumption for h in agent_states["households"])
    total_investment = sum(f.investment for f in agent_states["firms"])

    goods_market.demand = total_consumption + total_investment
    goods_market.supply = params.initial_gdp * (1 + rand(Normal(params.gdp_growth_rate, params.gdp_volatility)))
    goods_market.equilibrium_price = goods_market.price_level * (1 + rand(Normal(params.inflation_target, params.inflation_volatility)))

    # Update financial market
    financial_market = market_states["financial"][1]
    total_savings = sum(h.savings for h in agent_states["households"])
    total_investment = sum(f.investment for f in agent_states["firms"])

    financial_market.demand = total_savings
    financial_market.supply = total_investment
    financial_market.equilibrium_price = params.initial_interest_rate * (1 + rand(Normal(0.0, 0.01)))
end

"""
    generate_economic_data(params::EconomicParameters, steps::Int)

Generates economic data for the specified number of steps.
"""
function generate_economic_data(params::EconomicParameters, steps::Int)
    # Initialize states
    agent_states = generate_agent_states(params)
    market_states = generate_market_states(params)

    # Generate time series data
    data = Vector{Dict{String,Any}}()

    for step in 1:steps
        # Update states
        update_agent_states(agent_states, market_states, params)
        update_market_states(market_states, agent_states, params)

        # Record data
        step_data = Dict{String,Any}()

        # Aggregate agent data
        step_data["total_consumption"] = sum(h.consumption for h in agent_states["households"])
        step_data["total_investment"] = sum(f.investment for f in agent_states["firms"])
        step_data["total_savings"] = sum(h.savings for h in agent_states["households"])

        # Market data
        step_data["gdp"] = market_states["goods"][1].supply
        step_data["inflation"] = (market_states["goods"][1].equilibrium_price - 1.0) * 100
        step_data["interest_rate"] = market_states["financial"][1].equilibrium_price

        push!(data, step_data)
    end

    return data
end

# Example usage:
# params = EconomicParameters(
#     1000, 100, 10,  # n_households, n_firms, n_banks
#     1000.0, 2.0, 1.0, 50.0, 20.0,  # initial values
#     0.8, 0.2, 0.2, 0.5,  # behavioral parameters
#     0.02, 0.01, 2.0, 0.5  # stochastic parameters
# )
# data = generate_economic_data(params, 12) 
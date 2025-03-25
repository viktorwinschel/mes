using Pkg
Pkg.activate(".")

include("mes_types.jl")

"""
### Figure 1: Dynamical MES Model
An evolutive system is defined by a functor from the category defining the order of the timeline 
to the category of partial functors between small categories.
"""
function dynamical_mes_model(timeline::Vector{DateTime}, economic_data::Dict)
    """
    Implements the dynamical MES model as an evolutive system.

    Parameters:
    - timeline: Vector of time points
    - economic_data: Dictionary containing economic indicators

    Returns:
    - MESState with dynamical model structure
    """
    # Create functor H:T->ParCat
    functor = FunctorH{Dict{String,Any}}(
        [TimePoint(t) for t in timeline],
        Dict(TimePoint(t) => data for (t, data) in economic_data),
        Dict()
    )

    # Create initial state
    initial_state = economic_data[timeline[1]]

    # Create a default behavior stream (will be replaced later)
    default_behavior = BehaviorStream(
        initial_state,
        state -> state,
        state -> state
    )

    # Return MESState with default behavior
    return MESState(
        functor,
        initial_state,
        default_behavior,  # Changed from nothing to default_behavior
        SimulationLogger([])
    )
end

"""
### Figure 2: Reduced Form of MES
Illustrates the hierarchical structure of the MES (Memory Evolutive System) H, showing how objects 
are partitioned in a hierarchical manner.
"""
function reduced_form_mes(economic_system::Dict)
    """
    Implements the reduced form of the Monetary Model (MES).

    Parameters:
    - economic_system: Dictionary containing the economic system structure

    Returns:
    - MESState with reduced form structure
    """
    # Create timeline from economic system
    timeline = sort(collect(keys(economic_system)))

    functor = FunctorH{Dict{String,Any}}(
        [TimePoint(t) for t in timeline],
        Dict(TimePoint(t) => economic_system[t] for t in timeline),
        Dict()
    )

    # Define next state function (lambda to be defined)
    next_fn = state -> state  # Placeholder for actual computation

    # Define evaluation function (lambda to be defined)
    eval_fn = state -> state  # Placeholder for actual computation

    # Create initial state
    initial_state = economic_system[timeline[1]]

    # Create MES state with logging
    return MESState(functor, initial_state, next_fn, eval_fn)
end

"""
### Figure 3: Structural Complex Econometric Model
Shows how C is a multifaceted object colimit of both Q and P.
Demonstrates simple links (g: cQ0 → cQ) binding clusters and complex links that are weakly emergent at their level.
"""
function structural_econometric_model(quantitative_data::Dict, policy_data::Dict)
    """
    Implements the structural complex econometric model.

    Parameters:
    - quantitative_data: Dictionary containing quantitative economic data
    - policy_data: Dictionary containing policy-related data

    Returns:
    - MESState with structural model representation
    """
    # Create timeline from data
    timeline = sort(collect(keys(quantitative_data)))

    functor = FunctorH{Dict{String,Any}}(
        [TimePoint(t) for t in timeline],
        Dict(TimePoint(t) => merge(quantitative_data[t], policy_data[t]) for t in timeline),
        Dict()
    )

    # Define next state function (lambda to be defined)
    next_fn = state -> state  # Placeholder for actual computation

    # Define evaluation function (lambda to be defined)
    eval_fn = state -> state  # Placeholder for actual computation

    # Create initial state
    initial_state = merge(quantitative_data[timeline[1]], policy_data[timeline[1]])

    # Create MES state with logging
    return MESState(functor, initial_state, next_fn, eval_fn)
end

"""
### Figure 4: Hierarchical Folding
Illustrates the procedure Pr on H with objectives including:
- Adding external elements
- Suppressing or decomposing components
- Combining patterns into new emerging components
"""
function hierarchical_folding(model_components::Dict)
    """
    Implements the hierarchical folding process for model components.

    Parameters:
    - model_components: Dictionary containing model components to be folded

    Returns:
    - MESState with hierarchical structure
    """
    # Create timeline from components
    timeline = sort(collect(keys(model_components)))

    # Create functor with hierarchical structure
    functor = FunctorH(
        timeline,
        Dict(t => model_components[t] for t in timeline),
        Dict()
    )

    # Define next state function (lambda to be defined)
    next_fn = state -> state  # Placeholder for actual computation

    # Define evaluation function (lambda to be defined)
    eval_fn = state -> state  # Placeholder for actual computation

    # Create initial state
    initial_state = model_components[timeline[1]]

    # Create MES state with logging
    return MESState(functor, initial_state, next_fn, eval_fn)
end

"""
### Figure 5: Estimated Parameters
Shows how a cat-neuron of level 1 models a mental object O.
Demonstrates the activation of a synchronous pattern P of neurons as the "binding" (or colimit) cP of P.
"""
function estimate_parameters(model_data::Dict, estimation_method::String)
    """
    Implements parameter estimation for the model.

    Parameters:
    - model_data: Dictionary containing model data
    - estimation_method: String specifying the estimation method

    Returns:
    - MESState with estimated parameters
    """
    # Create timeline from model data
    timeline = sort(collect(keys(model_data)))

    # Create functor with parameter structure
    functor = FunctorH(
        timeline,
        Dict(t => model_data[t] for t in timeline),
        Dict()
    )

    # Define next state function (lambda to be defined)
    next_fn = state -> state  # Placeholder for actual computation

    # Define evaluation function (lambda to be defined)
    eval_fn = state -> state  # Placeholder for actual computation

    # Create initial state
    initial_state = model_data[timeline[1]]

    # Create MES state with logging
    return MESState(functor, initial_state, next_fn, eval_fn)
end

"""
### Figure 6: Memory and Model Representation
Shows the four main units of the Data Analyser (DA):
- Receptors unit with different kinds of receptors and effectors
- Communication between system and environment
"""
function model_memory(estimated_model::Dict, historical_data::Dict)
    """
    Implements the memory system for model representation.

    Parameters:
    - estimated_model: Dictionary containing the estimated model
    - historical_data: Dictionary containing historical data

    Returns:
    - MESState with memory representation
    """
    # Create timeline from historical data
    timeline = sort(collect(keys(historical_data)))

    # Create functor with memory structure
    functor = FunctorH(
        timeline,
        Dict(t => merge(estimated_model, historical_data[t]) for t in timeline),
        Dict()
    )

    # Define next state function (lambda to be defined)
    next_fn = state -> state  # Placeholder for actual computation

    # Define evaluation function (lambda to be defined)
    eval_fn = state -> state  # Placeholder for actual computation

    # Create initial state
    initial_state = merge(estimated_model, historical_data[timeline[1]])

    # Create MES state with logging
    return MESState(functor, initial_state, next_fn, eval_fn)
end

"""
### Figure 7: Landscape
Illustrates how DA acts as a CR (Co-Regulator) by steps.
Shows the three parts of one step:
- Formation of the landscape
- Components that are links activating at least one element
"""
function model_landscape(memory_system::Dict, current_state::Dict)
    """
    Implements the landscape system for model analysis.

    Parameters:
    - memory_system: Dictionary containing the memory system
    - current_state: Dictionary containing current system state

    Returns:
    - MESState with landscape representation
    """
    # Create timeline from current state
    timeline = [Dates.now()]

    # Create functor with landscape structure
    functor = FunctorH(
        timeline,
        Dict(t => merge(memory_system, current_state) for t in timeline),
        Dict()
    )

    # Define next state function (lambda to be defined)
    next_fn = state -> state  # Placeholder for actual computation

    # Define evaluation function (lambda to be defined)
    eval_fn = state -> state  # Placeholder for actual computation

    # Create initial state
    initial_state = merge(memory_system, current_state)

    # Create MES state with logging
    return MESState(functor, initial_state, next_fn, eval_fn)
end

"""
### Figure 8: Interpretation of Structural Models
Shows how the activation of a pattern P of receptors is transported via the landscape.
Demonstrates the activation of a pattern P' in the processing unit.
Shows how the record of P becomes a colimit of P' added via a de/complexification process.
"""
function interpret_structural_model(structural_model::Dict, data_patterns::Dict)
    """
    Implements the interpretation of structural models in light of data.

    Parameters:
    - structural_model: Dictionary containing the structural model
    - data_patterns: Dictionary containing data patterns

    Returns:
    - MESState with structural model interpretation
    """
    # Create timeline from data patterns
    timeline = sort(collect(keys(data_patterns)))

    # Create functor with interpretation structure
    functor = FunctorH(
        timeline,
        Dict(t => merge(structural_model, data_patterns[t]) for t in timeline),
        Dict()
    )

    # Define next state function (lambda to be defined)
    next_fn = state -> state  # Placeholder for actual computation

    # Define evaluation function (lambda to be defined)
    eval_fn = state -> state  # Placeholder for actual computation

    # Create initial state
    initial_state = merge(structural_model, data_patterns[timeline[1]])

    # Create MES state with logging
    return MESState(functor, initial_state, next_fn, eval_fn)
end

"""
### Figure 9: Monetary Policy under MES
Shows how a group G of humans acts as a co-regulator of S.
Illustrates how DA enables better cooperation between people.
Demonstrates the formation of G-archetypal patterns of shared concepts.
"""
function monetary_policy_mes(interpreted_model::Dict, policy_parameters::Dict)
    """
    Implements monetary policy as a service under MES framework.

    Parameters:
    - interpreted_model: Dictionary containing the interpreted model
    - policy_parameters: Dictionary containing policy parameters

    Returns:
    - MESState with monetary policy service
    """
    # Create timeline from policy parameters
    timeline = [Dates.now()]

    # Create functor with policy structure
    functor = FunctorH(
        timeline,
        Dict(t => merge(interpreted_model, policy_parameters) for t in timeline),
        Dict()
    )

    # Define next state function (lambda to be defined)
    next_fn = state -> state  # Placeholder for actual computation

    # Define evaluation function (lambda to be defined)
    eval_fn = state -> state  # Placeholder for actual computation

    # Create initial state
    initial_state = merge(interpreted_model, policy_parameters)

    # Create MES state with logging
    return MESState(functor, initial_state, next_fn, eval_fn)
end

struct MacroBooking
    booking1::Dict{String,Any}  # First micro booking
    booking2::Dict{String,Any}  # Second micro booking
    timestamp::DateTime
    transaction_type::String
    clearing_status::String
end

function create_boe_model()
    # Complete timeline with all 6 events
    dates = Dict(
        "delivery" => DateTime(2024, 1, 1),    # Bicycle delivery
        "creation" => DateTime(2024, 2, 1),    # BoE created
        "seller_bank" => DateTime(2024, 3, 2), # Seller bank buys BoE
        "buyer_bank" => DateTime(2024, 4, 1),  # Buyer bank buys BoE
        "maturity" => DateTime(2024, 5, 1),   # Buyer pays
        "settlement" => DateTime(2024, 6, 2)  # Central bank settlement
    )

    # Initial balances and parameters
    parameters = Dict(
        "face_value" => 5000.0,
        "rates" => Dict(
            "central_bank" => 0.01,  # 1% p.a.
            "commercial" => 0.10     # 10% p.a.
        ),
        "initial_balances" => Dict(
            "central_bank" => Dict("cash" => 10000.0, "equity" => 10000.0),
            "seller_bank" => Dict("cash" => 5000.0, "equity" => 5000.0),
            "buyer_bank" => Dict("cash" => 5000.0, "equity" => 5000.0)
        )
    )

    # Balance sheets for tracking
    balance_sheets = Dict(
        "central_bank" => Dict(
            "assets" => Dict("cash" => 10000.0),
            "liabilities" => Dict(),
            "equity" => Dict("capital" => 10000.0, "retained_earnings" => 0.0)
        ),
        "seller_bank" => Dict(
            "assets" => Dict("cash" => 5000.0),
            "liabilities" => Dict(),
            "equity" => Dict("capital" => 5000.0, "retained_earnings" => 0.0)
        ),
        "buyer_bank" => Dict(
            "assets" => Dict("cash" => 5000.0),
            "liabilities" => Dict(),
            "equity" => Dict("capital" => 5000.0, "retained_earnings" => 0.0)
        )
    )

    return Dict(
        "dates" => dates,
        "parameters" => parameters,
        "balance_sheets" => balance_sheets,
        "status" => "initialized",
        "current_holder" => "seller",
        "current_date" => dates["delivery"]
    )
end

function next_fn(state::Dict)
    """
    State transition function for the bill of exchange model.
    """
    new_state = deepcopy(state)
    current_date = new_state["current_date"]
    dates = new_state["dates"]

    if current_date == dates["delivery"]
        # Bicycle delivery - no financial impact
        new_state["status"] = "delivered"
        new_state["current_holder"] = "seller"

    elseif current_date == dates["creation"]
        # Create BoE - calculate present value
        face_value = new_state["parameters"]["face_value"]
        rate = new_state["parameters"]["rates"]["commercial"]
        time_to_maturity = (dates["maturity"] - current_date).value / (365 * 24 * 60 * 60)
        pv = face_value / (1 + rate * time_to_maturity)

        new_state["calculations"] = Dict(
            "seller_bank_purchase" => Dict(
                "face_value" => face_value,
                "purchase_value" => pv,
                "discount" => face_value - pv
            )
        )
        new_state["status"] = "created"
        new_state["current_holder"] = "seller_bank"

    elseif current_date == dates["seller_bank"]
        # Seller bank buys BoE - calculate interbank spread
        face_value = new_state["parameters"]["face_value"]
        central_bank_pv = calculate_pv(
            face_value,
            new_state["parameters"]["rates"]["central_bank"],
            current_date,
            dates["maturity"]
        )

        # Calculate earnings distribution
        seller_bank_purchase = new_state["calculations"]["seller_bank_purchase"]["purchase_value"]
        total_discount = face_value - central_bank_pv
        central_bank_earning = face_value - central_bank_pv
        commercial_spread = central_bank_pv - seller_bank_purchase
        bank_earning = commercial_spread / 2  # Split between seller and buyer bank

        new_state["calculations"]["earnings"] = Dict(
            "central_bank" => central_bank_earning,
            "seller_bank" => bank_earning,
            "buyer_bank" => bank_earning
        )
        new_state["current_holder"] = "buyer_bank"

    elseif current_date == dates["buyer_bank"]
        # Buyer bank buys BoE - calculate interbank spread
        face_value = new_state["parameters"]["face_value"]
        central_bank_pv = calculate_pv(
            face_value,
            new_state["parameters"]["rates"]["central_bank"],
            current_date,
            dates["maturity"]
        )

        # Calculate earnings distribution
        seller_bank_purchase = new_state["calculations"]["seller_bank_purchase"]["purchase_value"]
        total_discount = face_value - central_bank_pv
        central_bank_earning = face_value - central_bank_pv
        commercial_spread = central_bank_pv - seller_bank_purchase
        bank_earning = commercial_spread / 2  # Split between seller and buyer bank

        new_state["calculations"]["earnings"] = Dict(
            "central_bank" => central_bank_earning,
            "seller_bank" => bank_earning,
            "buyer_bank" => bank_earning
        )
        new_state["current_holder"] = "buyer_bank"

    elseif current_date == dates["maturity"]
        # Maturity - book earnings to equity
        earnings = new_state["calculations"]["earnings"]

        # Update balance sheets with earnings
        for (bank, earning) in earnings
            new_state["balance_sheets"][bank]["equity"]["retained_earnings"] += earning
        end
        new_state["status"] = "matured"

    elseif current_date == dates["settlement"]
        # Final settlement - transfer cash between accounts
        new_state["status"] = "settled"
    end

    return new_state
end

function print_boe_log(log::Vector)
    println("\nBill of Exchange Transaction Log:")
    println("================================")

    for (timestamp, event, data) in log
        println("\n=== $(Dates.format(timestamp, "yyyy-mm-dd")) : $(data["status"]) ===")

        if haskey(data, "calculations")
            if haskey(data["calculations"], "seller_bank_purchase")
                purchase = data["calculations"]["seller_bank_purchase"]
                println("\nSeller Bank Purchase:")
                println("  Face Value: €", round(purchase["face_value"], digits=2))
                println("  Purchase Value: €", round(purchase["purchase_value"], digits=2))
                println("  Initial Discount: €", round(purchase["discount"], digits=2))
            end

            if haskey(data["calculations"], "earnings")
                println("\nEarnings Distribution:")
                for (party, amount) in data["calculations"]["earnings"]
                    println("  $party: €", round(amount, digits=2))
                end
            end
        end

        # Print balance sheets at maturity
        if data["status"] == "matured"
            println("\nFinal Balance Sheet Positions:")
            for (bank, balance) in data["balance_sheets"]
                println("\n$bank:")
                println("  Capital: €", round(balance["equity"]["capital"], digits=2))
                println("  Retained Earnings: €", round(balance["equity"]["retained_earnings"], digits=2))
                println("  Total Equity: €", round(
                    balance["equity"]["capital"] + balance["equity"]["retained_earnings"],
                    digits=2
                ))
            end
        end
    end
end

# Add this function to run the simulation through all events
function run_boe_simulation()
    # Initialize model and log
    state = create_boe_model()
    log = Vector{Tuple{DateTime,String,Dict{String,Any}}}()

    # Get timeline from dates
    dates = state["dates"]
    timeline = [
        dates["delivery"],
        dates["creation"],
        dates["seller_bank"],
        dates["buyer_bank"],
        dates["maturity"],
        dates["settlement"]
    ]

    # Run through each date
    for date in timeline
        # Update current date
        state["current_date"] = date

        # Get next state
        state = next_fn(state)

        # Log the state
        push!(log, (date, "event", state))
    end

    return log
end

# Replace the execution code with:
log = run_boe_simulation()
print_boe_log(log)

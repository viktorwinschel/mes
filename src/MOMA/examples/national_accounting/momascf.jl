# --------------------------------------------------------------------------------------------------------------------------------------------
# MoMaT
# Monetäre Makrobuchhaltung des Supply Chain Finance (MoMaSCF)
# Monetäre Makro Buchhaltung der Lieferkettenfinanzierung (MoMaLKF) 
# Wechselmarkt in D 1990: 50 Mrd DM p.a.
# aktuell: trade finance $10^12, davon 2/3 als open account, dh später zu bezahlen
# --------------------------------------------------------------------------------------------------------------------------------------------
using DataFrames    # für simulierte Zeitreihen
using Plots         # zur Visualisierung der simulierten Zeitreihen
using Parameters    # für die Initialisierung der Zustandsvariablen des struct
using CSV, JSON, Statistics, Dates

#=
MoMaSCF:
Agenten: 
cap: capitalist
com: company, producer
lab: labour, worker, household
res: resource, raw material supplier
bank: bank (zentralbank nicht nötig)
Konten:
VGR konten der makro buchhaltung: aktiv und passiv
invarianzen: forderungen und verbindlichkeiten
Buchungen:
der monetären Makrobuchhaltung ergeben sich aus den Buchungen der (doppleten) Mikrobuchhaltungen
auf den aktiven und passiven Konten der Makrobuchhaltung
aus den Forderungen und Verbindlichkeiten der Mikrobuchhaltungen
ergeben sich als Forderungen und Verbindlichkeiten die Makroinvarianzen
=#

# ------------------------------------------------------------------------------------------------------------
# Parameters
const PARAMETERS = (
    InvestmentLen=10,    # length of investments cycle
    LabResourceRatio=0.2,  # ratio of labor to resources in investment
    ConsumRatioRes=0.8,  # consumption ratio for resource owners
    ConsumRatioLab=0.95,    # consumption ratio for labor
    ConsumRatioCap=0.6,   # consumption ratio for capitalists
    MarkUp=0.5,              # price markup over costs
    DivRateDiff=0.15,    # dividend ratio from surplus
    DivRateBank=0.4,     # dividend ratio from balance
    WindFallProfit=0.5,      # ratio of surplus converted to profit
    sigA=20.0,    # base investment level
    sigB=480.0,  # investment response scale
    sigC=200.0,  # investment response sensitivity
    ResourcePrice=25.0,            # base resource price
    LaborPrice=12.0,               # base labor price
    InitialGoodPrice=30.0,        # initial good price
    LabResSubstProd=0.75,  # labor elasticity in production
    ScaleProd=0.42,          # production scale factor
    DecayGoodLab=0.95,     # decay rate of labor goods
    DecayGoodRes=0.7,   # decay rate of resource goods
    DecayGoodCap=0.6,    # decay rate of capital goods
    ReNewRes=100.0,    # resource renewal rate
    ReNewLab=100.0        # labor renewal rate
)
# ------------------------------------------------------------------------------------------------------------
# State mit initials 
@with_kw mutable struct State
    Parameters::Any                                                    # parameters  
    wageHist::Vector{Float64} = zeros(PARAMETERS.InvestmentLen)       # history of wage payments
    repayHist::Vector{Float64} = zeros(PARAMETERS.InvestmentLen)      # history of loan repayments             
    morning_efficiency::Float64 = 0.85                                # morning clearing efficiency
    evening_efficiency::Float64 = 0.90                                # evening clearing efficiency

    # Agent.Account naming convention: AGENT_ACCOUNT
    # Agents: LABOR, RESOURCE, COMPANY, CAPITAL, BANK
    # Accounts: BANK, STOCK, GOOD, LOAN, DIV

    # Labor accounts
    LABOR_BANK::Float64 = 0.0               # Labor's bank account balance
    LABOR_STOCK::Float64 = 0.0              # Labor's stock of available labor
    LABOR_GOOD::Float64 = 0.0               # Labor's goods inventory

    # Resource owner accounts
    RESOURCE_BANK::Float64 = 0.0            # Resource owner's bank account balance
    RESOURCE_STOCK::Float64 = 0.0           # Resource owner's resource stock
    RESOURCE_GOOD::Float64 = 0.0            # Resource owner's goods inventory

    # Company accounts
    COMPANY_BANK::Float64 = 0.0             # Company's bank account balance
    COMPANY_LOAN::Float64 = 0.0             # Company's loan liabilities
    COMPANY_DIV::Float64 = 0.0              # Company's dividend liabilities
    COMPANY_RESOURCE::Float64 = 20.0        # Company's resource inventory
    COMPANY_LABOR::Float64 = 110.0          # Company's labor stock
    COMPANY_GOOD::Float64 = 0.0             # Company's goods inventory

    # Capital accounts
    CAPITAL_BANK::Float64 = 0.0             # Capitalist's bank account balance
    CAPITAL_DIV::Float64 = 0.0              # Capitalist's dividend receivables
    CAPITAL_GOOD::Float64 = 0.0             # Capitalist's goods inventory

    # Bank accounts (bank's view of other agents' accounts)
    BANK_COMPANY_LOAN::Float64 = 0.0        # Bank's loans to company (asset)
    BANK_COMPANY_BANK::Float64 = 0.0        # Bank's liability to company
    BANK_LABOR_BANK::Float64 = 0.0          # Bank's liability to labor
    BANK_RESOURCE_BANK::Float64 = 0.0       # Bank's liability to resource owner
    BANK_CAPITAL_BANK::Float64 = 0.0        # Bank's liability to capitalist
end;
# ------------------------------------------------------------------------------------------------------------
# Utility functions for numerical stability
function clamp_value(x, min_val, max_val)
    return max(min_val, min(max_val, x))
end

function safe_divide(x, y, default=1.0)
    if y == 0.0 || !isfinite(y)
        return default
    end
    result = x / y
    return isfinite(result) ? result : default
end

# Categorical morphisms for conditional logic
struct ConditionalMorphism
    condition::Function
    true_morphism::Function
    false_morphism::Function
end

# Price Formation Morphisms
struct PriceFormationMorphisms
    initial_price::ConditionalMorphism
    demand_price::Function
    surplus_price::ConditionalMorphism
end

# Dividend Decision Morphisms
struct DividendDecisionMorphisms
    surplus_dividend::ConditionalMorphism
    bank_dividend::ConditionalMorphism
end

# Create price formation morphisms
function create_price_formation_morphisms(pars)
    initial_price = ConditionalMorphism(
        period -> period == 0,
        _ -> pars.InitialGoodPrice,
        _ -> 0.0
    )

    demand_price = (demand_plan, production) -> safe_divide(demand_plan, production)

    surplus_price = ConditionalMorphism(
        surplus -> surplus > 0.0,
        surplus -> surplus * pars.WindFallProfit,
        _ -> 0.0
    )

    PriceFormationMorphisms(initial_price, demand_price, surplus_price)
end

# Create dividend decision morphisms
function create_dividend_decision_morphisms(pars)
    surplus_dividend = ConditionalMorphism(
        diff -> diff > 0.0,
        diff -> diff * pars.DivRateDiff,
        _ -> 0.0
    )

    bank_dividend = ConditionalMorphism(
        balance -> balance > 0.0,
        balance -> balance * pars.DivRateBank,
        _ -> 0.0
    )

    DividendDecisionMorphisms(surplus_dividend, bank_dividend)
end

# Apply conditional morphism
function apply_conditional_morphism(morphism::ConditionalMorphism, value)
    if morphism.condition(value)
        morphism.true_morphism(value)
    else
        morphism.false_morphism(value)
    end
end

# Calculate price using categorical morphisms
function calculate_price(price_morphisms::PriceFormationMorphisms, period, demand_plan, production, demand_surplus)
    initial = apply_conditional_morphism(price_morphisms.initial_price, period)
    demand = price_morphisms.demand_price(demand_plan, production)
    surplus = apply_conditional_morphism(price_morphisms.surplus_price, demand_surplus)

    initial + demand + surplus
end

# Calculate dividend decision using categorical morphisms
function calculate_dividend_decision(dividend_morphisms::DividendDecisionMorphisms, loan_diff, bank_balance)
    # Calculate dividend based on loan difference
    dividend_from_diff = apply_conditional_morphism(
        dividend_morphisms.surplus_dividend,
        loan_diff
    )

    # Calculate dividend based on bank balance
    dividend_from_bank = apply_conditional_morphism(
        dividend_morphisms.bank_dividend,
        bank_balance
    )

    dividend_from_diff + dividend_from_bank
end

# In the StateTransition function, replace the direct calculations with morphism-based ones
function StateTransition(sim, state, period)
    pars = state.Parameters
    stateNew = State(Parameters=pars)

    # Create morphisms
    price_morphisms = create_price_formation_morphisms(pars)
    dividend_morphisms = create_dividend_decision_morphisms(pars)

    # Calculate net positions
    NET_POSITION_CAPITAL = state.CAPITAL_BANK - state.BANK_CAPITAL_BANK
    NET_POSITION_RESOURCE = state.RESOURCE_BANK - state.BANK_RESOURCE_BANK
    NET_POSITION_COMPANY = state.COMPANY_BANK - state.BANK_COMPANY_BANK
    NET_POSITION_LOAN = state.BANK_COMPANY_LOAN - state.COMPANY_LOAN
    NET_POSITION_LABOR = state.LABOR_BANK - state.BANK_LABOR_BANK
    NET_POSITION_MACRO = NET_POSITION_CAPITAL + NET_POSITION_RESOURCE + NET_POSITION_COMPANY + NET_POSITION_LOAN + NET_POSITION_LABOR

    # Calculate flows
    FLOW_PAYMENT_WAGE = sum(state.wageHist)
    FLOW_PAYMENT_RESOURCE = sum(state.repayHist)
    FLOW_PAYMENT_DIVIDEND = 0.0  # Initialize dividend payment

    FLOW_CONSUMPTION_RESOURCE = state.RESOURCE_BANK * pars.ConsumRatioRes
    FLOW_CONSUMPTION_LABOR = state.LABOR_BANK * pars.ConsumRatioLab
    FLOW_CONSUMPTION_CAPITAL = state.CAPITAL_BANK * pars.ConsumRatioCap
    FLOW_CONSUMPTION_TOTAL = FLOW_CONSUMPTION_RESOURCE + FLOW_CONSUMPTION_LABOR + FLOW_CONSUMPTION_CAPITAL

    # Production and demand
    FLOW_PRODUCTION_GOOD = 1 + pars.ScaleProd * state.COMPANY_LABOR^pars.LabResSubstProd * state.COMPANY_RESOURCE^(1 - pars.LabResSubstProd)
    FLOW_DEMAND_PLANNED = (FLOW_PAYMENT_WAGE + FLOW_PAYMENT_RESOURCE) * (1 + pars.MarkUp)
    FLOW_DEMAND_SURPLUS = FLOW_CONSUMPTION_TOTAL - FLOW_DEMAND_PLANNED

    # Price formation using categorical morphisms
    GoodPrice = calculate_price(
        price_morphisms,
        period,
        FLOW_DEMAND_PLANNED,
        FLOW_PRODUCTION_GOOD,
        FLOW_DEMAND_SURPLUS
    )

    # Investment flows
    FLOW_INVESTMENT_TOTAL = pars.sigA + pars.sigB / (1.0 + exp(-FLOW_DEMAND_SURPLUS / pars.sigC))
    FLOW_INVESTMENT_RESOURCE = FLOW_INVESTMENT_TOTAL * (1 - pars.LabResourceRatio)
    FLOW_INVESTMENT_LABOR = FLOW_INVESTMENT_TOTAL * pars.LabResourceRatio
    FLOW_PAYMENT_REPAYMENT = FLOW_INVESTMENT_TOTAL / pars.InvestmentLen

    # Update history
    stateNew.wageHist = [FLOW_INVESTMENT_LABOR; state.wageHist[1:end-1]]
    stateNew.repayHist = [FLOW_PAYMENT_REPAYMENT; state.repayHist[1:end-1]]

    # Update state variables
    stateNew.LABOR_BANK = state.LABOR_BANK + FLOW_PAYMENT_WAGE - FLOW_CONSUMPTION_LABOR
    stateNew.LABOR_STOCK = state.LABOR_STOCK + pars.ReNewLab - FLOW_PAYMENT_WAGE / pars.LaborPrice
    stateNew.LABOR_GOOD = state.LABOR_GOOD + FLOW_CONSUMPTION_LABOR / GoodPrice - state.LABOR_GOOD * pars.DecayGoodLab

    stateNew.RESOURCE_BANK = state.RESOURCE_BANK + FLOW_INVESTMENT_RESOURCE - FLOW_CONSUMPTION_RESOURCE
    stateNew.RESOURCE_STOCK = state.RESOURCE_STOCK + pars.ReNewRes - FLOW_INVESTMENT_RESOURCE / pars.ResourcePrice
    stateNew.RESOURCE_GOOD = state.RESOURCE_GOOD + FLOW_CONSUMPTION_RESOURCE / GoodPrice - state.RESOURCE_GOOD * pars.DecayGoodRes

    # Calculate loan difference for dividend decision
    LOAN_DIFF = state.BANK_COMPANY_LOAN - state.COMPANY_LOAN

    # Dividend decision using categorical morphisms
    DividendDecision = calculate_dividend_decision(
        dividend_morphisms,
        LOAN_DIFF,
        state.COMPANY_BANK
    )

    # Calculate dividend payment
    FLOW_PAYMENT_DIVIDEND = DividendDecision * pars.DivRateBank

    stateNew.COMPANY_BANK = state.COMPANY_BANK + (FLOW_INVESTMENT_TOTAL + FLOW_CONSUMPTION_TOTAL) -
                            (FLOW_INVESTMENT_RESOURCE + FLOW_PAYMENT_WAGE + FLOW_PAYMENT_DIVIDEND + FLOW_PAYMENT_REPAYMENT)
    stateNew.COMPANY_LOAN = state.COMPANY_LOAN + FLOW_INVESTMENT_TOTAL - FLOW_PAYMENT_REPAYMENT
    stateNew.COMPANY_DIV = state.COMPANY_DIV + DividendDecision - FLOW_PAYMENT_DIVIDEND
    stateNew.COMPANY_RESOURCE = state.COMPANY_RESOURCE + FLOW_INVESTMENT_RESOURCE / pars.ResourcePrice - state.COMPANY_RESOURCE
    stateNew.COMPANY_LABOR = state.COMPANY_LABOR + FLOW_PAYMENT_WAGE / pars.LaborPrice - state.COMPANY_LABOR
    stateNew.COMPANY_GOOD = state.COMPANY_GOOD + FLOW_PRODUCTION_GOOD - FLOW_CONSUMPTION_TOTAL / GoodPrice

    FLOW_DIVIDEND_INCOME = state.CAPITAL_DIV
    stateNew.CAPITAL_BANK = state.CAPITAL_BANK + FLOW_DIVIDEND_INCOME - FLOW_CONSUMPTION_CAPITAL
    stateNew.CAPITAL_DIV = state.CAPITAL_DIV + DividendDecision - FLOW_DIVIDEND_INCOME
    stateNew.CAPITAL_GOOD = state.CAPITAL_GOOD + FLOW_CONSUMPTION_CAPITAL / GoodPrice - state.CAPITAL_GOOD * pars.DecayGoodCap

    stateNew.BANK_COMPANY_LOAN = state.BANK_COMPANY_LOAN + FLOW_INVESTMENT_TOTAL - FLOW_PAYMENT_REPAYMENT
    stateNew.BANK_COMPANY_BANK = state.BANK_COMPANY_BANK + (FLOW_INVESTMENT_TOTAL + FLOW_CONSUMPTION_TOTAL) -
                                 (FLOW_INVESTMENT_RESOURCE + FLOW_PAYMENT_WAGE + FLOW_PAYMENT_DIVIDEND + FLOW_PAYMENT_REPAYMENT)
    stateNew.BANK_LABOR_BANK = state.BANK_LABOR_BANK + FLOW_PAYMENT_WAGE - FLOW_CONSUMPTION_LABOR
    stateNew.BANK_RESOURCE_BANK = state.BANK_RESOURCE_BANK + FLOW_INVESTMENT_RESOURCE - FLOW_CONSUMPTION_RESOURCE
    stateNew.BANK_CAPITAL_BANK = state.BANK_CAPITAL_BANK + FLOW_DIVIDEND_INCOME - FLOW_CONSUMPTION_CAPITAL

    # Calculate clearing efficiencies
    MORNING_FLOWS = FLOW_PAYMENT_WAGE + FLOW_INVESTMENT_RESOURCE
    MORNING_NETTED = MORNING_FLOWS * 0.85
    stateNew.morning_efficiency = 0.85

    EVENING_FLOWS = FLOW_CONSUMPTION_TOTAL
    EVENING_NETTED = EVENING_FLOWS * 0.90
    stateNew.evening_efficiency = 0.90

    # Record variables
    push!(sim, (
        Period=period,
        morning_efficiency=stateNew.morning_efficiency,
        evening_efficiency=stateNew.evening_efficiency,
        NET_POSITION_CAPITAL=NET_POSITION_CAPITAL,
        NET_POSITION_RESOURCE=NET_POSITION_RESOURCE,
        NET_POSITION_COMPANY=NET_POSITION_COMPANY,
        NET_POSITION_LOAN=NET_POSITION_LOAN,
        NET_POSITION_LABOR=NET_POSITION_LABOR,
        NET_POSITION_MACRO=NET_POSITION_MACRO,
        FLOW_CONSUMPTION_RESOURCE=FLOW_CONSUMPTION_RESOURCE,
        FLOW_CONSUMPTION_LABOR=FLOW_CONSUMPTION_LABOR,
        FLOW_CONSUMPTION_CAPITAL=FLOW_CONSUMPTION_CAPITAL,
        FLOW_CONSUMPTION_TOTAL=FLOW_CONSUMPTION_TOTAL,
        FLOW_DEMAND_PLANNED=FLOW_DEMAND_PLANNED,
        FLOW_DEMAND_SURPLUS=FLOW_DEMAND_SURPLUS,
        FLOW_PRODUCTION_GOOD=FLOW_PRODUCTION_GOOD,
        PRICE_GOOD=GoodPrice,
        FLOW_INVESTMENT_TOTAL=FLOW_INVESTMENT_TOTAL,
        FLOW_INVESTMENT_RESOURCE=FLOW_INVESTMENT_RESOURCE,
        FLOW_INVESTMENT_LABOR=FLOW_INVESTMENT_LABOR,
        FLOW_PAYMENT_REPAYMENT=FLOW_PAYMENT_REPAYMENT,
        FLOW_PAYMENT_WAGE=FLOW_PAYMENT_WAGE,
        FLOW_PAYMENT_RESOURCE=FLOW_PAYMENT_RESOURCE,
        FLOW_PAYMENT_DIVIDEND=FLOW_PAYMENT_DIVIDEND,
        FLOW_DIVIDEND_DECISION=DividendDecision,
        FLOW_DIVIDEND_INCOME=FLOW_DIVIDEND_INCOME,
        LABOR_BANK=state.LABOR_BANK,
        LABOR_STOCK=state.LABOR_STOCK,
        LABOR_GOOD=state.LABOR_GOOD,
        RESOURCE_BANK=state.RESOURCE_BANK,
        RESOURCE_STOCK=state.RESOURCE_STOCK,
        RESOURCE_GOOD=state.RESOURCE_GOOD,
        COMPANY_BANK=state.COMPANY_BANK,
        COMPANY_LOAN=state.COMPANY_LOAN,
        COMPANY_DIV=state.COMPANY_DIV,
        COMPANY_RESOURCE=state.COMPANY_RESOURCE,
        COMPANY_LABOR=state.COMPANY_LABOR,
        COMPANY_GOOD=state.COMPANY_GOOD,
        CAPITAL_BANK=state.CAPITAL_BANK,
        CAPITAL_DIV=state.CAPITAL_DIV,
        CAPITAL_GOOD=state.CAPITAL_GOOD,
        BANK_COMPANY_LOAN=state.BANK_COMPANY_LOAN,
        BANK_COMPANY_BANK=state.BANK_COMPANY_BANK,
        BANK_LABOR_BANK=state.BANK_LABOR_BANK,
        BANK_RESOURCE_BANK=state.BANK_RESOURCE_BANK,
        BANK_CAPITAL_BANK=state.BANK_CAPITAL_BANK
    ))
    return sim, stateNew
end;
# Utilities
# ------------------------------------------------------------------------------------------------------------
# simulation iteration
function simulate(transition, state, nperiods)
    sim = DataFrame()                                           # use dataframe to hold data of simulation
    for period in 0:nperiods
        sim, state = transition(sim, state, period)              # iterated application of StateTransition to initial state                
    end
    return sim
end;
# one plot for each variable
function plotVars(sim)
    println("Column names: ", names(sim))

    # Micro Level Plots (Individual Agent Activities)
    p1 = plot(sim[!, :Period], [sim[!, :LABOR_BANK], sim[!, :LABOR_STOCK], sim[!, :LABOR_GOOD]],
        label=["Bank Account" "Labor Stock" "Goods"], title="Labor Accounts")

    p2 = plot(sim[!, :Period], [sim[!, :RESOURCE_BANK], sim[!, :RESOURCE_STOCK], sim[!, :RESOURCE_GOOD]],
        label=["Bank Account" "Resource Stock" "Goods"], title="Resource Accounts")

    p3 = plot(sim[!, :Period], [sim[!, :COMPANY_BANK], sim[!, :COMPANY_LOAN], sim[!, :COMPANY_GOOD]],
        label=["Bank Account" "Loans" "Goods"], title="Company Accounts")

    p4 = plot(sim[!, :Period], [sim[!, :CAPITAL_BANK], sim[!, :CAPITAL_DIV], sim[!, :CAPITAL_GOOD]],
        label=["Bank Account" "Dividends" "Goods"], title="Capital Accounts")

    micro_layout = plot(p1, p2, p3, p4, layout=(2, 2), size=(1200, 800))
    savefig(micro_layout, "docs/src/assets/micro_level_accounts.png")

    # Meso Level Plots (Clearing and Settlement)
    p5 = plot(sim[!, :Period], [sim[!, :morning_efficiency], sim[!, :evening_efficiency]],
        label=["Morning" "Evening"], title="Clearing Efficiency")

    p6 = plot(sim[!, :Period], [sim[!, :FLOW_CONSUMPTION_RESOURCE], sim[!, :FLOW_CONSUMPTION_LABOR], sim[!, :FLOW_CONSUMPTION_CAPITAL]],
        label=["Resource" "Labor" "Capital"], title="Consumption Flows")

    p7 = plot(sim[!, :Period], [sim[!, :FLOW_PAYMENT_WAGE], sim[!, :FLOW_PAYMENT_REPAYMENT]],
        label=["Wages" "Repayments"], title="Payment Flows")

    p8 = plot(sim[!, :Period], [sim[!, :FLOW_PAYMENT_DIVIDEND], sim[!, :FLOW_DIVIDEND_INCOME]],
        label=["Payments" "Income"], title="Dividend Flows")

    meso_layout = plot(p5, p6, p7, p8, layout=(2, 2), size=(1200, 800))
    savefig(meso_layout, "docs/src/assets/meso_level_flows.png")

    # Macro Level Plots (System-wide Variables)
    p9 = plot(sim[!, :Period], sim[!, :FLOW_INVESTMENT_TOTAL],
        label="Investment", title="Investment Cycle")

    p10 = plot(sim[!, :Period], [sim[!, :FLOW_PRODUCTION_GOOD], sim[!, :PRICE_GOOD]],
        label=["Production" "Price"], title="Production and Prices")

    p11 = plot(sim[!, :Period], [sim[!, :FLOW_DEMAND_PLANNED], sim[!, :FLOW_DEMAND_SURPLUS]],
        label=["Actual" "Surplus"], title="Demand Components")

    p12 = plot(sim[!, :Period], sim[!, :NET_POSITION_MACRO],
        label="Net Position", title="Macro Balance")

    macro_layout = plot(p9, p10, p11, p12, layout=(2, 2), size=(1200, 800))
    savefig(macro_layout, "docs/src/assets/macro_level_indicators.png")

    # System State Evolution
    p13 = plot(sim[!, :Period], [sim[!, :LABOR_BANK], sim[!, :RESOURCE_BANK],
            sim[!, :COMPANY_BANK], sim[!, :CAPITAL_BANK]],
        label=["Labor" "Resource" "Company" "Capital"],
        title="Bank Account Balances")

    p14 = plot(sim[!, :Period], [sim[!, :LABOR_GOOD], sim[!, :RESOURCE_GOOD],
            sim[!, :COMPANY_GOOD], sim[!, :CAPITAL_GOOD]],
        label=["Labor" "Resource" "Company" "Capital"],
        title="Good Holdings")

    p15 = plot(sim[!, :Period], [sim[!, :FLOW_CONSUMPTION_RESOURCE], sim[!, :FLOW_CONSUMPTION_LABOR],
            sim[!, :FLOW_CONSUMPTION_CAPITAL]],
        label=["Resource" "Labor" "Capital"],
        title="Consumption Patterns")

    p16 = plot(sim[!, :Period], [sim[!, :FLOW_INVESTMENT_RESOURCE], sim[!, :FLOW_INVESTMENT_LABOR]],
        label=["Resource" "Labor"],
        title="Investment Allocation")

    state_layout = plot(p13, p14, p15, p16, layout=(2, 2), size=(1200, 800))
    savefig(state_layout, "docs/src/assets/system_state_evolution.png")
end

# Plot functions for different flow types
function plot_payment_flows(sim)
    return plot(sim[!, :Period],
        [sim[!, :FLOW_PAYMENT_WAGE], sim[!, :FLOW_PAYMENT_RESOURCE], sim[!, :FLOW_PAYMENT_DIVIDEND]],
        label=["Wage" "Resource" "Dividend"],
        title="Payment Flows")
end

function plot_consumption_flows(sim)
    return plot(sim[!, :Period],
        [sim[!, :FLOW_CONSUMPTION_LABOR], sim[!, :FLOW_CONSUMPTION_RESOURCE],
            sim[!, :FLOW_CONSUMPTION_CAPITAL], sim[!, :FLOW_CONSUMPTION_TOTAL]],
        label=["Labor" "Resource" "Capital" "Total"],
        title="Consumption Flows")
end

function plot_production_flows(sim)
    return plot(sim[!, :Period],
        [sim[!, :FLOW_PRODUCTION_GOOD], sim[!, :PRICE_GOOD]],
        label=["Production" "Price"],
        title="Production and Price")
end

function plot_demand_flows(sim)
    return plot(sim[!, :Period],
        [sim[!, :FLOW_DEMAND_PLANNED], sim[!, :FLOW_DEMAND_SURPLUS]],
        label=["Planned" "Surplus"],
        title="Demand Components")
end

function plot_investment_flows(sim)
    return plot(sim[!, :Period],
        [sim[!, :FLOW_INVESTMENT_TOTAL], sim[!, :FLOW_INVESTMENT_RESOURCE],
            sim[!, :FLOW_INVESTMENT_LABOR]],
        label=["Total" "Resource" "Labor"],
        title="Investment Allocation")
end

function plot_net_positions(sim)
    return plot(sim[!, :Period],
        [sim[!, :NET_POSITION_CAPITAL], sim[!, :NET_POSITION_RESOURCE],
            sim[!, :NET_POSITION_COMPANY], sim[!, :NET_POSITION_LABOR]],
        label=["Capital" "Resource" "Company" "Labor"],
        title="Net Positions")
end

function plot_clearing_efficiency(sim)
    return plot(sim[!, :Period],
        [sim[!, :morning_efficiency], sim[!, :evening_efficiency]],
        label=["Morning" "Evening"],
        title="Clearing Efficiency")
end

function plot_stock_evolution(sim)
    return plot(sim[!, :Period],
        [sim[!, :LABOR_STOCK], sim[!, :RESOURCE_STOCK], sim[!, :COMPANY_GOOD]],
        label=["Labor" "Resource" "Goods"],
        title="Stock Evolution")
end

function plotVars(sim)
    println("Plotting system variables...")

    # Create individual plots
    p1 = plot_payment_flows(sim)
    p2 = plot_consumption_flows(sim)
    p3 = plot_production_flows(sim)
    p4 = plot_demand_flows(sim)
    p5 = plot_investment_flows(sim)
    p6 = plot_net_positions(sim)
    p7 = plot_clearing_efficiency(sim)
    p8 = plot_stock_evolution(sim)

    # Combine plots into layouts
    flow_layout = plot(p1, p2, p3, p4, layout=(2, 2), size=(1200, 800))
    savefig(flow_layout, "docs/src/assets/flow_analysis.png")

    system_layout = plot(p5, p6, p7, p8, layout=(2, 2), size=(1200, 800))
    savefig(system_layout, "docs/src/assets/system_analysis.png")

    # Print summary statistics
    println("\nSystem Analysis Summary:")
    println("Payment Flows:")
    println("  - Average Wage Payment: ", mean(sim[!, :FLOW_PAYMENT_WAGE]))
    println("  - Average Resource Payment: ", mean(sim[!, :FLOW_PAYMENT_RESOURCE]))
    println("  - Average Dividend Payment: ", mean(sim[!, :FLOW_PAYMENT_DIVIDEND]))

    println("\nConsumption Flows:")
    println("  - Total Consumption: ", mean(sim[!, :FLOW_CONSUMPTION_TOTAL]))
    println("  - Labor Share: ", mean(sim[!, :FLOW_CONSUMPTION_LABOR] ./ sim[!, :FLOW_CONSUMPTION_TOTAL]))
    println("  - Resource Share: ", mean(sim[!, :FLOW_CONSUMPTION_RESOURCE] ./ sim[!, :FLOW_CONSUMPTION_TOTAL]))
    println("  - Capital Share: ", mean(sim[!, :FLOW_CONSUMPTION_CAPITAL] ./ sim[!, :FLOW_CONSUMPTION_TOTAL]))

    println("\nProduction and Investment:")
    println("  - Average Production: ", mean(sim[!, :FLOW_PRODUCTION_GOOD]))
    println("  - Average Price: ", mean(sim[!, :PRICE_GOOD]))
    println("  - Average Investment: ", mean(sim[!, :FLOW_INVESTMENT_TOTAL]))

    println("\nClearing Efficiency:")
    println("  - Morning: ", mean(sim[!, :morning_efficiency]))
    println("  - Evening: ", mean(sim[!, :evening_efficiency]))
end

# Save simulation data with new flow variables
function save_simulation_data(sim::DataFrame, filepath::String)
    # Group variables by flow type
    flow_groups = Dict(
        "payment_flows" => [:FLOW_PAYMENT_WAGE, :FLOW_PAYMENT_RESOURCE, :FLOW_PAYMENT_DIVIDEND],
        "consumption_flows" => [:FLOW_CONSUMPTION_LABOR, :FLOW_CONSUMPTION_RESOURCE,
            :FLOW_CONSUMPTION_CAPITAL, :FLOW_CONSUMPTION_TOTAL],
        "production_flows" => [:FLOW_PRODUCTION_GOOD, :PRICE_GOOD],
        "demand_flows" => [:FLOW_DEMAND_PLANNED, :FLOW_DEMAND_SURPLUS],
        "investment_flows" => [:FLOW_INVESTMENT_TOTAL, :FLOW_INVESTMENT_RESOURCE,
            :FLOW_INVESTMENT_LABOR],
        "net_positions" => [:NET_POSITION_CAPITAL, :NET_POSITION_RESOURCE,
            :NET_POSITION_COMPANY, :NET_POSITION_LABOR],
        "clearing_efficiency" => [:morning_efficiency, :evening_efficiency]
    )

    # Save full simulation data
    CSV.write(filepath * "_full.csv", sim)

    # Create summary statistics by flow group
    summary = Dict{String,Any}()

    for (group_name, vars) in flow_groups
        group_stats = Dict{String,Any}()
        for var in vars
            if var in names(sim)
                group_stats[String(var)] = Dict(
                    "mean" => mean(sim[:, var]),
                    "std" => std(sim[:, var]),
                    "min" => minimum(sim[:, var]),
                    "max" => maximum(sim[:, var])
                )
            end
        end
        summary[group_name] = group_stats
    end

    # Add metadata
    summary["metadata"] = Dict(
        "periods" => nrow(sim),
        "variables" => ncol(sim) - 1,
        "timestamp" => string(now())
    )

    # Save summary
    open(filepath * "_summary.json", "w") do f
        JSON.print(f, summary, 4)
    end

    return summary
end

# ------------------------------------------------------------------------------------------------------------
# Simulate
sim = simulate(StateTransition, State(Parameters=PARAMETERS), 100)   # state transition, initial state with parameters, 100 periods to simulate

# Save simulation data
save_simulation_data(sim, "simulation_data/data")

# Print and plot selected variables
vars = [
    :Period, :FLOW_INVESTMENT_TOTAL, :FLOW_PAYMENT_DIVIDEND,
    :FLOW_CONSUMPTION_RESOURCE, :FLOW_CONSUMPTION_LABOR, :FLOW_CONSUMPTION_CAPITAL,
    :LABOR_BANK, :RESOURCE_BANK, :COMPANY_BANK, :CAPITAL_BANK,
    :FLOW_PRODUCTION_GOOD, :PRICE_GOOD
]
sim[1:100, vars]                                              # print dataframe
plotVars(sim)                                                 # plot variables using all data

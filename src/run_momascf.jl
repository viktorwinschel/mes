using DataFrames    # for simulated time series
using Plots         # for visualization
using Parameters    # for struct initialization
using CSV, JSON, Statistics, Dates

# Define the State structure
@with_kw mutable struct State
    Parameters::NamedTuple
    # Bank accounts
    AccLabBank::Float64 = 0.0
    AccLabLab::Float64 = 0.0
    AccLabGood::Float64 = 0.0
    AccResBank::Float64 = 0.0
    AccResRes::Float64 = 0.0
    AccResGood::Float64 = 0.0
    AccCapBank::Float64 = 0.0
    AccCapDiv::Float64 = 0.0
    AccCapGood::Float64 = 0.0
    AccComBank::Float64 = 0.0
    AccComLoan::Float64 = 0.0
    AccComDiv::Float64 = 0.0
    AccComRes::Float64 = 0.0
    AccComLab::Float64 = 0.0
    AccComGood::Float64 = 0.0
    AccBankComLoan::Float64 = 0.0
    AccBankComBank::Float64 = 0.0
    AccBankLabBank::Float64 = 0.0
    AccBankResBank::Float64 = 0.0
    AccBankCapBank::Float64 = 0.0
    # History vectors
    wageHist::Vector{Float64} = zeros(Parameters.InvestmentLen)
    repayHist::Vector{Float64} = zeros(Parameters.InvestmentLen)
end

# Parameters for the simulation
const Pars = (
    InvestmentLen=10,    # length of investments, also number of parallel investments
    LabResourceRatio=0.2,
    ConsumRatioRes=0.8,
    ConsumRatioLab=0.95,
    ConsumRatioCap=0.6,
    MarkUp=0.5,
    DivRateDiff=0.15,
    DivRateBank=0.4,
    WindFallProfit=0.5,
    sigA=20.0,  # sigmoid parameter of learning to invest (from demand gap)
    sigB=480.0, # sigmoid parameter of learning to invest (from demand gap)
    sigC=200.0, # sigmoid parameter of learning to invest (from demand gap)
    ResourcePrice=25.0,
    LaborPrice=12.0,
    InitialGoodPrice=30.0,
    LabResSubstProd=0.75,  # elasticity of substitution
    ScaleProd=0.42,  # scaling parameter 
    DecayGoodLab=0.95,
    DecayGoodRes=0.7,
    DecayGoodCap=0.6,
    ReNewRes=100.0,
    ReNewLab=100.0   # new labor every period
)

# State transition function
function StateTransition(sim, state, period)
    pars = state.Parameters                                                     # parameters
    stateNew = State(Parameters=pars)                                           # new state

    # Calculate invariances
    InvCapBank = state.AccCapBank - state.AccBankCapBank                        # capitalists's bank invariance
    InvResBank = state.AccResBank - state.AccBankResBank                        # resource owner's bank invariance
    InvComBank = state.AccComBank - state.AccBankComBank                        # company's bank invariance
    InvComLoan = state.AccBankComLoan - state.AccComLoan                        # company's loan invariance
    InvLabBank = state.AccLabBank - state.AccBankLabBank                        # labor supplier's bank invariance
    InvMacro = InvCapBank + InvResBank + InvComBank + InvComLoan + InvLabBank   # macro economic active, passive, invariance

    # Calculate flows
    WagesPayment = sum(state.wageHist)                                          # wage history
    RepaysPayment = sum(state.repayHist)                                        # repayments of investment history
    ConsumRes = state.AccResBank * pars.ConsumRatioRes                          # consumption of resource owner
    ConsumLab = state.AccLabBank * pars.ConsumRatioLab                          # consumption of labor supplier
    ConsumCap = state.AccCapBank * pars.ConsumRatioCap                          # consumption of capitalist
    Demand = ConsumRes + ConsumLab + ConsumCap                                  # demand (turnover)

    # Production
    GoodProduction = 1 + pars.ScaleProd * state.AccComLab^pars.LabResSubstProd * state.AccComRes^(1 - pars.LabResSubstProd)

    # Market
    DemandPlan = (WagesPayment + RepaysPayment) * (1 + pars.MarkUp)            # costs(wages,depreciation) * Markup
    DemandSurplus = Demand - DemandPlan                                         # demand surplus
    GoodPrice = ((period == 0 ? pars.InitialGoodPrice : 0.0)
                 + DemandPlan / GoodProduction
                 + ((DemandSurplus > 0.0) ? (DemandSurplus * pars.WindFallProfit) : 0.0))

    # Investment
    Investment = pars.sigA + pars.sigB / (1.0 + exp(-DemandSurplus / pars.sigC)) # investment decision
    InvestmentRes = Investment * (1 - pars.LabResourceRatio)                      # investments used for resources
    InvestmentLab = Investment * pars.LabResourceRatio                            # investments used for labour
    Repayment = Investment / pars.InvestmentLen                                   # period repayments

    # Update History
    p2H(hist, newelem) = [newelem; hist[1:end-1]]                               # push new element to history, drop last
    stateNew.wageHist = p2H(state.wageHist, InvestmentLab)                      # update wage history
    stateNew.repayHist = p2H(state.repayHist, Repayment)                        # update repay history

    # Calculate dividends
    Diff = state.AccBankComLoan - state.AccComLoan                              # difference between bank and company loan accounts
    DividendDecision = Diff * pars.DivRateDiff                                  # dividend decision based on difference
    DividendPayment = DividendDecision * pars.DivRateBank                       # dividend payment based on decision
    DividendIncome = DividendPayment                                            # dividend income equals payment

    # Update accounts
    stateNew.AccLabBank = state.AccLabBank + InvestmentLab - ConsumLab
    stateNew.AccLabLab = state.AccLabLab + pars.ReNewLab
    stateNew.AccLabGood = state.AccLabGood * pars.DecayGoodLab
    stateNew.AccResBank = state.AccResBank + InvestmentRes - ConsumRes
    stateNew.AccResRes = state.AccResRes + pars.ReNewRes
    stateNew.AccResGood = state.AccResGood * pars.DecayGoodRes
    stateNew.AccCapBank = state.AccCapBank + DividendIncome - ConsumCap
    stateNew.AccCapDiv = state.AccCapDiv + DividendIncome
    stateNew.AccCapGood = state.AccCapGood * pars.DecayGoodCap
    stateNew.AccComBank = state.AccComBank + ConsumRes + ConsumLab + ConsumCap - InvestmentRes - InvestmentLab - DividendPayment
    stateNew.AccComLoan = state.AccComLoan + Repayment
    stateNew.AccComDiv = state.AccComDiv + DividendPayment
    stateNew.AccComRes = state.AccComRes + InvestmentRes
    stateNew.AccComLab = state.AccComLab + InvestmentLab
    stateNew.AccComGood = GoodProduction
    stateNew.AccBankComLoan = state.AccBankComLoan + Repayment
    stateNew.AccBankComBank = state.AccBankComBank
    stateNew.AccBankLabBank = state.AccBankLabBank
    stateNew.AccBankResBank = state.AccBankResBank
    stateNew.AccBankCapBank = state.AccBankCapBank

    # Record state
    push!(sim, (
        Period=period,
        InvCapBank=InvCapBank,
        InvResBank=InvResBank,
        InvComBank=InvComBank,
        InvComLoan=InvComLoan,
        InvLabBank=InvLabBank,
        InvMacro=InvMacro,
        ConsumRes=ConsumRes,
        ConsumLab=ConsumLab,
        ConsumCap=ConsumCap,
        Demand=Demand,
        DemandPlan=DemandPlan,
        DemandSurplus=DemandSurplus,
        GoodProduction=GoodProduction,
        GoodPrice=GoodPrice,
        Investment=Investment,
        InvestmentRes=InvestmentRes,
        InvestmentLab=InvestmentLab,
        Repayment=Repayment,
        WagesPayment=WagesPayment,
        RepaysPayment=RepaysPayment,
        Diff=Diff,
        DividendDecision=DividendDecision,
        DividendPayment=DividendPayment,
        DividendIncome=DividendIncome,
        AccLabBank=state.AccLabBank,
        AccLabLab=state.AccLabLab,
        AccLabGood=state.AccLabGood,
        AccResBank=state.AccResBank,
        AccResRes=state.AccResRes,
        AccResGood=state.AccResGood,
        AccCapBank=state.AccCapBank,
        AccCapDiv=state.AccCapDiv,
        AccCapGood=state.AccCapGood,
        AccComBank=state.AccComBank,
        AccComLoan=state.AccComLoan,
        AccComDiv=state.AccComDiv,
        AccComRes=state.AccComRes,
        AccComLab=state.AccComLab,
        AccComGood=state.AccComGood,
        AccBankComLoan=state.AccBankComLoan,
        AccBankComBank=state.AccBankComBank,
        AccBankLabBank=state.AccBankLabBank,
        AccBankResBank=state.AccBankResBank,
        AccBankCapBank=state.AccBankCapBank
    ))

    return sim, stateNew
end

# Simulation function
function simulate(transition, state, nperiods)
    sim = DataFrame()                                           # use dataframe to hold data of simulation
    for period in 0:nperiods
        sim, state = transition(sim, state, period)             # iterated application of StateTransition to initial state                
    end
    return sim
end

# Plotting function
function plotVars(sim, vars)
    p = plot(layout=(length(vars), 1), size=(800, 200 * length(vars)))    # one plot per variable, stacked vertically
    for (i, var) in enumerate(vars)
        plot!(p[i], sim[:, :Period], sim[:, var],
            label=String(var),
            title=String(var),
            linewidth=2,
            legend=:topright)
    end
    return p
end

# Run simulation
println("Starting simulation...")
sim = simulate(StateTransition, State(Parameters=Pars), 100)    # run for 100 periods

# Create plots directory if it doesn't exist
mkpath("plots")

# Plot key variables
vars = [:Investment, :DividendPayment, :GoodProduction, :GoodPrice]
println("\nPlotting results...")
p = plotVars(sim, vars)

# Save plot
savefig(p, "plots/momascf_simulation.png")
println("Plot saved to plots/momascf_simulation.png")

# Save results
println("\nSaving results...")
CSV.write("simulation_results.csv", sim)

println("Simulation complete!")
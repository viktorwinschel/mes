# ---------------------------------------------------------------------
# MoMa
# Monetery Accounting in Supply Chain Finance (MoMaSCF)
# ---------------------------------------------------------------------
using DataFrames    # Simulated Time Series
using Plots         # Visualization of Time Series
using Parameters    # Initialization of State Variables, Accounts
using CSV
# not used abstract types, to become categories ...
# ---------------------------------------------------------------------
#=
monetary macro booking are 
two bookings on the debit and credit one amount
(one booking only paper money creation at micro account centralbank
gold creation is by byuing gold for bank note at gold minter) 
bank loans and deposits sum to macro invariance 
(no payments and revenues invariance of money, here only deposits)
=#
# ---------------------------------------------------------------------
Pars = (
    InvestmentLen=10, # Int length and number (later) of investments
    # Vector implements storage (as FILO Stack) for the
    # repayment of investments and payment of wages
    LabResourceRatio=0.2, # Float64 investment ratio wages resources
    ConsumRatioRes=0.8, # Float64 ratio resources consumption
    ConsumRatioLab=0.95, # Float64 ratio wages consumption
    ConsumRatioCap=0.6, # Float64 ratio dividends consumption
    MarkUp=0.5, # Float64 markup
    DivRateDiff=0.15, # Float64 dividend rate companies
    DivRateBank=0.4, # Float64 dividend rate banks    
    WindFallProfit=0.5, # Float64 windfall profit
    sigA=20.0,  # Float64 sigA decide investment from demand gap
    sigB=480.0, # Float64 sigB decide investment from demand gap
    sigC=200.0, # Float64 sigC decide investment from demand gap
    ResourcePrice=25.0, # Float64 price resources
    LaborPrice=12.0, # Float64 price wages
    InitialGoodPrice=30.0, # Float64 initial price products
    LabResSubstProd=0.75,  # Float64 elasticity of substitution
    ScaleProd=0.42, # Float64 production scalor 
    DecayGoodLab=0.95, # Float64 depreciation labor
    DecayGoodRes=0.7, # Float64 depreciation resources
    DecayGoodCap=0.6, # Float64 depreciation capital
    ReNewRes=100.0, # Float64 new resources each period
    ReNewLab=100.0, # Float64 new labor each period
);
# ---------------------------------------------------------------------
# State of Macro Accounting System 
# ---------------------------------------------------------------------
@with_kw mutable struct State
    Parameters::Any # parameters, history wage, repayments
    wageHist::Vector{Float64} = zeros(Parameters.InvestmentLen)
    repayHist::Vector{Float64} = zeros(Parameters.InvestmentLen)
    #= 
    5:agents:labor,resource,company,capital,bank
    14:accounts(3,3,6,3,5)
       types:A=Asset,N=Nominal,R=Real,L=Liability
    3:labor:bank(A,N),stock(A,R),good(A,R)
    3:resource:bank(A,N),stock(A,R),good(A,R)
    6:company:bank(A,N),loan(L,N),dividend(L,N),
              labor(A,R),resource(A,R),good(A,R)
    3:capital:bank(A,N),dividend(A,N),good(A,R)
    5:bank:loan.company(A,N),deposit.labor(L,N),deposit.resource(L,N), 
                             deposit.company(L,N),deposit.capital(L,N) =#
    AccLabBank::Float64 = 0.0       # A, N - labor
    AccLabLab::Float64 = 0.0        # A, R      
    AccLabGood::Float64 = 0.0       # A, R      
    AccResBank::Float64 = 0.0       # A, N - resource
    AccResRes::Float64 = 0.0        # A, R      
    AccResGood::Float64 = 0.0       # A, R      
    AccComBank::Float64 = 0.0       # A, N - company
    AccComLoan::Float64 = 0.0       # L, N
    AccComDiv::Float64 = 0.0        # L, N
    AccComRes::Float64 = 20.0       # A, R 
    AccComLab::Float64 = 110.0      # A, R      
    AccComGood::Float64 = 0.0       # A, R      
    AccCapBank::Float64 = 0.0       # A, N - capital
    AccCapDiv::Float64 = 0.0        # A, N
    AccCapGood::Float64 = 0.0       # A, R
    AccBankComLoan::Float64 = 0.0   # A, N - bank
    AccBankComBank::Float64 = 0.0   # L, N 
    AccBankLabBank::Float64 = 0.0   # L, N 
    AccBankResBank::Float64 = 0.0   # L, N 
    AccBankCapBank::Float64 = 0.0   # L, N 
end;
# ---------------------------------------------------------------------
# State Transition
# ---------------------------------------------------------------------
# sim: DataFrame to store results    
# state: with initial values
# period: number to simulate
function StateTransition(sim, state, period) # function to updat
    p2H(hist, newelem) = [newelem; hist[1:end-1]]
    pars = state.Parameters
    stateNew = State(Parameters=pars)
    InvCapBank = state.AccCapBank - state.AccBankCapBank # CapBank Inv 
    InvResBank = state.AccResBank - state.AccBankResBank # ResBank Inv                    
    InvComBank = state.AccComBank - state.AccBankComBank # ComBank Inv                        
    InvComLoan = state.AccBankComLoan - state.AccComLoan # ComLoan Inv                       
    InvLabBank = state.AccLabBank - state.AccBankLabBank # LabBank Inv                       
    InvMacro =
        InvCapBank + InvResBank +
        InvComBank + InvComLoan + InvLabBank # Macro Inv    
    WagesPayment = sum(state.wageHist) # wages payments
    RepaysPayment = sum(state.repayHist) # repayments investment    
    ConsumRes = state.AccResBank * pars.ConsumRatioRes # resources
    ConsumLab = state.AccLabBank * pars.ConsumRatioLab # labor
    ConsumCap = state.AccCapBank * pars.ConsumRatioCap # capital
    Demand = ConsumRes + ConsumLab + ConsumCap # demand
    GoodProduction =
        1 + pars.ScaleProd * state.AccComLab^pars.LabResSubstProd *
            state.AccComRes^(1 - pars.LabResSubstProd)
    DemandPlan = (WagesPayment + RepaysPayment) * (1 + pars.MarkUp)
    DemandSurplus = Demand - DemandPlan
    GoodPrice =
        ((period == 0 ? pars.InitialGoodPrice : 0.0)
         + DemandPlan / GoodProduction
         + ((DemandSurplus > 0.0)
            ? (DemandSurplus * pars.WindFallProfit) : 0.0))
    Investment = pars.sigA + pars.sigB /
                             (1.0 + exp(-DemandSurplus / pars.sigC))
    InvestmentRes = Investment * (1 - pars.LabResourceRatio)
    InvestmentLab = Investment * pars.LabResourceRatio
    Repayment = Investment / pars.InvestmentLen
    stateNew.wageHist = p2H(state.wageHist, InvestmentLab) # wage
    stateNew.repayHist = p2H(state.repayHist, Repayment) # repayments
    # ---------------------------------------------------------------------
    # bookings
    # - labor (4 bookings,M4D,M4C,M3C,M4D)
    # --- bank(A,N)
    inAccLabBank = WagesPayment # 1aD
    outAccLabBank = ConsumLab # 2aC
    stateNew.AccLabBank = state.AccLabBank + inAccLabBank - outAccLabBank
    # --- stock.labor(A,R)
    inAccLabLab = pars.ReNewLab # new labor
    outAccLabLab =
        WagesPayment / pars.LaborPrice # 1aC
    stateNew.AccLabLab = state.AccLabLab + inAccLabLab - outAccLabLab
    # --- good(A,R)
    inAccLabGood = ConsumLab / GoodPrice # 2aD
    outAccLabGood = state.AccLabGood * pars.DecayGoodLab # decay of labor 
    stateNew.AccLabGood = state.AccLabGood + inAccLabGood - outAccLabGood
    # ---------------------------------------------------------------------
    # - resource
    # --- bank(A,N)
    inAccResBank = InvestmentRes # 3aD
    outAccResBank = ConsumRes # 4aC
    stateNew.AccResBank = state.AccResBank + inAccResBank - outAccResBank
    # --- Resource account (asset)
    inAccResRes = pars.ReNewRes # new resource
    outAccResRes =
        InvestmentRes / pars.ResourcePrice # 3aC
    stateNew.AccResRes =
        state.AccResRes + inAccResRes - outAccResRes
    # --- good(A,R)
    inAccResGood = ConsumRes / GoodPrice # 4aD
    outAccResGood = state.AccResGood * pars.DecayGoodRes # decay of good 
    stateNew.AccResGood = state.AccResGood + inAccResGood - outAccResGood
    # ---------------------------------------------------------------------
    # - company
    DividendPayment = state.AccComDiv # decide period before 
    # --- bank(A,N)
    inAccComBank = (
        Investment   # 5aD
        + ConsumLab  # 2aD
        + ConsumRes  # 4aD
        + ConsumCap) # 8aD
    outAccComBank = (
        InvestmentRes     # 3bC
        + WagesPayment    # 1bC
        + DividendPayment # 6aC
        + RepaysPayment)  # 7aC
    Diff = inAccComBank - outAccComBank
    stateNew.AccComBank = state.AccComBank + Diff
    # --- dividend(L,N)
    DividendDecision =
        (Diff > 0.0
         ? (Diff * pars.DivRateDiff) : 0.0) +
        ((state.AccComBank > 0)
         ? (state.AccComBank * pars.DivRateBank) : 0.0)
    inAccComDiv = DividendDecision
    outAccComDiv = DividendPayment # 6aD
    stateNew.AccComDiv = state.AccComDiv + inAccComDiv - outAccComDiv
    # --- loan(L,N)
    inAccComLoan = Investment     # 5aC
    outAccComLoan = RepaysPayment # 7aD
    stateNew.AccComLoan = state.AccComLoan + inAccComLoan - outAccComLoan
    # --- resource(A,R)
    inAccComRes =
        InvestmentRes / pars.ResourcePrice # 3bD
    outAccComRes = state.AccComRes # resource usage in production
    stateNew.AccComRes = state.AccComRes + inAccComRes - outAccComRes
    # --- labor(A,R)
    inAccComLab =
        WagesPayment / pars.LaborPrice # 1bD
    outAccComLab = state.AccComLab # labor usage in production
    stateNew.AccComLab = state.AccComLab + inAccComLab - outAccComLab
    # --- good(A,R)
    inAccComGood = GoodProduction
    outAccComGood =
        (ConsumRes # 4bC
         + ConsumLab # 2bC
         + ConsumCap) / GoodPrice # 8aC
    stateNew.AccComGood = state.AccComGood + inAccComGood - outAccComGood
    # ---------------------------------------------------------------------
    # - capital
    # --- dividend(A,N)
    DividendIncome = state.AccCapDiv # dividend income
    inAccCapDiv = DividendDecision # dividend decision
    outAccCapDiv = DividendIncome # 6bC
    stateNew.AccCapDiv = state.AccCapDiv + inAccCapDiv - outAccCapDiv
    # --- bank(A,N) 
    inAccCapBank = DividendIncome # 6bD
    outAccCapBank = ConsumCap # 8bC
    stateNew.AccCapBank = state.AccCapBank + inAccCapBank - outAccCapBank
    # --- good(A,R)
    inAccCapGood = ConsumCap / GoodPrice # 8bD
    outAccCapGood = state.AccCapGood * pars.DecayGoodCap # decay good
    stateNew.AccCapGood = state.AccCapGood + inAccCapGood - outAccCapGood
    # ---------------------------------------------------------------------
    # - bank 
    # --- loan.company(A,N)
    inAccBankComLoan = Investment # 5bD
    outAccBankComLoan = RepaysPayment # 7bC
    stateNew.AccBankComLoan =
        state.AccBankComLoan + inAccBankComLoan - outAccBankComLoan
    # --- deposit.company(L,N)
    inAccBankComBank = (
        Investment # 5bC
        + ConsumRes # 4cC
        + ConsumLab # 2cC
        + ConsumCap) # 8cC
    outAccBankComBank = (
        InvestmentRes # 3cD
        + WagesPayment # 1cD
        + DividendPayment # 6cD
        + RepaysPayment) # 7bD
    stateNew.AccBankComBank =
        state.AccBankComBank + inAccBankComBank - outAccBankComBank
    # --- deposit.labor(A,L)
    inAccBankLabBank = WagesPayment # 1cC
    outAccBankLabBank = ConsumLab # 2cD
    stateNew.AccBankLabBank =
        state.AccBankLabBank + inAccBankLabBank - outAccBankLabBank
    # --- deposit.resource(A,L)
    inAccBankResBank = InvestmentRes # 3cC
    outAccBankResBank = ConsumRes # 4cD
    stateNew.AccBankResBank =
        state.AccBankResBank + inAccBankResBank - outAccBankResBank
    # --- deposit.capital(A,L)
    inAccBankCapBank = DividendIncome # 6cC
    outAccBankCapBank = ConsumCap # 8cD
    stateNew.AccBankCapBank =
        state.AccBankCapBank + inAccBankCapBank - outAccBankCapBank
    # ---------------------------------------------------------------------
    # variables of interest, states
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
end;
# ---------------------------------------------------------------------
function simulate(transition, state, nperiods)
    sim = DataFrame()
    for period in 0:nperiods
        sim, state = transition(sim, state, period)
    end
    return sim
end;
function plotVars(sim)
    plots = Plots.Plot{Plots.GRBackend}[]
    nms = names(sim)
    for c in 2:ncol(sim)
        push!(plots,
            plot(sim[:, :Period], sim[:, c], label=String(nms[c]),
                title=String(nms[c]), linewidth=2, legend=:topright))
    end
    plot(plots...)
end;
sim = simulate(StateTransition, State(Parameters=Pars), 100);
vars = [:Period, :Investment, :DividendPayment];
sim[1:100, vars]
plotVars(sim[:, vars])
# reaplce near zero values
ϵ = 1e-12
df = sim
for col in names(df)
    if eltype(df[!, col]) <: Number
        df[!, col] = map(x -> abs(x) < ϵ ? 0.0 : x, df[!, col])
    end
end
sim = df
filename = @__FILE__
csvfile = replace(filename, ".jl" => "_data.csv")
# write
CSV.write(csvfile, sim)

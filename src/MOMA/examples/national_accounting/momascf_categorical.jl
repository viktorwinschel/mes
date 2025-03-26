# --------------------------------------------------------------------------------------------------------------------------------------------
# MoMaT
# Monetäre Makrobuchhaltung des Supply Chain Finance (MoMaSCF)
# Monetäre Makro Buchhaltung der Lieferkettenfinanzierung (MoMaLKF) 
# Wechselmarkt in D 1990: 50 Mrd DM p.a.
# aktuell: trade finance $10^12, davon 2/3 als open account, dh später zu bezahlen
# --------------------------------------------------------------------------------------------------------------------------------------------
using DataFrames, Plots, Parameters, CSV, JSON, Statistics, Dates

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
Pars = (
    InvestmentLen=10,    # length of investments, also number of parallel investments, 
    # also length of vector that implements memory (as a FILO stack)
    # for the investments repayment and paid wages.
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
);
# ------------------------------------------------------------------------------------------------------------
# State mit initials 
@with_kw mutable struct State
    Parameters::Any                                                   # parameters  
    wageHist::Vector{Float64} = zeros(Parameters.InvestmentLen)       # history of wage payments
    repayHist::Vector{Float64} = zeros(Parameters.InvestmentLen)      # history of loan repayments             
    #                                         acc system of     account                 type            unit
    #                                       -----------------------------------------------------------------
    AccLabBank::Float64 = 0.0               # labour            bank                    asset           nominal
    AccLabLab::Float64 = 0.0                # labour            labor                   asset           real           
    AccLabGood::Float64 = 0.0               # labour            goods                   asset           real      
    AccResBank::Float64 = 0.0               # resource owner    bank                    asset           nomimal
    AccResRes::Float64 = 0.0                # resource owner    resources               asset           real      
    AccResGood::Float64 = 0.0               # resource owner    goods                   asset           real      
    AccComBank::Float64 = 0.0               # company           bank                    asset           nomimal
    AccComLoan::Float64 = 0.0               # company           loan                    liabilities     nomimal
    AccComDiv::Float64 = 0.0                # company           dividend                liabilities     nomimal
    AccComRes::Float64 = 20.0               # company           resource                asset           real       
    AccComLab::Float64 = 110.0              # company           labor                   asset           real      
    AccComGood::Float64 = 0.0               # company           good                    asset           real      
    AccCapBank::Float64 = 0.0               # capitalist        bank                    asset           nomimal
    AccCapDiv::Float64 = 0.0                # capitalist        dividend                asset           nomimal
    AccCapGood::Float64 = 0.0               # capitalist        goods                   asset           real
    AccBankComLoan::Float64 = 0.0           # bank              loan of company         asset           nomimal
    AccBankComBank::Float64 = 0.0           # bank              bank of company         liabilities     nomimal
    AccBankLabBank::Float64 = 0.0           # bank              bank of labor           liabilities     nomimal
    AccBankResBank::Float64 = 0.0           # bank              bank of resouce owner   liabilities     nomimal
    AccBankCapBank::Float64 = 0.0           # bank              bank of capitalist      liabilities     nomimal
end;
# ------------------------------------------------------------------------------------------------------------
function StateTransition(sim, state, period)
    pars = state.Parameters                                                     # parameters
    stateNew = State(Parameters=pars)                                           # new state
    # Invarianzen: Aktiv, Passive, Forderungen, Verbindlichkeiten, WagesPayment, RepaysPayment, ConsumRes, ConsumLab, ConsumCap, Demand 
    InvCapBank = state.AccCapBank - state.AccBankCapBank                        # capitalists's     bank invariance
    InvResBank = state.AccResBank - state.AccBankResBank                        # resource owner's  bank invariance
    InvComBank = state.AccComBank - state.AccBankComBank                        # company's         bank invariance
    InvComLoan = state.AccBankComLoan - state.AccComLoan                        # company's         loan invariance
    InvLabBank = state.AccLabBank - state.AccBankLabBank                        # labor supplier's  bank invariance
    InvMacro = InvCapBank + InvResBank + InvComBank + InvComLoan + InvLabBank   # macro economic active, passive, invariance
    WagesPayment = sum(state.wageHist)                                          # wage history
    RepaysPayment = sum(state.repayHist)                                        # repayments of investment history
    ConsumRes = state.AccResBank * pars.ConsumRatioRes                          # consumption of resource owner
    ConsumLab = state.AccLabBank * pars.ConsumRatioLab                          # consumption of labor supplier
    ConsumCap = state.AccCapBank * pars.ConsumRatioCap                          # consumption of capitalist
    Demand = ConsumRes + ConsumLab + ConsumCap                                  # demand (turnover)
    # Production (Cobb-Douglas production function)
    GoodProduction = 1 + pars.ScaleProd * state.AccComLab^pars.LabResSubstProd * state.AccComRes^(1 - pars.LabResSubstProd)
    # Market
    DemandPlan = (WagesPayment + RepaysPayment) * (1 + pars.MarkUp)         # costs(wages,depreciation) * Markup
    DemandSurplus = Demand - DemandPlan                                     # damand surplus
    GoodPrice = ((period == 0 ? pars.InitialGoodPrice : 0.0)
                 + DemandPlan / GoodProduction
                 + ((DemandSurplus > 0.0) ? (DemandSurplus * pars.WindFallProfit) : 0.0))
    # Investment
    Investment = pars.sigA + pars.sigB / (1.0 + exp(-DemandSurplus / pars.sigC)) # investment decision
    # here some simulation variations are possible:
    # e.g. linear growth from period 40 to 60, random disturbances
    InvestmentRes2 = Investment * (1 - pars.LabResourceRatio)               # investments used for resources
    InvestmentRes = InvestmentRes2                                          # used in VenSim code / model (InvestmentRes2 is superfluous)
    InvestmentLab = Investment * pars.LabResourceRatio                      # investments used for labour
    Repayment = Investment / pars.InvestmentLen                             # period repayments
    # Update History
    p2H(hist, newelem) = [newelem; hist[1:end-1]]                           # push new element to history, drop last: p2H([3,2,1],4)=[4,3,2]
    stateNew.wageHist = p2H(state.wageHist, InvestmentLab)                  # update wage history
    stateNew.repayHist = p2H(state.repayHist, Repayment)                    # update repay history
    # Accouting
    #=
     Explanation of the notation of bookings:
     Examples:   M5_Com(D,_)ex-Com-Bank: money inflow from investment
                 M4_Lab(_,C)ex-Lab-Com-Bank: money outflow from buying good

     'M5' is the Macro accounting booking no. '5'. 
     There are two double accounting systems of the agents 'Com' and 'Bank' involved 
     in this 'ex'change where this booking is the 'D'ebit booking of 'Com'
     'money inflow of investment' is a comment on the booking from the perspective of Com.

     'M4' is the Macro accounting booking no. '4'. 
     There are three double accounting systems of the agents 'Lab', 'Com' and 'Bank' involved 
     in this 'ex'change where this booking is the 'C'redit booking of 'Lab'.
     'money outflow from buying good' is a comment on the booking from the perspective of Lab.
     =#
    # Lab
    # Bank account (asset)
    inAccLabBank = WagesPayment                                             # M3_Lab(D,_)ex-Lab-Com-Bank: money inflow from selling labour
    outAccLabBank = ConsumLab                                               # M4_Lab(_,C)ex-Lab-Com-Bank: money outflow from buying good
    stateNew.AccLabBank = state.AccLabBank + inAccLabBank - outAccLabBank   # state update
    # Labour account (asset)
    inAccLabLab = pars.ReNewLab                                             # new labour each period 
    outAccLabLab = WagesPayment / pars.LaborPrice                           # M3_Lab(_,C)ex-Lab-Com-Bank: labour outflow from selling labour
    stateNew.AccLabLab = state.AccLabLab + inAccLabLab - outAccLabLab       # state update
    # Good account (asset)
    inAccLabGood = ConsumLab / GoodPrice                                    # M4_Lab(D,_)ex-Lab-Com-Bank: good inflow from buying good
    outAccLabGood = state.AccLabGood * pars.DecayGoodLab                    # decay of good of Lab
    stateNew.AccLabGood = state.AccLabGood + inAccLabGood - outAccLabGood   # state update
    # Res
    # Bank account (asset)
    inAccResBank = InvestmentRes                                            # M1_Res(D,_)ex-Res-Com-Bank: money inflow from selling resources
    outAccResBank = ConsumRes                                               # M2_Res(_,C)ex-Res-Com-Bank: money outflow from buying good
    stateNew.AccResBank = state.AccResBank + inAccResBank - outAccResBank   # state update
    # Resource account (asset)
    inAccResRes = pars.ReNewRes                                             # new resources each period 
    outAccResRes = InvestmentRes / pars.ResourcePrice                       # M1_Res(_,C)ex-Res-Com-Bank: resources outflow from selling resources
    stateNew.AccResRes = state.AccResRes + inAccResRes - outAccResRes       # state update
    # Good account (asset)
    inAccResGood = ConsumRes / GoodPrice                                    # M2_Res(D,_)ex-Res-Com-Bank: good inflow from buying good
    outAccResGood = state.AccResGood * pars.DecayGoodRes                    # decay of good of Res                                                         
    stateNew.AccResGood = state.AccResGood + inAccResGood - outAccResGood   # state update
    # Com
    DividendPayment = state.AccComDiv                                       # dividend payment of the company (decided one period before)
    # Bank account (asset)
    inAccComBank = (Investment                                              # M5_Com(D,_)ex-Com-Bank: money inflow from investment
                    + ConsumLab                                             # M4_Com(D,_)ex-Lab-Com-Bank: money inflow from selling good
                    + ConsumRes                                             # M2_Com(D,_)ex-Res-Com-Bank: money inflow from selling good
                    + ConsumCap)                                            # M8_Com(D,_)ex-Com-Cap-Bank: money inflow from selling good
    outAccComBank = (InvestmentRes                                          # M1_Com(_,C)ex-Res-Com-Bank: money outflow from buying resources
                     + WagesPayment                                         # M3_Com(_,C)ex-Lab-Com-Bank: money outflow from buying labour
                     + DividendPayment                                      # M6_Com(_,C)ex-Cap-Com-Bank: money outflow from dividend payment
                     + RepaysPayment)                                       # M7_Com(_,C)ex-Com-Bank: money outflow from repayment                                                                                                                                                                                                                                    
    Diff = inAccComBank - outAccComBank
    stateNew.AccComBank = state.AccComBank + Diff                           # state update
    # Dividend account (liability)
    DividendDecision = ((Diff > 0.0 ? (Diff * pars.DivRateDiff) : 0.0)
                        +
                        ((state.AccComBank > 0) ? (state.AccComBank * pars.DivRateBank) : 0.0))
    inAccComDiv = DividendDecision                                          # dividend decision
    outAccComDiv = DividendPayment                                          # M6_Com(D,_)ex-Cap-Com-Bank: dividend outflow from dividend payment
    stateNew.AccComDiv = state.AccComDiv + inAccComDiv - outAccComDiv       # state update
    # Loan account (liability)
    inAccComLoan = Investment                                               # M5_Com(_,C)ex-Com-Bank: loan increase from investment
    outAccComLoan = RepaysPayment                                           # M7_Com(D,_)ex-Com-Bank: loan decrease from repayment
    stateNew.AccComLoan = state.AccComLoan + inAccComLoan - outAccComLoan   # state update
    # Resource account (asset)
    inAccComRes = InvestmentRes / pars.ResourcePrice                        # M1_Com(D,_)ex-Res-Com-Bank: resource inflow from buying resources
    outAccComRes = state.AccComRes                                          # resources usage in production
    stateNew.AccComRes = state.AccComRes + inAccComRes - outAccComRes       # state update
    # Labour account (asset)
    inAccComLab = WagesPayment / pars.LaborPrice                            # M3_Com(D,_)ex-Lab-Com-Bank: labour inflow from byuing labour
    outAccComLab = state.AccComLab                                          # labour usage in production
    stateNew.AccComLab = state.AccComLab + inAccComLab - outAccComLab       # state update
    # Good account (asset)
    inAccComGood = GoodProduction
    outAccComGood = (ConsumRes                                              # M2_Com(_,C)ex-Res-Com-Bank: good outflow from selling good
                     + ConsumLab                                            # M4_Com(_,C)ex-Lab-Com-Bank: good outflow from selling good
                     + ConsumCap) / GoodPrice                               # M8_Com(_,C)ex-Com-Cap-Bank: good outflow from selling good                                                                     
    stateNew.AccComGood = state.AccComGood + inAccComGood - outAccComGood   # state update
    # Cap
    DividendIncome = state.AccCapDiv                                        # dividend income
    # Dividend account (asset)
    inAccCapDiv = DividendDecision                                          # devidend decision
    outAccCapDiv = DividendIncome                                           # M6_Cap(_,C)ex-Cap-Com-Bank: dividend outflow from dividend payment
    stateNew.AccCapDiv = state.AccCapDiv + inAccCapDiv - outAccCapDiv       # state update
    # Bank account (asset)
    inAccCapBank = DividendIncome                                           # M6_Cap(D,_)ex-Cap-Com-Bank: money inflow from dividend payment 
    outAccCapBank = ConsumCap                                               # M8_Cap(_,C)ex-Com-Cap-Bank: money outflow from buying good
    stateNew.AccCapBank = state.AccCapBank + inAccCapBank - outAccCapBank   # state update
    # Good account (asset)
    inAccCapGood = ConsumCap / GoodPrice                                    # M8_Cap(D,_)ex-Com-Cap-Bank: good inflow from buying good
    outAccCapGood = state.AccCapGood * pars.DecayGoodCap                    # decay of good of Cap
    stateNew.AccCapGood = state.AccCapGood + inAccCapGood - outAccCapGood   # state update
    # Bank
    # Loan account of Com (asset)
    inAccBankComLoan = Investment                                           # M5_Bank(D,_)ex-Com-Bank: loan increase from giving investment
    outAccBankComLoan = RepaysPayment                                       # M7_Bank(_,C)ex-Com-Bank: loan decrease from repayment
    stateNew.AccBankComLoan = state.AccBankComLoan + inAccBankComLoan - outAccBankComLoan   # state update
    # Bank account of Com (liability)
    inAccBankComBank = (Investment                                          # M5_Bank(_,C)ex-Com-Bank: bank increase from getting investment 
                        + ConsumRes                                         # M2_Bank(_,C)ex-Res-Com-Bank: bank increase from selling good
                        + ConsumLab                                         # M4_Bank(_,C)ex-Lab-Com-Bank: bank increase from selling good
                        + ConsumCap)                                        # M8_Bank(_,C)ex-Com-Cap-Bank: bank increase from selling good                                                                                                                                                                                                                                                   
    outAccBankComBank = (InvestmentRes                                      # M1_Bank(D,_)ex-Res-Com-Bank: bank decrease from buying resources
                         + WagesPayment                                     # M3_Bank(D,_)ex-Lab-Com-Bank: bank decrease from buying labour
                         + DividendPayment                                  # M6_Bank(D,_)ex-Cap-Com-Bank: bank decrease from dividend income
                         + RepaysPayment)                                   # M7_Bank(D,_)ex-Com-Bank: bank decrease from repayment                                                                                                                                                                                                                                       
    stateNew.AccBankComBank = state.AccBankComBank + inAccBankComBank - outAccBankComBank   # state update
    # Bank account of Lab (liability)
    inAccBankLabBank = WagesPayment                                         # M3_Bank(_,C)ex-Lab-Com-Bank: bank increase from seeling labour
    outAccBankLabBank = ConsumLab                                           # M4_Bank(D,_)ex-Lab-Com-Bank: bank decrease from buying good
    stateNew.AccBankLabBank = state.AccBankLabBank + inAccBankLabBank - outAccBankLabBank   # state update
    # Bank account of Res (liability)
    inAccBankResBank = InvestmentRes                                        # M1_Bank(_,C)ex-Res-Com-Bank: bank increase from seeling resources
    outAccBankResBank = ConsumRes                                           # M2_Bank(D,_)ex-Res-Com-Bank: bank decrease from buying good
    stateNew.AccBankResBank = state.AccBankResBank + inAccBankResBank - outAccBankResBank   # state update
    # Bank account of Cap (liability)
    inAccBankCapBank = DividendIncome                                       # M6_Bank(_,C)ex-Cap-Com-Bank: bank increase from dividend income
    outAccBankCapBank = ConsumCap                                           # M8_Bank(D,_)ex-Com-Cap-Bank: bank decrease from buying good
    stateNew.AccBankCapBank = state.AccBankCapBank + inAccBankCapBank - outAccBankCapBank   # state update
    # Remember variables of interest and states
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
    plots = Plots.Plot{Plots.GRBackend}[]                       # create empty container for plots
    nms = names(sim)                                            # column names (variables)  
    for c in 2:ncol(sim)                                        # plot all but the first (:Period) variables
        push!(plots, plot(sim[:, :Period], sim[:, c], label=String(nms[c])))  # add a plot for each variable (y) against :Periods (x)
    end
    plot(plots...)                                              # show all plots
end;
# ------------------------------------------------------------------------------------------------------------
# Simulate
sim = simulate(StateTransition, State(Parameters=Pars), 100);   # state transition, initial state with parameters, 100 periods to simulate
vars = [:Period, :Investment, :DividendPayment];                # variables to print and plot
# Print and plot results
sim[1:100, vars]                                                # print dataframe (11 of 100 simulated periods)
plotVars(sim[:, vars])                                          # plot variables (all simulated periods)
sim

# Categorical Structures
abstract type CategoryObject end
abstract type CategoryMorphism end

# Objects represent accounts and economic entities
struct Account <: CategoryObject
    name::String
    agent::String
    type::String  # "asset" or "liability"
    unit::String  # "nominal" or "real"
    value::Float64
end

# Morphisms represent flows and transformations
struct Flow <: CategoryMorphism
    name::String
    source::Account
    target::Account
    value::Float64
    description::String
end

# Categorical composition of flows
function compose(f::Flow, g::Flow)
    if f.source != g.target
        error("Flows not composable")
    end
    return Flow(
        string(f.name, "∘", g.name),
        g.source,
        f.target,
        f.value,
        string("Composition: ", g.description, " followed by ", f.description)
    )
end

# Natural transformations between different accounting perspectives
struct AccountingPerspective
    name::String
    objects::Vector{Account}
    morphisms::Vector{Flow}
end

# Functor between accounting systems
function accounting_functor(source::AccountingPerspective, target::AccountingPerspective)
    # Map objects (accounts)
    object_map = Dict{Account,Int}()
    for src in source.objects
        idx = findfirst(t -> t.name == src.name, target.objects)
        if idx !== nothing
            object_map[src] = idx
        end
    end

    # Map morphisms (flows)
    morphism_map = Dict{Flow,Flow}()
    for m in source.morphisms
        if haskey(object_map, m.source) && haskey(object_map, m.target)
            morphism_map[m] = Flow(
                m.name,
                target.objects[object_map[m.source]],
                target.objects[object_map[m.target]],
                m.value,
                m.description
            )
        end
    end

    return (object_map, morphism_map)
end

# Categorical balance checker
function check_categorical_balance(perspective::AccountingPerspective)
    # Check object-level balance
    for obj in perspective.objects
        inflows = sum(m.value for m in perspective.morphisms if m.target == obj)
        outflows = sum(m.value for m in perspective.morphisms if m.source == obj)
        if abs(inflows - outflows) > 1e-10
            error("Balance violation in $(obj.name)")
        end
    end

    # Check composition balance
    for f in perspective.morphisms
        for g in perspective.morphisms
            if f.source == g.target
                composed = compose(f, g)
                direct = findfirst(m -> m.source == g.source && m.target == f.target,
                    perspective.morphisms)
                if direct !== nothing && abs(composed.value - perspective.morphisms[direct].value) > 1e-10
                    error("Composition violation")
                end
            end
        end
    end
    return true
end

# Create perspectives from simulation data
function create_perspectives(sim::DataFrame, period::Int)
    row = sim[period+1, :]  # +1 because periods start at 0

    # Create accounts
    accounts = Account[
        Account("LabBank", "Lab", "asset", "nominal", row.AccLabBank),
        Account("LabLab", "Lab", "asset", "real", row.AccLabLab),
        Account("LabGood", "Lab", "asset", "real", row.AccLabGood),
        Account("ResBank", "Res", "asset", "nominal", row.AccResBank),
        Account("ResRes", "Res", "asset", "real", row.AccResRes),
        Account("ResGood", "Res", "asset", "real", row.AccResGood),
        Account("ComBank", "Com", "asset", "nominal", row.AccComBank),
        Account("ComLoan", "Com", "liability", "nominal", row.AccComLoan),
        Account("ComDiv", "Com", "liability", "nominal", row.AccComDiv),
        Account("ComRes", "Com", "asset", "real", row.AccComRes),
        Account("ComLab", "Com", "asset", "real", row.AccComLab),
        Account("ComGood", "Com", "asset", "real", row.AccComGood),
        Account("CapBank", "Cap", "asset", "nominal", row.AccCapBank),
        Account("CapDiv", "Cap", "asset", "nominal", row.AccCapDiv),
        Account("CapGood", "Cap", "asset", "real", row.AccCapGood)
    ]

    # Create flows
    flows = Flow[]

    # Add major flows
    push!(flows, Flow("WagePayment",
        accounts[findfirst(a -> a.name == "ComBank", accounts)],
        accounts[findfirst(a -> a.name == "LabBank", accounts)],
        row.WagesPayment,
        "M3: Wage payment from company to labor"))

    push!(flows, Flow("Investment",
        accounts[findfirst(a -> a.name == "ComLoan", accounts)],
        accounts[findfirst(a -> a.name == "ComBank", accounts)],
        row.Investment,
        "M5: Investment loan to company"))

    push!(flows, Flow("ResourcePayment",
        accounts[findfirst(a -> a.name == "ComBank", accounts)],
        accounts[findfirst(a -> a.name == "ResBank", accounts)],
        row.InvestmentRes,
        "M1: Resource payment from company to resource owner"))

    # Create the micro perspective
    micro = AccountingPerspective("Micro", accounts, flows)

    # Create the macro perspective (aggregated accounts)
    macro_accounts = Account[
        Account("TotalBank", "System", "asset", "nominal",
            sum(a.value for a in accounts if endswith(a.name, "Bank"))),
        Account("TotalReal", "System", "asset", "real",
            sum(a.value for a in accounts if a.unit == "real")),
        Account("TotalNominal", "System", "asset", "nominal",
            sum(a.value for a in accounts if a.unit == "nominal"))
    ]

    macro_flows = Flow[
        Flow("NetInvestment",
        macro_accounts[1],  # TotalBank
        macro_accounts[2],  # TotalReal
        row.Investment - row.RepaysPayment,
        "Net investment flow")
    ]

    macro_perspective = AccountingPerspective("Macro", macro_accounts, macro_flows)

    return (micro, macro_perspective)
end

# Analyze and visualize categorical structures
function analyze_categorical_structure(sim::DataFrame)
    periods = 0:nrow(sim)-1
    results = Dict{String,Vector{Float64}}()

    # Initialize result vectors
    results["micro_balance"] = Float64[]
    results["macro_balance"] = Float64[]
    results["functor_preservation"] = Float64[]

    for period in periods
        micro, macro_perspective = create_perspectives(sim, period)

        # Check balances
        push!(results["micro_balance"],
            sum(obj.value for obj in micro.objects if obj.type == "asset") -
            sum(obj.value for obj in micro.objects if obj.type == "liability"))

        push!(results["macro_balance"],
            sum(obj.value for obj in macro_perspective.objects))

        # Check functor preservation
        object_map, morphism_map = accounting_functor(micro, macro_perspective)
        preservation = all(haskey(morphism_map, m) && abs(m.value - morphism_map[m].value) < 1e-10
                           for m in micro.morphisms)
        push!(results["functor_preservation"], Float64(preservation))
    end

    # Create visualization
    p1 = plot(periods, results["micro_balance"],
        label="Micro Balance", title="Categorical Balance Analysis")
    plot!(p1, periods, results["macro_balance"],
        label="Macro Balance")

    p2 = plot(periods, results["functor_preservation"],
        label="Functor Preservation", title="Categorical Structure Preservation")

    plot(p1, p2, layout=(2, 1), size=(800, 600))
    savefig("simulation_data/categorical_analysis.png")

    return results
end

# Load the original simulation code
include("momascf.jl")

# Run the simulation
sim = simulate(StateTransition, State(Parameters=Pars), 100)

# Analyze categorical structures
results = analyze_categorical_structure(sim)

# Save results
save_simulation_data(sim, "simulation_data/categorical_data")

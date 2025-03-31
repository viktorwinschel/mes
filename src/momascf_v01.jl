# ---------------------------------------------------------------------
# MoMa
# Monetäre Makrobuchhaltung in Supply Chain Finance (MoMaSCF)
# Supply Chain Finance, Lieferkettenfinanzierung
# ---------------------------------------------------------------------
using DataFrames    # Simulierte Zeitreihen
using Plots         # Visualisierung der Zeitreihen
using Parameters    # Initialisierung der Zustandsvariablen
using CSV
# ---------------------------------------------------------------------
#= 5 Agenten, (3,3,6,3,5) Konten, Buchungen
cap: Capital : capitalist investor
com: Company : producer
lab: Labor : worker, household
res: Resource : Ressourcen, material supplier
bank: Bank : Zentralbank nicht nötig, erst mit Bargeld
Konten:
VGR konten der Makrobuchhaltung: aktiv und passiv
real oder nominal
Buchungen:
monetären Makrobuchhaltung sind eine oder zwei Buchungen 
auf den aktiven und passiven Konten der Mikrobuchhaltung
Forderungen und Verbindlichkeiten
Auszahlungen und Einzahlungen
sind Makroinvarianzen
=#
# ---------------------------------------------------------------------
# Parameter
Pars = (
    InvestmentLen=10, # Länge und Anzahl (später) von Investitionen
    # Vektor implementiert Speicher (als FILO Stack) für die
    # Rückzahlung von Investitionen und Bezahlung von Löhnen
    LabResourceRatio=0.2, # Verhältnis Löhne zu Ressourcen
    ConsumRatioRes=0.8, # Verhältnis Ressourcen zu Konsum
    ConsumRatioLab=0.95, # Verhältnis Löhne zu Konsum
    ConsumRatioCap=0.6, # Verhältnis Dividenden zu Konsum
    MarkUp=0.5, # Markup
    DivRateDiff=0.15, # Dividendenrate für Unternehmen
    DivRateBank=0.4, # Dividendenrate für Banken    
    WindFallProfit=0.5, # Windfall Profit
    sigA=20.0,  # sigm lern Parameter Investitionen (demand gap)
    sigB=480.0, # sigm lern Parameter Investitionen (demand gap)
    sigC=200.0, # sigm lern Parameter Investitionen (demand gap)
    ResourcePrice=25.0, # Preis Ressourcen
    LaborPrice=12.0, # Preis Löhne
    InitialGoodPrice=30.0, # Anfangspreis Produkte
    LabResSubstProd=0.75,  # Elastizität der Substitution
    ScaleProd=0.42, # Skalierungsparameter 
    DecayGoodLab=0.95, # Abschreibung Labor
    DecayGoodRes=0.7, # Abschreibung Ressourcen
    DecayGoodCap=0.6, # Abschreibung Kapital
    ReNewRes=100.0, # neue Ressourcen jede Periode
    ReNewLab=100.0, # neue Labor jede Periode
);
# ---------------------------------------------------------------------
@with_kw mutable struct State
    Parameters::Any
    # history wage payments
    wageHist::Vector{Float64} = zeros(Parameters.InvestmentLen)
    # history loan repayments             
    repayHist::Vector{Float64} = zeros(Parameters.InvestmentLen)
    #                           agent, account, type, unit
    AccLabBank::Float64 = 0.0 # labour, bank, asset, nom
    AccLabLab::Float64 = 0.0 # labour, labor, asset, real           
    AccLabGood::Float64 = 0.0 # labour, goods, asset, real      
    AccResBank::Float64 = 0.0 # resourcer, bank, asset, nom
    AccResRes::Float64 = 0.0 # resourcer, resources, asset, real      
    AccResGood::Float64 = 0.0 # resourcer, goods, asset, real      
    AccComBank::Float64 = 0.0 # company, bank, asset, nom
    AccComLoan::Float64 = 0.0 # company, loan, liab, nom
    AccComDiv::Float64 = 0.0 # company, dividend, liab, nom
    AccComRes::Float64 = 20.0 # company, resource, asset, real       
    AccComLab::Float64 = 110.0 # company, labor, asset, real      
    AccComGood::Float64 = 0.0 # company, good, asset, real      
    AccCapBank::Float64 = 0.0 # capital, bank, asset, nom
    AccCapDiv::Float64 = 0.0 # capital, dividend, asset, nom
    AccCapGood::Float64 = 0.0 # capital, goods, asset, real
    AccBankComLoan::Float64 = 0.0 # bank, loan, company, asset, nom
    AccBankComBank::Float64 = 0.0 # bank, company, liab, nom
    AccBankLabBank::Float64 = 0.0 # bank, labor, liab, nom
    AccBankResBank::Float64 = 0.0 # bank, resourcer, liab, nom
    AccBankCapBank::Float64 = 0.0 # bank, capital, liab, nom
end;
# ---------------------------------------------------------------------
function StateTransition(sim, state, period)
    pars = state.Parameters                                                     
    stateNew = State(Parameters=pars)                                           
    # Invarianzen: Aktiv, Passive, Forderungen, Verbindlichkeiten
    # WagesPayment, RepaysPayment
    # ConsumRes, ConsumLab, ConsumCap, Demand 
    # Capital Bank Invarianz
    InvCapBank = state.AccCapBank - state.AccBankCapBank                        
    # Resourcer Bank Invarianz
    InvResBank = state.AccResBank - state.AccBankResBank                        
    # Company Bank Invarianz
    InvComBank = state.AccComBank - state.AccBankComBank                        
    # Company Loan Invarianz
    InvComLoan = state.AccBankComLoan - state.AccComLoan                       
    # Labor Bank Invarianz
    InvLabBank = state.AccLabBank - state.AccBankLabBank                       
    # Makro Accounting Aktiv, Passiv Invarianz
    InvMacro = InvCapBank + InvResBank 
             + InvComBank + InvComLoan + InvLabBank  
    # Wage History
    WagesPayment = sum(state.wageHist)                                         
    # Repayments Investment History
    RepaysPayment = sum(state.repayHist)                                       
    # Consumption of resourcer
    ConsumRes = state.AccResBank * pars.ConsumRatioRes                         
    # Consumption of Labor
    ConsumLab = state.AccLabBank * pars.ConsumRatioLab                         
    # Consumption of Capital
    ConsumCap = state.AccCapBank * pars.ConsumRatioCap                         
    # Demand
    Demand = ConsumRes + ConsumLab + ConsumCap                                 
    # Produktion (Cobb-Douglas)
    GoodProduction = 
        1 + pars.ScaleProd * state.AccComLab^pars.LabResSubstProd *
        state.AccComRes^(1 - pars.LabResSubstProd)
    # Markt
    # Kosten(Löhne,Abschreibung) * Markup
    DemandPlan = (WagesPayment + RepaysPayment) * (1 + pars.MarkUp)         
    # Nachfrageüberschuss
    DemandSurplus = Demand - DemandPlan                                 
    # Preis
    GoodPrice = (
        (period == 0 ? pars.InitialGoodPrice : 0.0)
        + DemandPlan / GoodProduction
        + ((DemandSurplus > 0.0) 
        ? (DemandSurplus * pars.WindFallProfit) : 0.0))
    # Investment
    Investment = 
        pars.sigA + pars.sigB / (1.0 + exp(-DemandSurplus / pars.sigC))
    # Modellierung linearer Wachstum von Periode 40 bis 60
    # zufällig möglich
    # Investitionen für Ressourcen
    InvestmentRes2 = Investment * (1 - pars.LabResourceRatio)               
    # used in VenSim code / model (InvestmentRes2 is superfluous)
    InvestmentRes = InvestmentRes2                                          
    # Investitionen für Labor
    InvestmentLab = Investment * pars.LabResourceRatio                      
    # Rückzahlung der Investitionen
    Repayment = Investment / pars.InvestmentLen                            
    # Update History
    # push new element to history, drop last: p2H([2,1],3)=[3,2] 
    p2H(hist, newelem) = [newelem; hist[1:end-1]]                           
    # Update Lohnzahlungshistorie
    stateNew.wageHist = p2H(state.wageHist, InvestmentLab)                  
    # Update Rückzahlungshistorie
    stateNew.repayHist = p2H(state.repayHist, Repayment)                   
# ---------------------------------------------------------------------
    #=
    Makro Accounting
    Erklärung der Buchungen:
    Beispiele:   M5_Com(D,_)ex-Com-Bank: money inflow investment
                M4_Lab(_,C)ex-Lab-Com-Bank: money outflow buying good

     'M5' Makrobuchung von Com and Bank
     Mikrobuchaltungen von Agenten Com und Bank
     'D'ebit von Com
     'money inflow of investment' ist ein Kommentar

     'M4' Makrobuchung von Lab und Bank
     Mikrobuchaltungen von Agenten Lab und Bank
     'C'redit von Lab
     'money outflow from buying good' ist ein Kommentar
     =#
# ---------------------------------------------------------------------
    # - Lab
    # --- Bank account (asset)
    # M3_Lab(D,_)ex-Lab-Com-Bank: money inflow from selling labour
    inAccLabBank = WagesPayment                                             
    # M4_Lab(_,C)ex-Lab-Com-Bank: money outflow from buying good
    outAccLabBank = ConsumLab                                               
    # state update
    stateNew.AccLabBank = 
        state.AccLabBank + inAccLabBank - outAccLabBank   
    # --- Labour account (asset)
    # new labour each period 
    inAccLabLab = pars.ReNewLab                                             
    # M3_Lab(_,C)ex-Lab-Com-Bank: labour outflow from selling labour
    outAccLabLab = WagesPayment / pars.LaborPrice                           
    # state update
    stateNew.AccLabLab = 
        state.AccLabLab + inAccLabLab - outAccLabLab      
    # --- Good account (asset)
    # M4_Lab(D,_)ex-Lab-Com-Bank: good inflow from buying good
    inAccLabGood = ConsumLab / GoodPrice                                    
    outAccLabGood = state.AccLabGood * pars.DecayGoodLab                   
    # state update
    stateNew.AccLabGood = 
        state.AccLabGood + inAccLabGood - outAccLabGood  
# ---------------------------------------------------------------------
    # - Res
    # --- Bank account (asset)
    # M1_Res(D,_)ex-Res-Com-Bank: money inflow from selling resources
    inAccResBank = InvestmentRes                                            
    # M2_Res(_,C)ex-Res-Com-Bank: money outflow from buying good
    outAccResBank = ConsumRes                                              
    # state update
    stateNew.AccResBank = 
        state.AccResBank + inAccResBank - outAccResBank  
    # --- Resource account (asset)
    # new resources each period 
    inAccResRes = pars.ReNewRes                                             
    # M1_Res(_,C)ex-Res-Com-Bank: resources outflow from selling resources
    outAccResRes = InvestmentRes / pars.ResourcePrice                      
    # state update
    stateNew.AccResRes = 
        state.AccResRes + inAccResRes - outAccResRes      
    # --- Good account (asset)
    # M2_Res(D,_)ex-Res-Com-Bank: good inflow from buying good
    inAccResGood = ConsumRes / GoodPrice                                   
    # decay of good of Res                                                         
    outAccResGood = state.AccResGood * pars.DecayGoodRes                   
    # state update
    stateNew.AccResGood = 
        state.AccResGood + inAccResGood - outAccResGood  
# ---------------------------------------------------------------------
    # - Com
    # --- dividend payment of the company (decided one period before)
    DividendPayment = state.AccComDiv                                       
    # --- Bank account (asset)
    inAccComBank = (
        Investment   # M5_Com(D,_)ex-Com-Bank: 
                     # money inflow from investment
        + ConsumLab  # M4_Com(D,_)ex-Lab-Com-Bank: 
                     # money inflow selling good
        + ConsumRes  # M2_Com(D,_)ex-Res-Com-Bank: 
                     # money inflow selling good
        + ConsumCap) # M8_Com(D,_)ex-Com-Cap-Bank: 
                     # money inflow selling good
    outAccComBank = (
        InvestmentRes     # M1_Com(_,C)ex-Res-Com-Bank: 
                          # money outflow buying resources
        + WagesPayment    # M3_Com(_,C)ex-Lab-Com-Bank: 
                          # money outflow buying labour
        + DividendPayment # M6_Com(_,C)ex-Cap-Com-Bank: 
                          # money outflow dividend payment
        + RepaysPayment)  # M7_Com(_,C)ex-Com-Bank: 
                          # money outflow repayment                                                                                                                                                                                                                                    
    # state update
    Diff = inAccComBank - outAccComBank
    stateNew.AccComBank = state.AccComBank + Diff                          
    # --- Dividend account (liability)
    DividendDecision = (
        (Diff > 0.0 ? (Diff * pars.DivRateDiff) : 0.0)
        + ((state.AccComBank > 0) 
            ? (state.AccComBank * pars.DivRateBank) 
            : 0.0))
    # dividend decision
    inAccComDiv = DividendDecision                                          
    # M6_Com(D,_)ex-Cap-Com-Bank: dividend outflow from dividend payment
    outAccComDiv = DividendPayment                                         
    # state update
    stateNew.AccComDiv = 
        state.AccComDiv + inAccComDiv - outAccComDiv      
    # --- Loan account (liability)
    # M5_Com(_,C)ex-Com-Bank: loan increase from investment
    inAccComLoan = Investment                                               
    # M7_Com(D,_)ex-Com-Bank: loan decrease from repayment
    outAccComLoan = RepaysPayment                                           
    # state update
    stateNew.AccComLoan = 
        state.AccComLoan + inAccComLoan - outAccComLoan   
    # --- Resource account (asset)
    # M1_Com(D,_)ex-Res-Com-Bank: resource inflow from buying resources
    inAccComRes = InvestmentRes / pars.ResourcePrice                        
    # resources usage in production
    outAccComRes = state.AccComRes                                         
    # state update
    stateNew.AccComRes = 
        state.AccComRes + inAccComRes - outAccComRes      
    # --- Labour account (asset)
    # M3_Com(D,_)ex-Lab-Com-Bank: labour inflow from buying labour
    inAccComLab = WagesPayment / pars.LaborPrice                            
    # labour usage in production
    outAccComLab = state.AccComLab                                         
    # state update
    stateNew.AccComLab = 
        state.AccComLab + inAccComLab - outAccComLab      
    # --- Good account (asset)
    inAccComGood = GoodProduction
    outAccComGood = (
        ConsumRes                # M2_Com(_,C)ex-Res-Com-Bank: 
                                 # good outflow from selling good
        + ConsumLab              # M4_Com(_,C)ex-Lab-Com-Bank: 
                                 # good outflow from selling good
        + ConsumCap) / GoodPrice # M8_Com(_,C)ex-Com-Cap-Bank: 
                                 # good outflow from selling good                                                                     
    # state update
    stateNew.AccComGood = 
        state.AccComGood + inAccComGood - outAccComGood   
# ---------------------------------------------------------------------
    # - Cap
    # --- Dividend account (asset)
    # dividend income
    DividendIncome = state.AccCapDiv                                        
    # --- Dividend account (asset)
    # devidend decision
    inAccCapDiv = DividendDecision                                          
    # M6_Cap(_,C)ex-Cap-Com-Bank: dividend outflow dividend payment
    outAccCapDiv = DividendIncome                                          
    # state update
    stateNew.AccCapDiv = 
        state.AccCapDiv + inAccCapDiv - outAccCapDiv      
    # --- Bank account (asset)
    # M6_Cap(D,_)ex-Cap-Com-Bank: money inflow dividend payment 
    inAccCapBank = DividendIncome                                           
    # M8_Cap(_,C)ex-Com-Cap-Bank: money outflow buying good
    outAccCapBank = ConsumCap                                              
    # state update
    stateNew.AccCapBank = 
        state.AccCapBank + inAccCapBank - outAccCapBank  
    # --- Good account (asset)
    inAccCapGood = ConsumCap / GoodPrice # M8_cap(D,_)ex-Com-Cap-Bank, good inflow from buying good                        
    # decay of good of Cap
    outAccCapGood = state.AccCapGood * pars.DecayGoodCap                   
    # state update
    stateNew.AccCapGood = 
        state.AccCapGood + inAccCapGood - outAccCapGood  
# ---------------------------------------------------------------------
    # - Bank
    # --- Loan account of Com (asset)
    # M5_Bank(D,_)ex-Com-Bank: loan increase giving investment
    inAccBankComLoan = Investment                                           
    # M7_Bank(_,C)ex-Com-Bank: loan decrease repayment
    outAccBankComLoan = RepaysPayment                                       
    # state update
    stateNew.AccBankComLoan = 
        state.AccBankComLoan + inAccBankComLoan - outAccBankComLoan   
    # --- Bank account of Com (liability)
    inAccBankComBank = (
        Investment          # M5_Bank(_,C)ex-Com-Bank: 
                            # bank increase getting investment 
        + ConsumRes         # M2_Bank(_,C)ex-Res-Com-Bank: 
                            # bank increase selling good
        + ConsumLab         # M4_Bank(_,C)ex-Lab-Com-Bank: 
                            # bank increase selling good
        + ConsumCap)        # M8_Bank(_,C)ex-Com-Cap-Bank: 
                            # bank increase selling good                                                                                                                                                                                                                                                   
    outAccBankComBank = (
        InvestmentRes       # M1_Bank(D,_)ex-Res-Com-Bank: 
                            # bank decrease buying resources
        + WagesPayment      # M3_Bank(D,_)ex-Lab-Com-Bank: 
                            # bank decrease buying labour
        + DividendPayment   # M6_Bank(D,_)ex-Cap-Com-Bank: 
                            # bank decrease dividend income
        + RepaysPayment)    # M7_Bank(D,_)ex-Com-Bank: 
                            # bank decrease repayment            
    # state update                                                                                                                                                                                                                           
    stateNew.AccBankComBank = 
        state.AccBankComBank + inAccBankComBank - outAccBankComBank   
    # --- Bank account of Lab (liability)
    inAccBankLabBank = WagesPayment                                         
    # M3_Bank(_,C)ex-Lab-Com-Bank: 
    # bank increase from seeling labour
    outAccBankLabBank = ConsumLab                                           
    # M4_Bank(D,_)ex-Lab-Com-Bank: 
    # bank decrease from buying good
    # state update
    stateNew.AccBankLabBank = 
        state.AccBankLabBank + inAccBankLabBank - outAccBankLabBank   
    # --- Bank account of Res (liability)
    inAccBankResBank = InvestmentRes                                        
    # M1_Bank(_,C)ex-Res-Com-Bank: bank increase seeling resources
    outAccBankResBank = ConsumRes                                           
    # M2_Bank(D,_)ex-Res-Com-Bank: bank decrease buying good
    # state update
    stateNew.AccBankResBank = 
        state.AccBankResBank + inAccBankResBank - outAccBankResBank   
    # --- Bank account of Cap (liability)
    inAccBankCapBank = DividendIncome                                       
    # M6_Bank(_,C)ex-Cap-Com-Bank: bank increase dividend income
    outAccBankCapBank = ConsumCap                                           
    # M8_Bank(D,_)ex-Com-Cap-Bank: bank decrease buying good
    # state update
    stateNew.AccBankCapBank = 
        state.AccBankCapBank + inAccBankCapBank - outAccBankCapBank   
# ---------------------------------------------------------------------
    # Variables of interest, States
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
        push!(plots
        , plot(sim[:, :Period], sim[:, c], label=String(nms[c])))  
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

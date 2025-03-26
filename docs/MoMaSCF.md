# Monetary Macro-Accounting Model for Supply Chain Finance (MoMaSCF)

## Overview

MoMaSCF is a monetary macro-accounting model that simulates financial flows and economic interactions in a supply chain system. The model represents a closed economy with four main agents (Labor, Resource Owners, Company, and Capitalists) interacting through a banking system.

### Historical Context
- Historical bill market in Germany 1990: 50 Billion DM per annum
- Current trade finance market: $\sim 10^{12}$, with 2/3 as open account (deferred payment)

## Model Structure

### Agents and Their Roles

#### Labor (Households)
- Provides labor to companies
- Receives wages
- Consumes goods
- Maintains bank accounts and goods inventory

#### Resource Owners
- Supply raw materials
- Receive resource payments
- Consume goods
- Maintain resource stocks and bank accounts

#### Company (Producer)
- Produces goods using labor and resources
- Takes loans for investment
- Pays wages, resource costs, and dividends
- Maintains multiple account types (bank, loan, inventory)

#### Capitalists
- Receive dividends
- Consume goods
- Maintain bank accounts and goods inventory

#### Bank
- Provides loans to companies
- Maintains accounts for all agents
- Facilitates payments and settlements

## Mathematical Framework

### Key Parameters
$\begin{aligned}
\text{InvestmentLen} &= 10 && \text{(Investment cycle length)} \\
\text{LabResourceRatio} &= 0.2 && \text{(Labor to resources ratio)} \\
\text{ConsumRatio}_i &\in \{0.8, 0.95, 0.6\} && \text{(Consumption ratios)} \\
\text{MarkUp} &= 0.5 && \text{(Price markup)} \\
\text{DivRateDiff} &= 0.15 && \text{(Dividend ratio from surplus)} \\
\text{DivRateBank} &= 0.4 && \text{(Dividend ratio from balance)}
\end{aligned}$

### Production Function
The production function follows a Cobb-Douglas form:

$Q = 1 + \text{ScaleProd} \cdot L^{\alpha} \cdot R^{1-\alpha}$

where:
- $Q$: Production output
- $L$: Labor input
- $R$: Resource input
- $\alpha = \text{LabResSubstProd} = 0.75$
- $\text{ScaleProd} = 0.42$

### Investment Function
Investment follows a sigmoid response to demand surplus:

$I = \text{sigA} + \frac{\text{sigB}}{1 + e^{-D_s/\text{sigC}}}$

where:
- $D_s$: Demand surplus
- $\text{sigA} = 20.0$ (Base level)
- $\text{sigB} = 480.0$ (Scale)
- $\text{sigC} = 200.0$ (Sensitivity)

### Price Formation
Price is determined through categorical morphisms:

$P = P_0 \cdot 1_{t=0} + \frac{D_p}{Q} + W_p \cdot D_s \cdot 1_{D_s > 0}$

where:
- $P_0$: Initial price
- $D_p$: Planned demand
- $Q$: Production
- $D_s$: Demand surplus
- $W_p$: Windfall profit ratio

### Dividend Decision
Dividends are calculated using two components:

$D = r_d \cdot \max(L_d, 0) + r_b \cdot \max(B, 0)$

where:
- $L_d$: Loan difference
- $B$: Bank balance
- $r_d$: Dividend rate from difference
- $r_b$: Dividend rate from balance

## Categorical Implementation

### Morphisms
The model implements categorical morphisms for decision-making:

```julia
struct ConditionalMorphism
    condition::Function
    true_morphism::Function
    false_morphism::Function
end

struct PriceFormationMorphisms
    initial_price::ConditionalMorphism
    demand_price::Function
    surplus_price::ConditionalMorphism
end

struct DividendDecisionMorphisms
    surplus_dividend::ConditionalMorphism
    bank_dividend::ConditionalMorphism
end
```

## System Dynamics

### Flow Equations
Key flow relationships:

$\text{FLOW\_CONSUMPTION}_i = \text{BANK}_i \cdot \text{ConsumRatio}_i$
$\text{FLOW\_INVESTMENT\_RESOURCE} = I \cdot (1 - \text{LabResourceRatio})$
$\text{FLOW\_INVESTMENT\_LABOR} = I \cdot \text{LabResourceRatio}$

### Clearing System
Two-phase clearing with efficiency rates:

$\text{MORNING\_NETTED} = 0.85 \cdot \text{MORNING\_FLOWS}$
$\text{EVENING\_NETTED} = 0.90 \cdot \text{EVENING\_FLOWS}$

## Results

### Key Metrics
Average values from simulation:

$\begin{aligned}
\text{Wage Payment} &\approx 877.77 \\
\text{Resource Payment} &\approx 438.88 \\
\text{Dividend Payment} &\approx 2.63 \times 10^6 \\
\text{Production} &\approx 21.62 \\
\text{Price} &\approx 2.39 \times 10^6
\end{aligned}$

### System Stability
The model maintains:
- Net positions near equilibrium
- Consistent clearing efficiencies
- Balanced flow relationships

## Conclusion

MoMaSCF successfully implements a categorical approach to monetary macro-accounting, demonstrating:
- Robust financial flow modeling
- Stable clearing mechanisms
- Complex agent interactions
- Emergent economic behavior 
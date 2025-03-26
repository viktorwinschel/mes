# National Accounting as Memory Evolutive System

This document describes the categorical structures that connect national accounting with Memory Evolutive Systems (MES).

## Hierarchical Structure

The national accounting system forms a hierarchical category with three levels:

```math
\begin{array}{ccc}
C_{micro} & \to & C_{meso} & \to & C_{macro}
\end{array}
```
in 
where:
```math
\begin{array}{rcl}
C_{micro} & = & Individual Transactions \\
C_{meso} & = & Institutional Sectors \\
C_{macro} & = & National Accounts
\end{array}
```

## Micro-Macro Bridge

The connection between micro and macro levels is given by:

```math
\begin{array}{ccc}
Transaction & \to & MacroFlow \\
\downarrow & & \downarrow \\
Account & \to & Institution
\end{array}
```

## Classifier Structure

The classification of transactions:

```math
\begin{array}{ccc}
Transaction & \to & Type \\
\downarrow & & \downarrow \\
1 & \to & Class
\end{array}
```

Classification rules:
```math
\begin{array}{rcl}
type(t) & = & \begin{cases}
asset & \text{if increases net worth} \\
liability & \text{if decreases net worth} \\
income & \text{if adds to current} \\
expense & \text{if subtracts from current}
\end{cases}
\end{array}
```

## CoRegulator Structure

The self-healing mechanism has:

```math
\begin{array}{rcl}
L(C) & = & \sum Balance(A) \\
S(A) & = & min\{f: A \to B\} \\
U(C) & : & L \times T \to L
\end{array}
```

The coregulator maintains balance:

```math
\begin{array}{ccc}
C^0 & \to & C^1 & \to & C^2 \\
Accounts & & Flows & & Balances
\end{array}
```

with:
```math
\begin{array}{rcl}
d^0(a) & = & \sum_{out} f - \sum_{in} g \\
d^1(f) & = & target(f) - source(f)
\end{array}
```

## Pattern Matching

Transaction patterns are identified through:

```math
\begin{array}{ccc}
Pattern & \to & Transactions \\
\downarrow & & \downarrow \\
colim(P) & \to & Complex
\end{array}
```

## Double Entry Structure

Double entry bookkeeping:

```math
\begin{array}{ccc}
Entry & \to & Debit \\
\downarrow & & \downarrow \\
Credit & \to & Balance
\end{array}
```

## Binding Operations

Account bindings:

```math
\begin{array}{ccc}
A_t & \to & S_t \\
\downarrow & & \downarrow \\
A_{t+1} & \to & S_{t+1}
\end{array}
```

## Evolution

The system evolution:

```math
\begin{array}{ccc}
C_t & \to & C_{t+1} \\
\downarrow & & \downarrow \\
S & \to & S
\end{array}
```

## Stability Conditions

The system maintains:

```math
\begin{array}{rcl}
Balance(A) & = & \sum in - \sum out = 0 \\
NetWorth(S) & = & \sum Assets - \sum Liabilities \\
GDP & = & \sum ValueAdded
\end{array}
```

## Implementation

The categorical structures are implemented in Julia as:

```julia
struct Transaction{T}
    source::Account
    target::Account
    amount::Float64
    type::TransactionType
    timestamp::Float64
end

struct CoRegulator{T}
    landscape::Dict{Account, Float64}
    threshold::Float64
    decay::Float64
    update::Function
end

struct Pattern{T}
    objects::Vector{Account}
    morphisms::Dict{Tuple{Account,Account}, Vector{Transaction}}
    colimit::Union{Nothing, Transaction}
end
```

## Invariants

The system maintains:

```math
\begin{array}{rcl}
H^0 & = & Ker(d^0) = constant \\
H^1 & = & Ker(d^1)/Im(d^0) = balanced \\
H^2 & = & Coker(d^1) = invariant
\end{array}
``` 
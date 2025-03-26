# MOMAT: Monetary Macro System

This document describes the categorical structure of the Monetary Macro System (MOMAT) and its relationship to national accounting.

## Category Structure

The MOMAT system is modeled as a category C with:

```math
\begin{array}{rcl}
C & = & (Obj, Mor, \circ, id) \\
Obj & = & Accounts \cup Agents \\
Mor & = & Flows \cup Transactions
\end{array}
```

## Economic Agents

The system includes several economic agents:

```math
\begin{array}{rcl}
Agents & = & \{Lab, Res, Cap, Com, Bank\} \\
Accounts(a) & = & \{Bank, Good, Div, Loan, Res, Lab\}
\end{array}
```

## Flow Structure

Financial flows:

```math
\begin{array}{ccc}
Source & \to & Target \\
\downarrow & & \downarrow \\
R & \to & R
\end{array}
```

## Production

The production process:

```math
\begin{array}{rcl}
P(Good) & = & 1 + Scale \cdot Lab^a \cdot Res^{1-a} \\
P(f) & = & Prod(f) \cdot Input(A)
\end{array}
```

## Investment

The investment decision:

```math
\begin{array}{ccc}
Demand & \to & Production \\
\downarrow & & \downarrow \\
R & \to & R
\end{array}
```

with:
```math
Investment = A + \frac{B}{1 + e^{-D/C}}
```

## Balance Sheet

The balance sheet:

```math
\begin{array}{rcl}
B(Account) & = & R \\
B(f: A \to B) & = & +f
\end{array}
```

## Implementation

The system is implemented in Julia with the following structures:

```julia
@with_kw mutable struct State
    Parameters::NamedTuple
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
end
```

## Invariants

The system maintains:

```math
\begin{array}{rcl}
InvCapBank & = & AccCapBank - AccBankCapBank \\
InvResBank & = & AccResBank - AccBankResBank \\
InvComBank & = & AccComBank - AccBankComBank \\
InvComLoan & = & AccBankComLoan - AccComLoan \\
InvLabBank & = & AccLabBank - AccBankLabBank
\end{array}
```

## Macro Invariant

The global invariant:

```math
InvMacro = InvCapBank + InvResBank + InvComBank + InvComLoan + InvLabBank
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

## Connection to MES

The MOMAT system as MES:

```math
\begin{array}{rcl}
Components & = & Accounts \cup Agents \\
Bindings & = & Flows \cup Transactions \\
State(M) & = & Balance(M) \times Flows(M)
\end{array}
``` 
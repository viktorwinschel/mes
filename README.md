# MOMA (Money and Operations Management Analysis)

A Julia package for simulating and analyzing money flows and operations in economic systems using Memory Evolutive Systems (MES) principles.

## Overview

MOMA is a simulation tool that models economic transactions and money flows between different agents in a financial system. It implements a double-entry accounting system and tracks the evolution of balance sheets over time.

## Features

- Agent-based simulation with support for multiple economic actors
- Double-entry accounting system
- Balance sheet tracking and evolution
- Transaction flow analysis
- Visualization of results
- Detailed reporting and statistics

## Installation

```julia
using Pkg
# MOMA (Money and Operations Management Analysis)

A Julia package for simulating and analyzing money flows and operations in economic systems using Memory Evolutive Systems (MES) principles.

## Overview

MOMA is a simulation tool that models economic transactions and money flows between different agents in a financial system. It implements a double-entry accounting system and tracks the evolution of balance sheets over time.

## Features

- Agent-based simulation with support for multiple economic actors
- Double-entry accounting system
- Balance sheet tracking and evolution
- Transaction flow analysis
- Visualization of results
- Detailed reporting and statistics

## Installation

```julia
using Pkg
Pkg.add("MOMA")
```

## Usage

```julia
using MOMA

# Run the simulation
include("src/moma_main.jl")
```

## Project Structure

- `src/moma_simulation.jl`: Core simulation structures and initialization
- `src/moma_events.jl`: Event processing and simulation logic
- `src/moma_visualization.jl`: Visualization and reporting functions
- `src/moma_main.jl`: Main script to run the simulation

## Dependencies

- Julia 1.6 or higher
- Dates
- DataFrames
- Plots

## License

MIT License

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. 

## Testing

To run the tests, use:

```julia
using Pkg
Pkg.test("MOMA")
```

## Micro-Macro Accounting Relationship

This project implements a monetary economics simulation using double-entry bookkeeping principles at both micro and macro levels. It demonstrates how individual accounting practices (micro) give rise to system-wide properties (macro) through categorical relationships.

### Key Concepts

#### Double-Entry Bookkeeping

##### Micro Level (Individual Agent Accounting)
- Each agent (bank, central bank, etc.) maintains their own T-accounts
- Every transaction affects two accounts (debit = credit)
- All accounts within an agent must sum to zero (micro invariance)
- Example:
  ```
  Bank A's books:
  Deposits at Bank B (DR) | 100
  CB Reserve (CR)         | 100
  ```

##### Macro Level (System-wide Accounting)
- Debt relationships always involve exactly two agents (debtor-creditor pairs)
- At macro level, there is no "net debt" - every debt is someone's asset
- Claims between agents must cancel out perfectly (macro invariance)
- Example:
  ```
  Bank A's "Deposits at Bank B" ↔ Bank B's "Deposits from Bank A"
  These must net to zero at system level
  ```

##### Categorical Structure
- Accounts are morphisms between debits and credits
- Transactions are natural transformations between accounts
- Micro invariance is a local colimit (within each agent)
- Macro invariance is a global colimit (across the system)
- The accounting equation emerges from these categorical relationships

#### Implementation Details

##### Account Structure
```julia
mutable struct Account
    name::String
    debit::Float64  # Left side of T-account
    credit::Float64 # Right side of T-account
    transactions::Vector{Dict}
end
```

##### Invariance Checks
- Micro invariance: Verifies that all debits = all credits within each agent
- Macro invariance: Verifies that all debt relationships between agents net to zero

##### Events
The simulation supports various financial events:
- Money creation
- Loans between banks
- Bicycle purchase (real economy transaction)
- Bills of Exchange (BOE) creation and transfer
- Settlement between banks

Each event maintains both micro and macro invariance through proper double-entry bookkeeping.

## References
[Add references to monetary economics papers/books] 
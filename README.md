# MOMA (Monetary Macro Accounting)

A Julia package for simulating and analyzing money flows and operations in monetary economic systems using Memory Evolutive Systems (MES) principles.

## Overview

MOMA is a simulation tool that models economic transactions and money flows between different agents in a financial system. It implements a double-entry accounting system and tracks the evolution of balance sheets over time. The macro economics dynamics are modelled in memory evolutive systems (MES) of Andree Ehresmann and Jean-Paul Vanbremeersch.

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

# MES (Memory Evolutive Systems)

A Julia package for implementing and analyzing Memory Evolutive Systems (MES) in economic contexts.

## Overview

MES is a mathematical framework for modeling complex systems that evolve over time, with particular applications in economic systems. This package provides tools for creating, analyzing, and visualizing MES structures.

## Features

- Category theory-based implementation of MES
- Support for functors and natural transformations
- Economic system modeling capabilities
- Comprehensive documentation and examples

## Installation

```julia
using Pkg
Pkg.add("MES")
```

## Usage

```julia
using MES

# Create a category
C = create_category(["A", "B"], ["f", "g"])

# Add morphisms
add_morphism!(C, "A", "B", "f")
add_morphism!(C, "B", "A", "g")

# Define composition
compose_morphisms!(C, "f", "g", "id_A")
compose_morphisms!(C, "g", "f", "id_B")
```

## Project Structure

- `src/core/`: Core MES implementation
  - `types.jl`: Basic type definitions
  - `category.jl`: Category theory implementation
  - `functor.jl`: Functor implementation
  - `natural_transformation.jl`: Natural transformation implementation
- `src/examples/`: Example usage and demonstrations
- `docs/`: Documentation and papers

## Dependencies

- Julia 1.6 or higher
- Dates
- DataFrames
- Documenter.jl (for documentation)

## Documentation

Documentation is currently being built and will be available soon.

## Papers

The following papers are available in the `papers/` directory:
- `bcbaas25/bcbaas25.pdf`: "Memory Evolutive Systems in Economic Contexts"
- `mes07/mes07.pdf`: "Memory Evolutive Systems"
- `mes23/mes23.pdf`: "Memory Evolutive Systems in Economics"

## License

MIT License

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Testing

To run the tests, use:

```julia
using Pkg
Pkg.test("MES")
``` 
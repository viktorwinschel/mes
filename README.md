# Monetary Macro Accounting with Memory Evolutive Systems (MoMaMES)

A Julia package that implements monetary and economic systems using Memory Evolutive Systems (MES), providing a rigorous mathematical framework for analyzing economic dynamics through category theory.

## Overview

This project combines two powerful frameworks:

1. **MoMa (Monetary Macro Accounting)**
   - Models economic transactions and money flows between agents
   - Implements double-entry accounting at micro and macro levels
   - Tracks balance sheet evolution and transaction flows
   - Provides visualization and analysis tools

2. **MES (Memory Evolutive Systems)**
   - Provides mathematical foundation using category theory
   - Models complex systems that evolve over time
   - Maintains structural relationships and memory
   - Supports functors and natural transformations

## Features

### Economic Features
- Agent-based simulation with multiple economic actors
- Double-entry accounting system at micro and macro levels
- Balance sheet tracking and evolution
- Transaction flow analysis and visualization
- Bills of Exchange (BOE) creation and transfer
- Interbank settlement systems

### Mathematical Features
- Category theory-based implementation
- Functors for time evolution
- Natural transformations for system changes
- Pattern matching and colimit computation
- Memory system implementation

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/viktorwinschel/mes")
```

## Quick Start

```julia
using MES

# Create and run a basic economic simulation
include("examples/national_accounting_example.jl")

# Create a category with economic objects
C = create_category(["Bank", "Firm", "Household"], ["loan", "payment"])

# Add economic morphisms
add_morphism!(C, "Bank", "Firm", "loan")
add_morphism!(C, "Firm", "Household", "payment")
```

## Documentation

Comprehensive documentation is available at:
https://viktorwinschel.github.io/mes/

Key sections:
- Getting Started Guide
- Theory and Mathematical Background
- Examples and Tutorials
- API Reference

## Project Structure

```
mes/
├── src/
│   ├── core/           # Core implementations
│   │   ├── category.jl     # Category theory
│   │   ├── types.jl       # Basic types
│   │   └── memory.jl      # Memory systems
│   └── examples/      # Example implementations
├── docs/             # Documentation
└── test/            # Test suite
```

## Dependencies

- Julia 1.9 or higher
- DataFrames
- Documenter.jl

## Contributing

Contributions are welcome! Please feel free to:
1. Fork the repository
2. Create a feature branch
3. Submit a Pull Request

## Papers and References

Available in `papers/`:
1. **Memory Evolutive Systems: Hierarchy, Emergence, Cognition** (2007)  
   *Ehresmann, A. C., & Vanbremeersch, J. P.*  
   Elsevier Science, Volume 4  
   *The foundational book introducing Memory Evolutive Systems theory*

2. **Memory Evolutive Systems: A Categorical Framework for Complex Systems** (2023)  
   *Ehresmann, A.C., Béjean, M., & Vanbremeersch, J.-P.*  
   *A modern extension of MES theory for complex systems*

3. **Monetary Macro Accounting Theory (MoMaT)** (2025)  
   *Menéndez, R., & Winschel, V.*  
   *Application of MES to monetary and economic systems*

## License

MIT License 
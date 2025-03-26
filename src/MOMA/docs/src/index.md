# MOMA.jl Documentation

MOMA (Monetary System Analysis) is a Julia package that implements a categorical framework for analyzing financial events and monetary systems.

## Features

- **Category Theory Framework**: Models financial events using category theory concepts
- **Financial Event Analysis**: Supports various types of financial events (money creation, loans, purchases)
- **Multi-level Analysis**: Maps between micro and macro levels of the economy
- **Mathematical Rigor**: Ensures consistency through categorical properties

## Quick Start

```julia
using MOMA
using Dates

# Create a money creation event
date = Date("2025-01-15")
diagram = create_money_creation_diagram(1000.0, date)

# Verify categorical properties
@assert is_commutative(diagram)
@assert verify_universal_property(create_colimit(diagram))

# Create functor to macro level
F = create_micro_macro_functor(diagram)
```

## Installation

To install MOMA.jl, use Julia's package manager:

```julia
using Pkg
Pkg.add("MOMA")
```

## Contents

```@contents
Pages = [
    "theory/category.md",
    "theory/events.md",
    "theory/functors.md",
    "api/types.md",
    "api/events.md",
    "api/category.md",
    "api/functors.md",
    "examples.md"
]
Depth = 2
``` 
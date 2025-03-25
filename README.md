# MES

A Julia package for simulating Memory Evolutive Systems (MES) using category theory.

## Overview

MES provides tools for:
- Creating and manipulating categories
- Working with patterns and colimits
- Simulating memory evolutive systems

## Installation

```julia
using Pkg
Pkg.add("MES")
```

## Quick Start

```julia
using MES

# Create a simple category
objects = ["A", "B", "C"]
morphisms = Dict(
    ("A", "B") => ["f"],
    ("B", "C") => ["g"]
)
category = create_category(objects, morphisms)

# Create a pattern
pattern = create_pattern(category, ["A", "B"], [("A", "B")])

# Calculate colimit
colimit = calculate_colimit(pattern)
```

## Documentation

For detailed documentation, visit [https://viktorwinschel.github.io/MES.jl](https://viktorwinschel.github.io/MES.jl).

## Development

To set up the development environment:

```julia
using Pkg
Pkg.develop(path=".")
Pkg.instantiate()
```

## Testing

Run the test suite:

```julia
using Pkg
Pkg.test("MES")
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. 
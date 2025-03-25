# MES (Monetary Economic System)

A Julia package for modeling monetary and economic systems using category theory.

## Overview

MES provides tools for:
- Creating and manipulating categories
- Working with patterns and colimits
- Simulating memory evolutive systems

## Installation

To install MES, use Julia's package manager:

```julia
using Pkg
Pkg.add("MES")
```

For development:

```julia
using Pkg
Pkg.develop(path=".")
```

## Quick Start

```julia
using MES

# Create a simple category
objects = ["Bank", "Customer", "Account"]
morphisms = ["deposit", "withdraw"]
cat = create_category(objects, morphisms)

# Create a pattern
pattern = create_pattern(cat, cat, cat, [("deposit", "withdraw", "balance")])

# Calculate colimit
result = calculate_colimit(pattern)
```

## Documentation

For detailed documentation, visit [https://viktorwinschel.github.io/mes](https://viktorwinschel.github.io/mes)

## Examples

See the `examples/` directory for detailed examples including:
- Bill of Exchange modeling
- Double-entry accounting systems
- Banking system patterns

## Development

To contribute to MES:

1. Fork the repository
2. Create a new branch for your feature
3. Make your changes
4. Run the tests: `julia --project=. test/test.jl`
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Citation

If you use MES in your research, please cite:

```bibtex
@software{mes2024,
  author = {Winschel, Viktor},
  title = {MES: Monetary Economic System},
  year = {2024},
  url = {https://github.com/viktorwinschel/mes}
}
``` 
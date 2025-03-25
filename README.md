# MES (Monetary Economic System)

[![Documentation](https://github.com/viktorwinschel/mes/actions/workflows/documentation.yml/badge.svg)](https://github.com/viktorwinschel/mes/actions/workflows/documentation.yml)
[![Stable Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://viktorwinschel.github.io/mes/stable)
[![Dev Documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://viktorwinschel.github.io/mes/dev)

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

The documentation is available in multiple versions:

- [Stable Documentation](https://viktorwinschel.github.io/mes/stable) - Documentation for the latest released version
- [Development Documentation](https://viktorwinschel.github.io/mes/dev) - Documentation for the development version

The documentation includes:
- Getting Started Guide
- Theory and Concepts
- API Reference
- Examples and Tutorials
- MOMAT Integration Guide

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

## Development Workflow

### Local Development

1. Make code changes in your project
2. Run tests:
   ```julia
   julia --project=. test/test.jl
   ```
3. Build and preview documentation locally:
   ```julia
   cd docs
   julia --project=. make.jl
   ```
   View at `file:///path/to/mes/docs/build/index.html`

### Documentation

- Edit markdown files in `docs/src/`
- Update docstrings in Julia code
- Documentation automatically rebuilds on push to GitHub

### Git Workflow

```bash
# Stage your changes
git add .

# Commit with a descriptive message
git commit -m "Description of changes"

# Push to GitHub
git push origin main
```

After pushing:
- GitHub Actions automatically runs tests and builds documentation
- Monitor progress in the "Actions" tab on GitHub
- Documentation updates at:
  - Development (latest): https://viktorwinschel.github.io/mes/dev
  - Stable (released): https://viktorwinschel.github.io/mes/stable

### Releases

```bash
# Tag a new version
git tag v1.0.0
git push --tags
```

```bibtex
@software{mes2024,
  author = {Winschel, Viktor},
  title = {MES: Monetary Economic System},
  year = {2024},
  url = {https://github.com/viktorwinschel/mes}
}
``` 
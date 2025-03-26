# Getting Started

Welcome to the Memory Evolutive Systems (MES) documentation! This guide will help you get started with using MES for your projects.

## Installation

To install MES, use Julia's package manager:

```julia
using Pkg
Pkg.add(url="https://github.com/yourusername/mes.jl")
```

## Basic Usage

Here's a simple example to get you started:

```julia
using MES

# Create a simple category
C = Category("ExampleCategory")
add_object!(C, "A")
add_object!(C, "B")
add_morphism!(C, "f", "A", "B")

# Create a memory system
M = MemorySystem(C)
```

## Next Steps

After getting familiar with the basics, you can:

1. Explore the [Theory](../theory/index.md) section to understand the mathematical foundations
2. Check out the [Examples](../examples/index.md) to see practical applications
3. Reference the [API Documentation](../api.md) for detailed function descriptions

## Project Structure

The project is organized as follows:

```
mes/
├── src/           # Source code
├── docs/          # Documentation
├── test/          # Test suite
└── examples/      # Example implementations
```

## Contributing

We welcome contributions! Here's how you can help:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Getting Help

If you need assistance:

1. Check the [Theory](../theory/index.md) section for conceptual understanding
2. Look through the [Examples](../examples/index.md) for practical guidance
3. Review the [API Documentation](../api.md) for function details
4. Open an issue on GitHub for specific problems

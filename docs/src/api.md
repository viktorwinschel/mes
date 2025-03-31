# API Reference

This page documents the public API of the Memory Evolutive Systems (MES) package.

## Core Types

```@docs
SimpleObject
SimpleMorphism
Functor
NaturalTransformation
```

## Category Operations

```@docs
get_source
get_target
get_identity
compose
verify_identity_laws
verify_associativity
```

## Functor Operations

```@docs
create_functor
apply_functor
create_natural_transformation
apply_natural_transformation
```

## Pattern Operations

```@docs
verify_pattern
verify_colimit
```

## Categories

```@docs
Category
ConcreteCategory
create_category
verify_category
verify_composition_closure
verify_identity_existence
```

## Financial Categories

```@docs
FinancialCategory
create_financial_category
create_time_series_functor
create_price_natural_transformation
verify_conservation_laws
```

## Patterns

```@docs
Pattern
create_pattern
calculate_colimit
```

## Memory Systems

```@docs
MemorySystem
store!
retrieve
verify_memory_system
```

## Synchronization

```@docs
Synchronization
verify_synchronization
```

## Category Operations

The following functions provide core operations for manipulating categories:

```@docs
add_morphism!
compose_morphisms!
```

## Memory Components

The following functions create and manage memory components in the system:

```@docs
create_memory_component
create_hierarchical_category
create_co_regulator
```

## Binding Operations

The following functions manage bindings between different levels of the hierarchy:

```@docs
add_binding!
update_landscape!
```

## Implementation Details

### Category Operations

The category operations form the foundation of our system:

```julia
# Add a new morphism
add_morphism!(category::Category{T}, source::T, target::T, morphism::T) where T

# Compose two morphisms
compose_morphisms!(category::Category{T}, f::T, g::T, result::T) where T
```

### Memory Components

Memory components are the building blocks of the MES:

```julia
# Create a memory component
create_memory_component(capacity::Int, decay_rate::Float64)

# Build a hierarchical category
create_hierarchical_category(levels::Dict{Int, Vector{T}}) where T

# Create a coregulator
create_co_regulator(threshold::Float64, decay_rate::Float64)
```

### Binding Operations

Binding operations connect different levels of the hierarchy:

```julia
# Create a binding between levels
add_binding!(category::HierarchicalCategory{T}, lower::T, higher::T) where T

# Update the system landscape
update_landscape!(regulator::CoRegulator{T}, activations::Dict{T, Float64}) where T
```

## Examples

### Creating and Composing Morphisms

```julia
# Create a category
category = create_category(["A", "B", "C"], Dict())

# Add morphisms
add_morphism!(category, "A", "B", "f")
add_morphism!(category, "B", "C", "g")

# Compose morphisms
compose_morphisms!(category, "f", "g", "h")
```

### Building Memory Systems

```julia
# Create memory components
stm = create_memory_component(5, 0.3)  # Short-term memory
ltm = create_memory_component(20, 0.05) # Long-term memory

# Create hierarchical structure
levels = Dict(
    1 => ["n1", "n2", "n3"],
    2 => ["P1", "P2"],
    3 => ["C1"]
)
hierarchy = create_hierarchical_category(levels)

# Add bindings
add_binding!(hierarchy, "n1", "P1")
add_binding!(hierarchy, "n2", "P1")
add_binding!(hierarchy, "P1", "C1")

# Create and update coregulator
regulator = create_co_regulator(0.6, 0.1)
activations = Dict("n1" => 0.8, "n2" => 0.6)
update_landscape!(regulator, activations)
```

## Mathematical Background

### Category Theory

The category operations satisfy the standard categorical laws:

$$
\begin{array}{l}
g \circ (f \circ h) = (g \circ f) \circ h \quad \text{(associativity)} \\
f \circ \text{id}_A = f = \text{id}_B \circ f \quad \text{(identity)}
\end{array}
$$

### Memory Evolution

Memory components evolve according to:

$$
\begin{array}{l}
\text{Activation}(t+1) = \text{Activation}(t) \cdot (1 - \text{decay\_rate}) + \text{input}(t) \\
\text{Threshold}(t) = \text{base\_threshold} \cdot (1 + \text{activation\_rate} \cdot \text{Activation}(t))
\end{array}
$$
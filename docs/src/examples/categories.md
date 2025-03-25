# Category Examples

This chapter provides practical examples of using categories in Memory Evolutive Systems.

## Basic Category Creation

Let's start with creating a simple category:

```julia
using MES

# Create a graph with neurons and connections
graph = create_graph([
    "Neuron1", "Neuron2", "Assembly"
], [
    ("Neuron1", "Neuron2", "synapse"),
    ("Neuron2", "Assembly", "activation")
])

# Convert to category
cat = create_category(graph)

# Add composition
add_composition!(cat, "synapse", "activation", "process")

# Verify category structure
is_valid = verify_category(cat)
```

## Biological System Example

Modeling a cell and its components:

```julia
# Create a configuration category for a cell
cell = configuration_category([
    "Nucleus", "Mitochondria", "CellMembrane"
], [
    ("Nucleus", "Mitochondria", "energy_transfer"),
    ("Mitochondria", "CellMembrane", "transport")
])

# Model cell division
daughter_cell = configuration_category([
    "DaughterNucleus", "DaughterMitochondria", "DaughterMembrane"
], [
    ("DaughterNucleus", "DaughterMitochondria", "energy_transfer"),
    ("DaughterMitochondria", "DaughterMembrane", "transport")
])

# Create a functor representing division
division = functor(cell, daughter_cell, Dict(
    "Nucleus" => "DaughterNucleus",
    "Mitochondria" => "DaughterMitochondria",
    "CellMembrane" => "DaughterMembrane"
))
```

## Neural Network Example

Modeling a simple neural network:

```julia
# Create a labeled category for the network
network = labeled_category([
    "Input", "Hidden", "Output"
], [
    ("Input", "Hidden", "weight1"),
    ("Hidden", "Output", "weight2")
], ["weight1", "weight2"])

# Add learning rules as compositions
add_composition!(network, "weight1", "weight2", "forward_prop")
add_composition!(network, "weight2", "weight1", "back_prop")
```

## Social Network Example

Modeling social relationships:

```julia
# Create a category with generators
social = category_generators([
    "Person", "Group", "Organization"
], [
    ("Person", "Group", "member"),
    ("Group", "Organization", "affiliate")
])

# Add social interaction rules
add_composition!(social, "member", "affiliate", "participate")
```

## Further Reading

For more information about categories in MES, refer to:
- [Category Theory](../theory/categories.md)
- [Patterns](../theory/patterns.md)
- [Memory Systems](../theory/memory_systems.md) 
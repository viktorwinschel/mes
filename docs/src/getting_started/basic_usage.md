# Basic Usage

This guide will walk you through the basic usage of MoMaT_Sim.

## Creating a Category

```julia
using MoMaT_Sim

# Create a simple category with two objects and a morphism
objects = ["A", "B"]
morphisms = Dict(("A", "B") => ["f"])
category = create_category(objects, morphisms)
```

## Working with Patterns

```julia
# Create a pattern from the category
pattern_objects = ["A", "B"]
pattern_links = [("A", "B")]
pattern = create_pattern(category, pattern_objects, pattern_links)

# Calculate colimit
colimit = calculate_colimit(pattern)
```

## Next Steps

For more detailed examples, check out the examples in the [Basic Categories](../examples/basic_categories.md) section. 
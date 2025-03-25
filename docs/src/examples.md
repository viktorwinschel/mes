# Examples

This section provides practical examples of using the Memory Evolutive Systems package.

## Basic Category Creation

```julia
using MoMaT_Sim

# Create a simple category with three objects and two morphisms
objects = ["A", "B", "C"]
morphisms = Dict(
    ("A", "B") => ["f"],
    ("B", "C") => ["g"]
)
category = create_category(objects, morphisms)
```

## Working with Patterns

```julia
# Create a pattern in the category
pattern_objects = ["A", "B"]
pattern_links = [("A", "B")]
pattern = create_pattern(category, pattern_objects, pattern_links)

# Calculate the colimit
colimit_result = calculate_colimit(pattern)
```

## Hierarchical Categories

```julia
# Create a hierarchical category with two levels
levels = Dict(
    1 => ["A", "B"],
    2 => ["C"]
)
links = Dict(
    ("A", "C") => ["f"],
    ("B", "C") => ["g"]
)
hierarchical_cat = create_hierarchical_category(levels, links)
```

## Memory Systems

```julia
# Create a memory system with procedures
procedures = Dict(
    "update" => x -> x + 1,
    "store" => x -> Dict("value" => x)
)
memory_system = create_memory_system(category, procedures)

# Update memory with new input
new_input = Dict("value" => 42)
updated_memory = update_memory(memory_system, new_input)
```

## Complexification Process

```julia
# Create patterns for complexification
patterns = [
    create_pattern(category, ["A", "B"], [("A", "B")]),
    create_pattern(category, ["B", "C"], [("B", "C")])
]

# Perform complexification
complexified_category = complexify(category, patterns)
``` 
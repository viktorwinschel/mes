# Basic Categories

This section provides practical examples of working with categories in MES.

## Example Usage

```julia
using MES
```

## Creating a Simple Category

```julia
# Define objects and morphisms
objects = ["A", "B", "C"]
morphisms = Dict(
    "f" => ("A", "B"),
    "g" => ("B", "C")
)

# Create the category
category = create_category(objects, morphisms)
```

## Working with Patterns

```julia
# Create a pattern from the category
pattern_objects = ["A", "B"]
pattern_links = [("A", "B")]
pattern = create_pattern(category, pattern_objects, pattern_links)

# Calculate the colimit
colimit = calculate_colimit(pattern)
```

## Next Steps

Check out the [Bill of Exchange](bill_of_exchange.md) example for a more complex application. 
"""
    Pattern

A type representing a pattern in a category.

# Fields
- `category::Category`: The category containing the pattern
- `objects::Vector{String}`: The objects in the pattern
- `morphisms::Vector{Tuple{String,String,String}}`: The morphisms between objects in the pattern (source, target, name)
"""
struct Pattern
    category::Category
    objects::Vector{String}
    morphisms::Vector{Tuple{String,String,String}}
end

"""
    create_pattern(category::Category, objects::Vector{String}, morphisms::Vector{Tuple{String,String,String}})

Create a pattern in a category.

# Arguments
- `category::Category`: The category containing the pattern
- `objects::Vector{String}`: The objects in the pattern
- `morphisms::Vector{Tuple{String,String,String}}`: The morphisms between objects (source, target, name)

# Returns
A `Pattern` struct representing the pattern.

# Examples
```julia
category = create_category(["A", "B", "C"], Dict{String,Tuple{String,String}}())
pattern = create_pattern(category, ["A", "B"], [("A", "B", "f")])
```
"""
function create_pattern(category::Category, objects::Vector{String}, morphisms::Vector{Tuple{String,String,String}})
    # Verify that all objects exist in the category
    for obj in objects
        if !any(o -> o isa SimpleObject && o.name == obj, category.objects)
            throw(ArgumentError("Object $obj not found in category"))
        end
    end

    # Verify that all morphisms are valid
    for (src, tgt, name) in morphisms
        if !(src in objects && tgt in objects)
            throw(ArgumentError("Morphism $name has invalid source or target"))
        end
    end

    Pattern(category, objects, morphisms)
end

"""
    verify_pattern(pattern::Pattern)

Verify that a pattern is valid in its category.

# Returns
`true` if the pattern is valid, `false` otherwise.
"""
function verify_pattern(pattern::Pattern)
    # Check that all objects exist in category
    for obj in pattern.objects
        if !any(o -> o isa SimpleObject && o.name == obj, pattern.category.objects)
            return false
        end
    end

    # Check that all morphisms are valid
    for (src, tgt, name) in pattern.morphisms
        if !(src in pattern.objects && tgt in pattern.objects)
            return false
        end
    end

    true
end

"""
    calculate_colimit(pattern::Pattern)

Calculate the colimit of a pattern in a category.

# Arguments
- `pattern::Pattern`: The pattern to calculate the colimit for

# Returns
A tuple (colimit_obj, colimit_morphisms) where:
- colimit_obj: The name of the colimit object
- colimit_morphisms: Vector of (source, target, name) tuples for morphisms to colimit

# Examples
```julia
category = create_category(["A", "B", "C"], Dict{String,Tuple{String,String}}())
pattern = create_pattern(category, ["A", "B"], [("A", "B", "f")])
colimit_obj, colimit_morphisms = calculate_colimit(pattern)
```
"""
function calculate_colimit(pattern::Pattern)
    # Create a unique name for the colimit object
    colimit_obj = "colim_" * join(pattern.objects, "_")

    # Create morphisms from each pattern object to the colimit
    colimit_morphisms = [
        (obj, colimit_obj, "to_colimit_$obj")
        for obj in pattern.objects
    ]

    # Return the colimit object and morphisms
    return (colimit_obj, colimit_morphisms)
end

"""
    verify_colimit(pattern::Pattern, colimit_obj::String, colimit_morphisms::Vector{Tuple{String,String,String}})

Verify that a colimit satisfies the universal property.

# Returns
`true` if the colimit satisfies the universal property, `false` otherwise.
"""
function verify_colimit(pattern::Pattern, colimit_obj::String, colimit_morphisms::Vector{Tuple{String,String,String}})
    # Check that each object has a morphism to the colimit
    for obj in pattern.objects
        if !any(m -> m[1] == obj && m[2] == colimit_obj, colimit_morphisms)
            return false
        end
    end

    # Check that the diagram commutes
    for (src, tgt, _) in pattern.morphisms
        src_to_colimit = findfirst(m -> m[1] == src && m[2] == colimit_obj, colimit_morphisms)
        tgt_to_colimit = findfirst(m -> m[1] == tgt && m[2] == colimit_obj, colimit_morphisms)

        if src_to_colimit === nothing || tgt_to_colimit === nothing
            return false
        end
    end

    true
end
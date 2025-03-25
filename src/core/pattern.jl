"""
    Pattern

A type representing a pattern in a category.

# Fields
- `category::Category`: The category containing the pattern
- `objects::Vector{String}`: The objects in the pattern
- `links::Vector{Tuple{String,String}}`: The morphisms between objects in the pattern
"""
struct Pattern
    category::Category
    objects::Vector{String}
    links::Vector{Tuple{String,String}}
end

"""
    create_pattern(category::Category, objects::Vector{String}, links::Vector{Tuple{String,String}})

Create a pattern in a category.

# Arguments
- `category::Category`: The category containing the pattern
- `objects::Vector{String}`: The objects in the pattern
- `links::Vector{Tuple{String,String}}`: The morphisms between objects in the pattern

# Returns
A `Pattern` struct representing the pattern.

# Examples
```julia
category = create_category(["A", "B", "C"], Dict())
pattern = create_pattern(category, ["A", "B"], [("A", "B")])
```
"""
function create_pattern(category::Category, objects::Vector{String}, links::Vector{Tuple{String,String}})
    return Pattern(category, objects, links)
end

"""
    calculate_colimit(pattern::Pattern)

Calculate the colimit of a pattern in a category.

# Arguments
- `pattern::Pattern`: The pattern to calculate the colimit for

# Returns
A dictionary containing the colimit object and the morphisms from the pattern objects to the colimit.

# Examples
```julia
category = create_category(["A", "B", "C"], Dict())
pattern = create_pattern(category, ["A", "B"], [("A", "B")])
colimit = calculate_colimit(pattern)
```
"""
function calculate_colimit(pattern::Pattern)
    colimit_object = "Colimit_$(join(pattern.objects, "_"))"

    morphisms = Dict{String,String}()
    for obj in pattern.objects
        morphisms[obj] = "morphism_to_colimit_$obj"
    end

    return Dict(
        "object" => colimit_object,
        "morphisms" => morphisms
    )
end
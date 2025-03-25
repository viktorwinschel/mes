"""
    Category{T}

A type representing a category in category theory.

# Fields
- `objects::Vector{T}`: The objects in the category
- `morphisms::Dict{Tuple{T,T},Vector{T}}`: Maps pairs of objects to their morphisms
- `composition::Dict{Tuple{T,T,T},Bool}`: Maps triples of objects to composed morphisms
"""
struct Category{T}
    objects::Vector{T}
    morphisms::Dict{Tuple{T,T},Vector{T}}
    composition::Dict{Tuple{T,T,T},Bool}
end

"""
    create_category(objects::Vector{T}, morphisms::Dict{Tuple{T,T},Vector{T}}) where T

Create a category with the given objects and morphisms.

# Arguments
- `objects::Vector{T}`: A vector of objects in the category
- `morphisms::Dict{Tuple{T,T},Vector{T}}`: A dictionary mapping pairs of objects to their morphisms

# Returns
A `Category` struct representing the category.

# Examples
```julia
objects = ["A", "B", "C"]
morphisms = Dict(
    ("A", "B") => ["f"],
    ("B", "C") => ["g"]
)
category = create_category(objects, morphisms)
```
"""
function create_category(objects::Vector{T}, morphisms::Dict{Tuple{T,T},Vector{T}}) where {T}
    return Category{T}(
        objects,
        morphisms,
        Dict{Tuple{T,T,T},Bool}()
    )
end

"""
    add_morphism!(category::Category{T}, source::T, target::T, morphism::T) where T

Add a morphism to a category.

# Arguments
- `category::Category{T}`: The category to modify
- `source::T`: The source object
- `target::T`: The target object
- `morphism::T`: The morphism to add

# Examples
```julia
category = create_category(["A", "B"], Dict())
add_morphism!(category, "A", "B", "f")
```
"""
function add_morphism!(category::Category{T}, source::T, target::T, morphism::T) where {T}
    if !(source in category.objects)
        push!(category.objects, source)
    end
    if !(target in category.objects)
        push!(category.objects, target)
    end

    key = (source, target)
    if !haskey(category.morphisms, key)
        category.morphisms[key] = T[]
    end
    push!(category.morphisms[key], morphism)
end

"""
    compose_morphisms!(category::Category{T}, f::T, g::T, result::T) where T

Add a composition rule to the category.

# Arguments
- `category::Category{T}`: The category to modify
- `f::T`: The first morphism
- `g::T`: The second morphism
- `result::T`: The composed morphism

# Examples
```julia
category = create_category(["A", "B", "C"], Dict())
add_morphism!(category, "A", "B", "f")
add_morphism!(category, "B", "C", "g")
compose_morphisms!(category, "f", "g", "h")
```
"""
function compose_morphisms!(category::Category{T}, f::T, g::T, result::T) where {T}
    category.composition[(f, g, result)] = true
end
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
    verify_category(category::Category{T}) where T

Verify that a category satisfies the basic axioms.

# Arguments
- `category::Category{T}`: The category to verify

# Returns
A boolean indicating whether the category is valid.
"""
function verify_category(category::Category{T}) where {T}
    # Check that all objects in morphisms exist
    for ((src, tgt), _) in category.morphisms
        if !(src in category.objects && tgt in category.objects)
            return false
        end
    end
    return true
end

"""
    verify_composition_closure(category::Category{T}) where T

Verify that the category is closed under composition.

# Arguments
- `category::Category{T}`: The category to verify

# Returns
A boolean indicating whether the category is closed under composition.
"""
function verify_composition_closure(category::Category{T}) where {T}
    for ((src, mid), morphs1) in category.morphisms
        for ((mid2, tgt), morphs2) in category.morphisms
            if mid == mid2
                # Check if composition exists
                if !haskey(category.morphisms, (src, tgt))
                    return false
                end
            end
        end
    end
    return true
end

"""
    verify_identity_existence(category::Category{T}) where T

Verify that each object has an identity morphism.

# Arguments
- `category::Category{T}`: The category to verify

# Returns
A boolean indicating whether each object has an identity morphism.
"""
function verify_identity_existence(category::Category{T}) where {T}
    for obj in category.objects
        if !haskey(category.morphisms, (obj, obj))
            return false
        end
    end
    return true
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
    if !(source in category.objects && target in category.objects)
        error("Source and target objects must exist in the category")
    end

    if !haskey(category.morphisms, (source, target))
        category.morphisms[(source, target)] = T[]
    end

    if !(morphism in category.morphisms[(source, target)])
        push!(category.morphisms[(source, target)], morphism)
    end
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
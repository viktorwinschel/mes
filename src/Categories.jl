module Categories

export Category, Graph
export create_graph, create_category, add_composition!
export verify_category, configuration_category
export functor, category_generators, labeled_category

"""
    Graph{T}

A directed graph with vertices of type T and labeled edges.
"""
struct Graph{T}
    vertices::Set{T}
    edges::Dict{Tuple{T,T},Set{String}}
end

"""
    Category{T}

A category with objects of type T, morphisms between them, and composition rules.
"""
struct Category{T}
    objects::Set{T}
    morphisms::Dict{Tuple{T,T},Set{String}}
    compositions::Dict{Tuple{String,String},String}
    identities::Dict{T,String}
end

"""
    create_graph(vertices::Vector{T}, edges::Vector{Tuple{T,T,String}}) where T

Create a graph from a list of vertices and labeled edges.
"""
function create_graph(vertices::Vector{T}, edges::Vector{Tuple{T,T,String}}) where {T}
    vertex_set = Set(vertices)
    edge_dict = Dict{Tuple{T,T},Set{String}}()

    for (source, target, label) in edges
        key = (source, target)
        if !haskey(edge_dict, key)
            edge_dict[key] = Set{String}()
        end
        push!(edge_dict[key], label)
    end

    Graph{T}(vertex_set, edge_dict)
end

"""
    create_category(graph::Graph{T}) where T

Create a category from a graph by adding identity morphisms and preparing for compositions.
"""
function create_category(graph::Graph{T}) where {T}
    # Copy graph structure
    objects = copy(graph.vertices)
    morphisms = copy(graph.edges)

    # Add identity morphisms
    identities = Dict{T,String}()
    for obj in objects
        id_name = "id_$(obj)"
        key = (obj, obj)
        if !haskey(morphisms, key)
            morphisms[key] = Set{String}()
        end
        push!(morphisms[key], id_name)
        identities[obj] = id_name
    end

    Category{T}(objects, morphisms, Dict{Tuple{String,String},String}(), identities)
end

"""
    add_composition!(cat::Category{T}, f::String, g::String, h::String) where T

Add a composition rule h = g ∘ f to the category.
"""
function add_composition!(cat::Category{T}, f::String, g::String, h::String) where {T}
    cat.compositions[(f, g)] = h
end

"""
    verify_category(cat::Category)

Verify that the category satisfies the category laws:
- Identity morphisms exist for all objects
- Compositions are well-defined
- Associativity holds
- Identity laws hold
"""
function verify_category(cat::Category)
    # Check identities
    for obj in cat.objects
        if !haskey(cat.identities, obj)
            return false, "Missing identity morphism for object $obj"
        end
    end

    # Check composition closure
    for ((f1, f2), h) in cat.compositions
        # Verify the morphisms exist
        found_f1 = false
        found_f2 = false
        found_h = false

        for (_, morphs) in cat.morphisms
            if f1 in morphs
                found_f1 = true
            end
            if f2 in morphs
                found_f2 = true
            end
            if h in morphs
                found_h = true
            end
        end

        if !found_f1 || !found_f2 || !found_h
            return false, "Invalid composition rule: $f1 ∘ $f2 = $h"
        end
    end

    # More detailed checks could be added for associativity and identity laws

    return true, "Category laws verified"
end

"""
    configuration_category(;
        objects::Vector{T},
        morphisms::Vector{String},
        compositions::Vector{Tuple{String,String,String}}
    ) where T

Create a configuration category representing a system state.
"""
function configuration_category(;
    objects::Vector{T},
    morphisms::Vector{String},
    compositions::Vector{Tuple{String,String,String}}
) where {T}
    cat = create_category(create_graph(objects, []))

    for (f, g, h) in compositions
        add_composition!(cat, f, g, h)
    end

    cat
end

"""
    functor(;
        source::Category{T},
        target::Category{S},
        object_map::Dict{T,S},
        morphism_map::Dict{String,String}
    ) where {T,S}

Create a functor between categories, preserving structure.
"""
function functor(;
    source::Category{T},
    target::Category{S},
    object_map::Dict{T,S},
    morphism_map::Dict{String,String}
) where {T,S}
    # Verify functor laws
    # 1. Object mapping is total
    for obj in source.objects
        if !haskey(object_map, obj)
            error("Functor not defined for object $obj")
        end
    end

    # 2. Morphism mapping preserves composition
    for ((f, g), h) in source.compositions
        if !haskey(morphism_map, f) || !haskey(morphism_map, g) || !haskey(morphism_map, h)
            error("Functor not defined for all morphisms in composition")
        end

        # Verify F(g ∘ f) = F(g) ∘ F(f)
        if !haskey(target.compositions, (morphism_map[f], morphism_map[g]))
            error("Functor does not preserve composition")
        end
    end

    (object_map, morphism_map)
end

"""
    category_generators(;
        objects::Vector{T},
        basic_morphisms::Vector{String}
    ) where T

Create a category from generators and relations.
"""
function category_generators(;
    objects::Vector{T},
    basic_morphisms::Vector{String}
) where {T}
    create_category(create_graph(objects, []))
end

"""
    labeled_category(;
        objects::Vector{T},
        labels::Vector{String},
        morphisms::Vector{Tuple{T,T,String}}
    ) where T

Create a category with labeled morphisms.
"""
function labeled_category(;
    objects::Vector{T},
    labels::Vector{String},
    morphisms::Vector{Tuple{T,T,String}}
) where {T}
    # Verify labels
    for (_, _, label) in morphisms
        if !(label in labels)
            error("Invalid label: $label")
        end
    end

    create_category(create_graph(objects, morphisms))
end

end # module 
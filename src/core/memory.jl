"""
    Memory Evolutive Systems (MES) Core Implementation

This module implements the core concepts of Memory Evolutive Systems:
- Multiple Resolution: Objects at different complexity levels
- Dynamic Structure: Evolution over time
- Memory with Variable Multiplicity: Recording and using past experiences
"""

using Dates

# Memory component with variable multiplicity
struct MemoryComponent{T}
    records::Vector{T}
    timestamps::Vector{DateTime}
    multiplicity::Int
    decay_rate::Float64
end

# Hierarchical category with complexity levels
struct HierarchicalCategory{T}
    levels::Dict{Int,Vector{T}}
    bindings::Dict{T,Vector{T}}  # Links between levels
    complexity::Dict{T,Int}      # Complexity measure for objects
end

# Co-regulator for system adaptation
struct CoRegulator{T}
    landscape::Dict{T,Float64}   # Current activation landscape
    threshold::Float64            # Activation threshold
    decay_rate::Float64          # Decay rate for landscape
end

"""
    create_memory_component(capacity::Int, decay_rate::Float64)

Create a new memory component with given capacity and decay rate.
"""
function create_memory_component(capacity::Int, decay_rate::Float64)
    return MemoryComponent(
        Vector(),
        Vector{DateTime}(),
        capacity,
        decay_rate
    )
end

"""
    create_hierarchical_category(levels::Dict{Int, Vector{T}}) where T

Create a hierarchical category with specified levels.
"""
function create_hierarchical_category(levels::Dict{Int,Vector{T}}) where {T}
    return HierarchicalCategory{T}(
        levels,
        Dict{T,Vector{T}}(),
        Dict{T,Int}()
    )
end

"""
    create_co_regulator(threshold::Float64, decay_rate::Float64)

Create a co-regulator with specified threshold and decay rate.
"""
function create_co_regulator(threshold::Float64, decay_rate::Float64)
    return CoRegulator(
        Dict(),
        threshold,
        decay_rate
    )
end

"""
    add_binding!(category::HierarchicalCategory{T}, lower::T, higher::T) where T

Add a binding between objects at different levels.
"""
function add_binding!(category::HierarchicalCategory{T}, lower::T, higher::T) where {T}
    if !haskey(category.bindings, higher)
        category.bindings[higher] = T[]
    end
    push!(category.bindings[higher], lower)
end

"""
    update_landscape!(regulator::CoRegulator{T}, activations::Dict{T, Float64}) where T

Update the activation landscape of a co-regulator.
"""
function update_landscape!(regulator::CoRegulator{T}, activations::Dict{T,Float64}) where {T}
    # Apply decay to existing landscape
    for (key, value) in regulator.landscape
        regulator.landscape[key] = value * (1.0 - regulator.decay_rate)
    end

    # Add new activations
    for (key, value) in activations
        regulator.landscape[key] = get(regulator.landscape, key, 0.0) + value
    end
end
module MES

# Core types and functionality
include("core/category.jl")  # Define Category first
include("core/types.jl")     # Then include types that depend on Category
include("core/pattern.jl")
include("core/memory.jl")
include("core/synchronization.jl")

# Export all types and functions
export Category, Functor, NaturalTransformation,
    create_category, add_morphism!, verify_category, verify_composition_closure, verify_identity_existence,
    Pattern, create_pattern, calculate_colimit,
    MemorySystem, store!, retrieve, verify_memory_system,
    Synchronization, verify_synchronization,
    compose_morphisms!, create_memory_component, create_hierarchical_category, create_co_regulator,
    add_binding!, update_landscape!

end # module 
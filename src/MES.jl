module MES

# Core exports
include("core/exports.jl")

# Core types and functionality
include("core/category.jl")  # Define Category first
include("core/types.jl")     # Then include types that depend on Category
include("core/pattern.jl")   # Pattern functionality
include("core/memory.jl")    # Memory system
include("core/synchronization.jl") # Synchronization

# Additional exports from other modules
export Functor, NaturalTransformation,
    TimePoint, FunctorH, PartialCategory, BehaviorStream,
    SimulationLogger, MESState, bind, return_value, evaluate

export Pattern, create_pattern, calculate_colimit

export MemorySystem, store!, retrieve, verify_memory_system

export Synchronization, verify_synchronization,
    create_memory_component, create_hierarchical_category, create_co_regulator,
    add_binding!, update_landscape!

end # module 
module Core

using Parameters
using DataFrames

# Include all core functionality in proper order
include("types.jl")           # Basic types first
include("category.jl")        # Category definitions
include("pattern.jl")         # Pattern functionality
include("memory.jl")          # Memory system
include("synchronization.jl")  # Synchronization

# Export category types
export Category, ConcreteCategory, CategoryObject, CategoryMorphism
export SimpleObject, SimpleMorphism
export Functor, NaturalTransformation

# Export financial types
export Agent, Account, Flow, Transaction, StateTransition, FinancialCategory

# Export core category functions
export create_category, add_morphism!, compose_morphisms!, compose
export get_source, get_target, get_identity

# Export functor and natural transformation functions
export create_functor, create_natural_transformation
export apply_functor, apply_natural_transformation

# Export pattern functions
export Pattern, create_pattern, verify_pattern
export calculate_colimit, verify_colimit

# Export category verification functions
export verify_category, verify_composition_closure
export verify_identity_existence, verify_associativity
export verify_identity_laws

# Export financial functions
export create_financial_category, create_time_series_functor
export create_price_natural_transformation, verify_conservation_laws

# Export memory system types and functions
export MemorySystem, store!, retrieve, verify_memory_system

# Export synchronization types and functions
export Synchronization, verify_synchronization
export create_memory_component, create_hierarchical_category
export create_co_regulator, add_binding!, update_landscape!

end # module 
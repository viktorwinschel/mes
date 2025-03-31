module MES

using Parameters
using DataFrames

# Include and use Core submodule
include("core/Core.jl")
using .Core

# Re-export everything from Core
export Category, ConcreteCategory, CategoryObject, CategoryMorphism
export SimpleObject, SimpleMorphism
export Functor, NaturalTransformation

export Agent, Account, Flow, Transaction, StateTransition, FinancialCategory

export create_category, add_morphism!, compose_morphisms!, compose
export get_source, get_target, get_identity

export create_functor, create_natural_transformation
export apply_functor, apply_natural_transformation

export Pattern, create_pattern, verify_pattern
export calculate_colimit, verify_colimit

export verify_category, verify_composition_closure
export verify_identity_existence, verify_associativity
export verify_identity_laws

export create_financial_category, create_time_series_functor
export create_price_natural_transformation, verify_conservation_laws

export MemorySystem, store!, retrieve, verify_memory_system

export Synchronization, verify_synchronization
export create_memory_component, create_hierarchical_category
export create_co_regulator, add_binding!, update_landscape!

end # module 
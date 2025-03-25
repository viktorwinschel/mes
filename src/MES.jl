module MES

include("core/category.jl")
include("core/pattern.jl")

export Category, Pattern
export create_category, create_pattern, calculate_colimit
export add_morphism!

end # module MES 
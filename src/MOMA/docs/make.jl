using Documenter
using MOMA

makedocs(
    sitename="MOMA.jl",
    format=Documenter.HTML(),
    modules=[MOMA],
    pages=[
        "Home" => "index.md",
        "Theory" => [
            "Category Theory" => "theory/category.md",
            "Financial Events" => "theory/events.md",
            "Functorial Analysis" => "theory/functors.md"
        ],
        "API Reference" => [
            "Core Types" => "api/types.md",
            "Event Functions" => "api/events.md",
            "Category Functions" => "api/category.md",
            "Functor Functions" => "api/functors.md"
        ],
        "Examples" => "examples.md"
    ]
)
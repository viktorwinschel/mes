using Documenter
using MoMaT_Sim

makedocs(
    sitename="MoMaT_Sim",
    format=Documenter.HTML(),
    modules=[MoMaT_Sim],
    remotes=nothing,  # Disable remote source links
    pages=[
        "Home" => "index.md",
        "Getting Started" => [
            "Installation" => "getting_started/installation.md",
            "Basic Usage" => "getting_started/basic_usage.md"
        ],
        "Examples" => [
            "Basic Categories" => "examples/basic_categories.md"
        ],
        "Theory" => [
            "Categories" => "theory/categories.md"
        ],
        "API Reference" => "api.md"
    ]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(;
    repo="github.com/yourusername/MoMaT_Sim.jl",
    devbranch="main",
)
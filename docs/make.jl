using Documenter

# Add the parent directory to the Julia path so we can import MES
push!(LOAD_PATH, dirname(@__DIR__))
using MES

# Set prettyurls based on environment
const is_ci = get(ENV, "CI", "false") == "true"

# Build documentation
makedocs(
    sitename="MES Documentation",
    format=Documenter.HTML(
        # Enable pretty URLs for GitHub Pages
        prettyurls=is_ci,
        # Update canonical URL to GitHub Pages
        canonical="https://viktorwinschel.github.io/mes",
        edit_link="main"
    ),
    pages=[
        "Home" => "index.md",
        "Theory" => [
            "Categories" => "theory/categories.md",
            "Patterns" => "theory/patterns.md",
            "Memory Systems" => "theory/memory_systems.md",
            "Synchronization" => "theory/synchronization.md"
        ],
        "Examples" => [
            "Categories" => "examples/categories.md"
        ],
        "Papers" => [
            "MES Summary" => "papers/mes/mes-summary.md"
        ]
    ],
    modules=[MES],
    authors="Viktor Winschel",
    repo="https://github.com/viktorwinschel/mes",
    doctest=true,
    checkdocs=:all,
    linkcheck=false
)

# Deploy documentation
deploydocs(
    repo="viktorwinschel/mes",
    devbranch="main",
    push_preview=true
)
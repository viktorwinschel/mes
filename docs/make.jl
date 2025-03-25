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
        edit_link="main",
        # Add GitHub Pages optimizations
        assets=[
            "assets/favicon.ico",
            "assets/custom.css"
        ],
        # Add navigation options
        collapselevel=2,
        sidebar_sitename=true,
        # Add search functionality
        search=true
    ),
    pages=[
        "Home" => "index.md",
        "Getting Started" => "getting_started/quickstart.md",
        "Theory" => [
            "Overview" => "theory.md",
            "Categories" => "theory/categories.md",
            "Patterns" => "theory/patterns.md"
        ],
        "Examples" => [
            "Overview" => "examples.md",
            "Categories" => "examples/categories.md"
        ],
        "API Reference" => "api.md"
    ],
    modules=[MES],
    authors="Viktor Winschel",
    repo="https://github.com/viktorwinschel/mes",
    doctest=false,
    checkdocs=:none,
    linkcheck=false
)

# Deploy documentation
deploydocs(
    repo="viktorwinschel/mes",
    devbranch="main",
    push_preview=true
)
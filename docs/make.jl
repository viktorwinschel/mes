using Documenter

# Add the parent directory to the Julia path so we can import MES
push!(LOAD_PATH, dirname(@__DIR__))
using MES

# Generate documentation keys
using DocumenterTools
DocumenterTools.genkeys()

# Build documentation
makedocs(
    sitename="MES",
    format=Documenter.HTML(
        # Enable pretty URLs for GitHub Pages
        prettyurls=get(ENV, "CI", "false") == "true",
        # Update canonical URL to GitHub Pages
        canonical="https://viktorwinschel.github.io/mes",
        assets=[
            "assets/favicon.ico",
            "assets/custom.css"
        ],
        # Navigation options
        collapselevel=1,
        sidebar_sitename=true,
        # Enable git info for GitHub
        disable_git=false,
        # Add GitHub repo link
        repolink="https://github.com/viktorwinschel/mes"
    ),
    pages=[
        "Home" => "index.md",
        "Getting Started" => [
            "Installation" => "getting_started/installation.md",
            "Basic Usage" => "getting_started/basic_usage.md"
        ],
        "Examples" => [
            "Core MES Examples" => [
                "Basic Categories" => "examples/basic_categories.md",
                "Patterns and Colimits" => "examples/patterns.md",
                "Memory Systems" => "examples/memory.md",
                "Synchronization" => "examples/synchronization.md"
            ],
            "MOMAT Examples" => [
                "Overview" => "examples/momat/index.md",
                "Basic Examples" => "examples/momat/basic.md",
                "Advanced Examples" => "examples/momat/advanced.md"
            ]
        ],
        "Theory" => [
            "Categories" => "theory/categories.md",
            "Patterns" => "theory/patterns.md",
            "Memory Systems" => "theory/memory_systems.md",
            "Synchronization" => "theory/synchronization.md"
        ],
        "Papers and References" => "papers.md",
        "API Reference" => "api.md"
    ],
    modules=[MES],
    authors="Viktor Winschel",
    # Add repo info
    repo="github.com/viktorwinschel/mes",
    doctest=true,
    checkdocs=:all,
    linkcheck=false
)

# Deploy documentation
deploydocs(
    repo="github.com/viktorwinschel/mes.git",
    devbranch="main",
    push_preview=true,  # Enable preview builds for PRs
    # Deploy built documentation from docs/build to gh-pages branch
    target="build",
    deps=nothing,
    make=nothing
)
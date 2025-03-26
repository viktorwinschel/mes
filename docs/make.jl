using Documenter
using MES

# LaTeX command definitions for category theory
const latex_preamble = """
\\newcommand{\\cat}[1]{\\mathcal{#1}}
\\newcommand{\\Set}{\\mathbf{Set}}
\\newcommand{\\Cat}{\\mathbf{Cat}}
\\newcommand{\\Ab}{\\mathbf{Ab}}
\\newcommand{\\Time}{\\mathbf{Time}}
\\newcommand{\\Ord}{\\mathbf{Ord}}
\\newcommand{\\Ctrl}{\\mathbf{Ctrl}}
\\newcommand{\\State}{\\mathbf{State}}
\\newcommand{\\cod}{\\mathrm{cod}}
\\newcommand{\\id}{\\mathrm{id}}
\\newcommand{\\colim}{\\mathrm{colim}}
"""

makedocs(
    sitename="Memory Evolutive Systems",
    format=Documenter.HTML(
        prettyurls=false,
        assets=["assets/custom.css"]
    ),
    clean=true,
    doctest=true,
    checkdocs=:all,
    modules=[MES],
    pages=[
        "Home" => "index.md",
        "Getting Started" => "getting_started/index.md",
        "Theory" => [
            "Overview" => "theory/index.md",
            "Category Theory" => "theory/categories.md",
            "Synchronization" => "theory/synchronization.md",
            "Memory Systems" => "theory/memory_systems.md"
        ],
        "Examples" => [
            "Overview" => "examples/index.md",
            "Basic Examples" => "examples.md",
            "National Accounting" => "examples/national_accounting.md",
            "Bill of Exchange" => "examples/boe_cycles.md"
        ],
        "API Reference" => "api.md",
        "Papers & References" => "papers.md"
    ]
)

# Documenter can also automatically deploy documentation to gh-pages.

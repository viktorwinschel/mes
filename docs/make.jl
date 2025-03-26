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

makedocs(;
    modules=[MES],
    authors="Viktor Winschel",
    repo="https://github.com/viktorwinschel/mes/blob/{commit}{path}#L{line}",
    sitename="Memory Evolutive Systems",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "nothing") == "true",
        canonical="https://viktorwinschel.github.io/mes/",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Getting Started" => "getting_started/index.md",
        "Theory" => [
            "Overview" => "theory.md",
            "Examples" => "examples.md"
        ],
        "Examples" => [
            "Overview" => "examples/index.md",
            "Bill of Exchange" => "examples/boe_cycles.md",
            "National Accounting" => "examples/national_accounting.md"
        ],
        "API Reference" => "api.md",
        "Papers" => "papers.md"
    ]
)

deploydocs(;
    repo="github.com/viktorwinschel/mes",
    devbranch="main",
)

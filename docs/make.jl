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
    repo="https://github.com/viktorwinschel/mes",
    sitename="MoMa in MES",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://viktorwinschel.github.io/mes/",
        edit_link="main",
        repolink="https://github.com/viktorwinschel/mes",
        mathengine=Documenter.MathJax3(Dict(
            :loader => Dict("load" => ["[tex]/physics"]),
            :tex => Dict(
                "inlineMath" => [["\$", "\$"], ["\\(", "\\)"]],
                "tags" => "ams",
                "packages" => ["base", "ams", "autoload", "physics"],
                "preamble" => latex_preamble
            ),
        )),
    ),
    pages=[
        "Home" => "index.md",
        "Getting Started" => "getting_started/index.md",
        "Theory" => "theory.md",
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
    versions=nothing,  # Don't store multiple doc versions
    forcepush=true,   # Force push to overwrite gh-pages branch
    push_preview=false  # Don't create preview deployments
)

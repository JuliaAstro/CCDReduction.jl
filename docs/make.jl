using Documenter
using CCDReduction

DocMeta.setdocmeta!(CCDReduction, :DocTestSetup, :(using CCDReduction); recursive = true)

include("pages.jl")

makedocs(;
    modules = [CCDReduction],
    sitename = "CCDReduction.jl",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", nothing) == "true",
        canonical = "https://JuliaAstro.org/CCDReduction/stable/",
    ),
    authors = "Siddharth Lal",
    pages = pages,
)

deploydocs(;
    repo = "github.com/JuliaAstro/CCDReduction.jl.git",
    push_preview = true,
    devbranch = "main",
    versions = ["stable" => "v^", "v#.#"], # Restrict to minor releases
)

using Documenter
using CCDReduction

DocMeta.setdocmeta!(CCDReduction, :DocTestSetup, :(using CCDReduction); recursive = true)
include("pages.jl")
makedocs(modules = [CCDReduction],
    sitename = "CCDReduction.jl",
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    authors = "Siddharth Lal",
    pages = pages,
)

deploydocs(;
    repo = "github.com/JuliaAstro/CCDReduction.jl.git",
    push_preview = true,
    devbranch = "main"
)

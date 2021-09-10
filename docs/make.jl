using Documenter
using CCDReduction

DocMeta.setdocmeta!(CCDReduction, :DocTestSetup, :(using CCDReduction); recursive = true)

makedocs(modules = [CCDReduction],
    sitename = "CCDReduction.jl",
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    authors = "Siddharth Lal",
    strict = true,
    pages = [
        "Home" => "index.md",
        "API/Reference" => "api.md"
    ],
)

deploydocs(;
    repo = "github.com/JuliaAstro/CCDReduction.jl.git",
    push_preview = true,
    devbranch = "main"
)

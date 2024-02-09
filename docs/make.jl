using DLFP8Types
using Documenter

DocMeta.setdocmeta!(DLFP8Types, :DocTestSetup, :(using DLFP8Types); recursive=true)

makedocs(;
    modules=[DLFP8Types],
    authors="chengchingwen <chengchingwen214@gmail.com> and contributors",
    sitename="DLFP8Types.jl",
    format=Documenter.HTML(;
        canonical="https://chengchingwen.github.io/DLFP8Types.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/chengchingwen/DLFP8Types.jl",
    devbranch="main",
)

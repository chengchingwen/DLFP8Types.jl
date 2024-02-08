using DLFP8
using Documenter

DocMeta.setdocmeta!(DLFP8, :DocTestSetup, :(using DLFP8); recursive=true)

makedocs(;
    modules=[DLFP8],
    authors="chengchingwen <chengchingwen214@gmail.com> and contributors",
    sitename="DLFP8.jl",
    format=Documenter.HTML(;
        canonical="https://chengchingwen.github.io/DLFP8.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/chengchingwen/DLFP8.jl",
    devbranch="main",
)

using HPGL
using Documenter

makedocs(; modules=[HPGL],
         sitename="HPGL.jl",
         authors="hannahilea",
         pages=["API Documentation" => "index.md"])

deploydocs(; repo="github.com/hannahilea/HPGL.git",
           push_preview=true,
           devbranch="main")

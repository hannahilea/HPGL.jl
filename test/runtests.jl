using Test
using Aqua
using HPGL

@testset "HPGL" begin
    @testset "Aqua" begin
        Aqua.test_all(HPGL; ambiguities=false)
    end
end

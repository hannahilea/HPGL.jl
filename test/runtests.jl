using Test
using Aqua
using HPGL

@testset "HPGL" begin
    @testset "Aqua" begin
        Aqua.test_all(HPGL; ambiguities=false)
    end

    @testset "Basics" begin
        @test ismissing(set_up_serial_port_plotter())

        # Writing commands logs to file also
        logfile = joinpath(mktempdir(), "log1.hpgl")
        plot_commands!(missing, ["FOO", "BAR"]; logfile)
        @test readlines(logfile) == ["FOO;", "BAR;"]

        # Append to existing file
        plot_commands!(missing, ["rabbit"]; logfile)
        @test readlines(logfile) == ["FOO;", "BAR;", "rabbit;"]

        # Append semicolon only when needed
        logfile2 = joinpath(mktempdir(), "log2.hpgl")
        plot_commands!(missing, ["PU", "PU;"]; logfile=logfile2)
        @test readlines(logfile2) == ["PU;", "PU;"]

        # Missing logfile doesn't fail
        @test isnothing(plot_commands!(missing, ["PU", "PU;"]; logfile=missing))
    end

    @testset "`send_plotter_cmd`" begin
        # When safety up, adds a pen up
        logfile = joinpath(mktempdir(), "log1.hpgl")
        plot_commands!(missing, ["PA 30,20"]; logfile)
        @test readlines(logfile) == ["PA 30,20;", "PU;"]

        # When not safety up, don't
        logfile2 = joinpath(mktempdir(), "log2.hpgl")
        plot_commands!(missing, ["PA 30,20"]; safety_up=false, logfile=logfile2)
        @test readlines(logfile2) == ["PA 30,20;"]
    end
end

using Test
using KiteModels
using Pkg

@testset "Testing KiteModels...." begin
    path=pwd()
    tmpdir=mktempdir()
    mkpath(tmpdir)
    cd(tmpdir)
    KiteModels.copy_examples()
    @test isfile(joinpath(tmpdir, "examples", "bench.jl"))
    @test isfile(joinpath(tmpdir, "examples", "compare_kps3_kps4.jl"))
    @test isfile(joinpath(tmpdir, "examples", "menu.jl"))
    @test isfile(joinpath(tmpdir, "examples", "reel_out_1p.jl"))
    @test isfile(joinpath(tmpdir, "examples", "reel_out_4p.jl"))
    @test isfile(joinpath(tmpdir, "examples", "reel_out_4p_torque_control.jl"))
    @test isfile(joinpath(tmpdir, "examples", "simulate_simple.jl"))
    @test isfile(joinpath(tmpdir, "examples", "simulate_steering.jl"))
    if ! Sys.iswindows()
        rm(tmpdir, recursive=true)
    end
    cd(path)
    path=pwd()
    tmpdir=mktempdir()
    mkpath(tmpdir)
    cd(tmpdir)
    KiteModels.install_examples()
    @test isfile(joinpath(tmpdir, "examples", "bench.jl"))
    @test isfile(joinpath(tmpdir, "examples", "compare_kps3_kps4.jl"))
    @test isfile(joinpath(tmpdir, "examples", "menu.jl"))
    @test isfile(joinpath(tmpdir, "examples", "reel_out_1p.jl"))
    @test isfile(joinpath(tmpdir, "examples", "reel_out_4p.jl"))
    @test isfile(joinpath(tmpdir, "examples", "reel_out_4p_torque_control.jl"))
    @test isfile(joinpath(tmpdir, "examples", "simulate_simple.jl"))
    @test isfile(joinpath(tmpdir, "examples", "simulate_steering.jl"))
    if ! Sys.iswindows()
        rm(tmpdir, recursive=true)
    end
    cd(path)
    @test ! ("TestEnv" ∈ keys(Pkg.project().dependencies))
    @test ! ("Revise" ∈ keys(Pkg.project().dependencies))
    @test ! ("Plots" ∈ keys(Pkg.project().dependencies))
end

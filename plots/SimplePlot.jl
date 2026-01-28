using GLMakie
using NaturalSort
using MagnetospherePinn3D
using OrdinaryDiffEq
using DrWatson
using OrderedCollections

include("Plotting.jl")
include("PostProcess.jl")

jobdirs = sort(filter(dir -> isdir(dir), readdir(datadir(); join=true, sort=false)), lt=natural)
jobdir = jobdirs[end]
# jobdir = datadir("replace with the actual data directory path")

config = NamedTuple(load(joinpath(jobdir, "config.jld2"), "data"))
NN, _, st = create_neural_network(config, test_mode=true)
traindata = load(joinpath(jobdir, "traindata.jld2"), "data")
Θ = traindata.Θ
losses = traindata.losses

n_q = 80
n_μ = 40
n_ϕ = 80

if isfile(joinpath(jobdir, "griddata.jld2"))
    griddata = load(joinpath(jobdir, "griddata.jld2"), "data")
else
    griddata = evaluate_on_grid(n_q, n_μ, n_ϕ, NN, Θ, st, config; use_θ = false, extended = false)
    wsave(joinpath(jobdir, "griddata.jld2"), "data", griddata)
end

if isfile(joinpath(jobdir, "fieldlines.jld2"))
    fieldlines = load(joinpath(jobdir, "fieldlines.jld2"), "data")
else 
    @unpack μ, ϕ, α1 = griddata
    footprints = find_footprints(μ, ϕ, α1, μ_interval=0..1, ϕ_interval=0..2π)
    fieldlines = integrate_fieldlines(footprints, NN, Θ, st, config; q_start = 1);
    wsave(joinpath(jobdir, "fieldlines.jld2"), "data", fieldlines)
end

f = Figure()
ax = Makie.Axis(f[1, 1], xlabel="Iteration", ylabel="Loss", yscale=log10)
lines!(ax, losses)
display(GLMakie.Screen(), f)


target_mu = findnearest(μ, cosd(config.θ1))
chosen_lines = filter(line -> line.μ[1] in [target_mu], fieldlines)
f = plot_magnetosphere_3d(chosen_lines, α1[end, :, :]; use_lscene=true)
# save(joinpath("figures", "twisted_magnetosphere_M=$(params.model.M)_a0=$(params.model.alpha0)_island.png"), f, update=false, size=(750, 600))


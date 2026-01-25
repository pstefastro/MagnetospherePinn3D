using GLMakie
using LaTeXStrings
using NaturalSort
using MagnetospherePinn3D
using OrdinaryDiffEq
using Integrals
using DataFrames
using DrWatson

include("Plotting.jl")
include("PostProcess.jl")

jobdir = datadir("sequence_alphamax_axisymmetric/")
subjobdirs = sort(filter(dir -> isdir(dir), readdir(abspath(jobdir); join=true, sort=false)), lt=natural)
subjobdir = subjobdirs[32]

config = NamedTuple(load(joinpath(subjobdir, "config.jld2"), "data"))
NN, _, st = create_neural_network(config, test_mode=true)
Θ = load(joinpath(subjobdir, "trained_model.jld2"), "Θ_trained")
griddata = load(joinpath(subjobdir, "griddata.jld2"), "data")
fieldlines = load(joinpath(subjobdir, "fieldlines.jld2"), "data")

@unpack μ, ϕ, α1 = griddata
target_mu = findnearest(μ, cosd(config.θ1))
chosen_lines = filter(line -> line.μ[1] in [target_mu], fieldlines)
f = plot_magnetosphere_3d(chosen_lines, α1[end, :, :]; use_lscene=true)
# save(joinpath("figures", "twisted_magnetosphere_M=$(params.model.M)_a0=$(params.model.alpha0)_island.png"), f, update=false, size=(750, 600))

losses = load(joinpath(subjobdir, "traindata.jld2"), "data")[:losses][1:1, :]
f = plot_losses(losses)
save(joinpath("plots", "figures", "loss_M=$(config.compactness)_a0=$(config.α0).png"), f, update=false, size=(750, 600))

using DataFrames
using DrWatson
using GLMakie
using LaTeXStrings
using MagnetospherePinn3D
using NaturalSort

include("Plotting.jl")
include("PostProcess.jl")

jobdir = datadir("sequence_alphamax_3d/")

# Common loader function
load_data = filename -> load(filename, "data")

# Collect config results
configs = collect_results(jobdir;
    subfolders = true,
    rinclude = [r"config"],
    white_list = [:α0, :compactness],
    load_function = load_data
)

# Collect training results with computed loss
traindata = collect_results(jobdir;
    subfolders = true,
    rinclude = [r"traindata"],
    white_list = [],
    special_list = [:loss => data -> data[:losses][1][findlast(!isnan, data[:losses][1])]],
    load_function = load_data
)

# Merge results by path and sort naturally
results = leftjoin(configs, traindata[!, [:path, :loss]], on = :path, makeunique=true) |>
    df -> sort(df, :path, lt = natural)

selected_runs = filter(row -> row[:compactness] == 0.0 && (row[:α0] == 1.0 || row[:α0] == 2.0 || row[:α0] == 3.0), results)
fieldlines = [load(joinpath(jobdir, dirname(path), "fieldlines.jld2"), "data") for path in selected_runs[!, :path]]
griddata = [load(joinpath(jobdir, dirname(path), "griddata.jld2"), "data") for path in selected_runs[!, :path]]

# Compute the global maximum of all α1 arrays
α_max = maximum([maximum(grid[:α1]) for grid in griddata])

f = Figure(size=(1200, 800))
ax = [Axis3(f[1, i], 
    aspect = :data,
    protrusions = 0,
    # limits=((-2,2), (-2, 2), (-2,2)),
    # ytickformat = values -> ["$(Int(-value))" for value in values],
    azimuth = 3, elevation = 0.1,
    title = L"\alpha_0 = %$(Int(selected_runs[i, :α0]))",
    titlesize = 30,
    titlegap = -200
) for i in eachindex(fieldlines)]

cmap = cgrad(:gist_heat, 100, rev=true)
hidedecorations!.(ax)
hidespines!.(ax)

# Plot all models in the same axis
for i in eachindex(ax)

    @unpack μ, ϕ, α1 = griddata[i]
    # Plot the star surface for this model
    star = mesh!(ax[i], Sphere(Point3(0, 0, 0), 1.0),
        color=α1[end, :, :], colormap=cmap, interpolate=true,
        colorrange=(0.0, α_max)
    )
    # Plot fieldlines for this model
    # chosen_lines = filter(line -> line.α[1] in 0.9..3, fieldlines[i])
    chosen_lines = filter(line -> line.μ[1] in findnearest(μ[end, :, 1], cosd(45)), fieldlines[i])
    plot_fieldlines(ax[i], chosen_lines, α_max, cmap)

    # Add a single colorbar for all models
    Colorbar(f[1, length(fieldlines) + 1], star, 
        label=L"α \ [R^{-1}]", labelsize = 25, labelrotation=3π/2,
        ticklabelsize = 20,
        height = Relative(1/2)
    )
end
# [colsize!(f.layout, col, Aspect(1, 0.6)) for col in 1:3]
resize_to_layout!(f)
display(GLMakie.Screen(), f, update=false)
# save(plotsdir("figures", "twisted_magnetospheres_B.png"), f, update=false)



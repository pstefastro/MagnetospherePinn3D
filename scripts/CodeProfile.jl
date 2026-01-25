using MagnetospherePinn3D
using Profile
using ProfileView


config = create_config()
jobdir = setup_jobdir(config)

configs = dict_list(config)
expanded_keys = filter(k -> config[k] isa Vector && (length(config[k]) > 1), keys(config))

function sweep_configs(configs, jobdir, expanded_keys)
    for (i, c) in enumerate(configs)

        setup_subjobdir(c, jobdir, expanded_keys)
        c = NamedTuple(c)
        
        @info "Running main function with configuration $i / $(length(configs)):"
        for (param, value) in [k => c[k] for k in expanded_keys if k in keys(config)]
            println("\t$(Symbol(param)) = $(get_short_name(value))")
        end

        GC.gc(true)
        main(c)
    end
end

ProfileView.@profview sweep_configs(configs, jobdir, expanded_keys)

# @profile sweep_configs(configs, jobdir, expanded_keys)

# # Profile.print()
# ProfileView.view()
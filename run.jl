
# ! import AnyMOD and options

using Gurobi, AnyMOD, CSV, FourierAnalysis

h = ARGS[1]
res = ARGS[2]
cyc = ARGS[3]
t_int = parse(Int,ARGS[4]) # number of threads


scr_str = "h" * h * "_" * res * "_" * cyc

# ! create and run model
anyM = anyModel(["_basis","_resolution/" * res,"_cyclic/" * cyc,"timeSeries/" * h * "hours_2008_only2040"],"results", supTsLvl = 2, shortExp = 5, redStep = 1.0, emissionLoss = false, objName = scr_str)
createOptModel!(anyM)
setObjective!(:cost,anyM)

set_optimizer(anyM.optModel, Gurobi.Optimizer)
set_optimizer_attribute(anyM.optModel, "Method", 2);
set_optimizer_attribute(anyM.optModel, "Crossover", 0);
set_optimizer_attribute(anyM.optModel, "Threads",t_int);
set_optimizer_attribute(anyM.optModel, "BarConvTol", 1e-5);

optimize!(anyM.optModel)

# ! report results
reportResults(:summary,anyM, addRep = (:cyc, :flh))

# write storage levels
stTech_arr = ["lithiumBattery","redoxBattery","heatpumpAirSpace","heatpumpGroundSpace","resistiveHeatSpace","largeWaterTank","pitThermalStorage","h2StorageCavern","h2StorageTank","solarThermalResi_a","solarThermalResi_b","pumpedStorage","reservoir"]

for st in stTech_arr
    # get data 
    stLvl_df = printObject(anyM.parts.tech[Symbol(st)].var[:stLvl],anyM, rtnDf = (:csvDf,))
    select!(stLvl_df,[:timestep_dispatch,:region_dispatch,:variable])
    stLvl_df[!,:region_dispatch] = map(x -> split(x," < ")[end], stLvl_df[!,:region_dispatch])
    # unstack data
    stLvl_df = unstack(stLvl_df,:region_dispatch,:variable)
    stLvl_df[!,:timestep_dispatch] = map(x -> split(x," < ")[end], stLvl_df[!,:timestep_dispatch])
    sort!(stLvl_df,[:timestep_dispatch])
    # create aggregated column
    stLvl_df[!,:agg] = map(x -> sum(x[filter(y -> !(y == "timestep_dispatch"),names(stLvl_df))]), eachrow(stLvl_df))
    # write data
    CSV.write("results/stLvl_" * scr_str * "_" * st * ".csv",stLvl_df)
end

# fourier FourierAnalysis of storage pattern

for st in stTech_arr

    stLvl_gdf = groupby(printObject(anyM.parts.tech[Symbol(st)].var[:stLvl],anyM, rtnDf = (:csvDf,)),[:region_dispatch])

    # create dataframe for fourier results
    frq_arr = FourierAnalysis.rfftfreq(size(stLvl_gdf[1],1))
    four_df = DataFrame(frq = frq_arr, drt = 1 ./ frq_arr .* (8760/size(stLvl_gdf[1],1)) )

    for gdf in stLvl_gdf
        gdf[!,:timestep_dispatch] = map(x -> split(x," < ")[end], gdf[!,:timestep_dispatch])
        sort!(gdf,[:timestep_dispatch])
        stLvl_arr = gdf[!,:variable] .- mean(gdf[!,:variable])
        four_df[!,Symbol(split(gdf[1,:region_dispatch]," < ")[end])] = abs.(FourierAnalysis.rfft(stLvl_arr))
    end

    four_df[!,:agg] = map(x -> sum(x[filter(y -> !(y in ("frq","drt")),names(four_df))]), eachrow(four_df))
    CSV.write("results/fourier_" * scr_str * "_" * st * ".csv",four_df)
end
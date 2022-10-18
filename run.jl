
# ! import AnyMOD and options

using Gurobi, AnyMOD

h = ARGS[1]
res = ARGS[2]
cyc = ARGS[3]
t_int = parse(Int,ARGS[4]) # number of threads

using AnyMOD, CSV
using Gurobi 


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
reportResults(:summary,anyM)

# write storage levels

stTech_arr = ["lithiumBattery","redoxBattery","heatpumpAirSpace","heatpumpGroundSpace","resistiveHeatSpace","largeWaterTank","pitThermalStorage","h2StorageCavern","h2StorageTank","solarThermalResi_a","solarThermalResi_b","pumpedStorage","reservoir"]

for st in stTech_arr

    stLvl_df = printObject(anyM.parts.tech[Symbol(st)].var[:stLvl],anyM, rtnDf = (:csvDf,))
    filter!(x -> x.region_dispatch[end-1:end] == "DE" ,stLvl_df)
    select!(stLvl_df,[:timestep_dispatch,:variable])
    stLvl_df = combine(x -> (variable = sum(x.variable)),groupby(stLvl_df,[:timestep_dispatch]))
    CSV.write("results/stLvl_" * scr_str * "_" * st * ".csv",stLvl_df)
end
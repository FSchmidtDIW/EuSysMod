# import AnyMOD

b = "C:/Users/lgoeke/git/AnyMOD.jl/"
	
using Base.Threads, CSV, Dates, LinearAlgebra, Requires, YAML
using MathOptInterface, Reexport, Statistics, SparseArrays
using DataFrames, JuMP, Suppressor, Plotly
using DelimitedFiles

include(b* "src/objects.jl")
include(b* "src/tools.jl")
include(b* "src/modelCreation.jl")
include(b* "src/decomposition.jl")

include(b* "src/optModel/technology.jl")
include(b* "src/optModel/exchange.jl")
include(b* "src/optModel/system.jl")
include(b* "src/optModel/cost.jl")
include(b* "src/optModel/other.jl")
include(b* "src/optModel/objective.jl")

include(b* "src/dataHandling/mapping.jl")
include(b* "src/dataHandling/parameter.jl")
include(b* "src/dataHandling/readIn.jl")
include(b* "src/dataHandling/tree.jl")
include(b* "src/dataHandling/util.jl")

include(b* "src/dataHandling/gurobiTools.jl")

# run mono alt: perfect (1.00857817e+06 in 81itr/250s), limited foresight (1.01170975e+06 in 72itr/200s)
# run mono neu: perfect (1.00857817e+06 in 81itr/290s), limited foresight (1.01170975e+06 in 72itr/186s)

anyM = anyModel(["_basis","timeSeries/greenfield_test"],"results", objName = "test_mono_per", supTsLvl = 2, shortExp = 5)
anyM = anyModel(["_basis","timeSeries/greenfield_test"],"results", objName = "test_mono_lim", supTsLvl = 2, shortExp = 5, lvlFrs = 3)

createOptModel!(anyM)
setObjective!(:cost,anyM)

set_optimizer(anyM.optModel, Gurobi.Optimizer)
set_optimizer_attribute(anyM.optModel, "Method", 2);
set_optimizer_attribute(anyM.optModel, "Crossover", 0);
set_optimizer_attribute(anyM.optModel, "Threads",4);
set_optimizer_attribute(anyM.optModel, "BarConvTol", 1e-5);

optimize!(anyM.optModel)

reportResults(:summary,anyM, addObjName = true)

# write storage level for checking
for tSym in (:reservoir,:h2StorageCavern)
    stLvl_df = combine(x -> (lvl = sum(value.(x.var)),), groupby(anyM.parts.tech[tSym].var[:stLvl],[:Ts_dis,:scr]))
    stLvl_df = unstack(sort(stLvl_df,:Ts_dis),:scr,:lvl)
    CSV.write("results/stLvl_" * string(tSym) * "_" * ".csv",stLvl_df)
end


tSym = :solarThermalResi_a
tInt = sysInt(tSym,anyM.sets[:Te])
part = anyM.parts.tech[tSym]
prepTech_dic = prepSys_dic[:Te][tSym]

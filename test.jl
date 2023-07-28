b = "C:/Users/lgoeke/git/AnyMOD.jl/"
	
using Base.Threads, CSV, Dates, LinearAlgebra, Requires, YAML
using MathOptInterface, Reexport, Statistics, SparseArrays
using DataFrames, JuMP, Suppressor, Plotly
using DelimitedFiles, CategoricalArrays

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


h = "96"
inSub = "4"
t_int = 4
impH2 = "none"

b = "" # add the model dir here
input_arr = [b * "_basis",b * "impH2/" * impH2,b * "timeSeries/" * h * "hours_det",b * "timeSeries/" * h * "hours_inSub" * inSub]
resultDir_str = b * "results"

# create and solve model
anyM = anyModel(input_arr, resultDir_str, objName = h * "hours_inSub" * inSub * "_impH2_" * impH2, lvlFrs = 2, supTsLvl = 1,reportLvl = 2, shortExp = 10, coefRng = (mat = (1e-2,1e3), rhs = (1e0,1e3)), scaFac = (capa = 1e2, capaStSize = 1e3, insCapa = 1e1, dispConv = 0.4e1, dispSt = 1e1, dispExc = 1e2, dispTrd = 1e3, costDisp = 1e1, costCapa = 1e2, obj = 1e0))

createOptModel!(anyM)
setObjective!(:cost,anyM)

set_optimizer(anyM.optModel, Gurobi.Optimizer)
set_optimizer_attribute(anyM.optModel, "Method", 2);
set_optimizer_attribute(anyM.optModel, "Crossover", 0);
set_optimizer_attribute(anyM.optModel, "Threads",t_int);

set_optimizer_attribute(anyM.optModel, "BarConvTol", 1e-3);

optimize!(anyM.optModel)

# reporting
reportResults(:summary,anyM, addRep = (:flh,:cyc,:effConv))
reportResults(:cost,anyM)
reportResults(:exchange,anyM)
reportTimeSeries(:electricity,anyM)

plotSankeyDiagram(anyM, frsScr = Dict("eins" => Dict("2030" => ("scr1","scr1","scr1","scr1"),)), formatScr = (3,true))

# write storage levels to csv
for tSym in (:reservoir,:h2Cavern)
    stLvl_df = combine(x -> (lvl = sum(value.(x.var)),), groupby(anyM.parts.tech[tSym].var[:stLvl],[:Ts_dis,:scr]))
    stLvl_df = unstack(sort(stLvl_df,:Ts_dis),:scr,:lvl)
    CSV.write(resultDir_str * "/stLvl_" * string(tSym) * "_" * h * "hours_inSub" * inSub * ".csv",stLvl_df)
end

# write stress indicator
c_sym = :electricity
cns_df = copy(anyM.parts.bal.cns[Symbol(:enBal,makeUp(c_sym))])
cns_df[!,:value] .= dual.(cns_df[!,:cns])

aggDual_df = combine(x -> (value = sum(x.value),),groupby(cns_df,[:Ts_disSup,:Ts_dis,:C,:scr]))
printObject(aggDual_df,anyM)



# make script for data conversion


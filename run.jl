#import Pkg; Pkg.activate(".")
# Pkg.instantiate()
# ! import AnyMOD and packages

using AnyMOD, Gurobi, CSV

h = ARGS[1]
inSub = ARGS[2]
impH2 = ARGS[3]
t_int = parse(Int,ARGS[4])

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
set_optimizer_attribute(anyM.optModel, "NumericFocus", 3);
set_optimizer_attribute(anyM.optModel, "Threads",t_int);

optimize!(anyM.optModel)

# reporting
reportResults(:cost,anyM)
reportResults(:summary,anyM)
reportResults(:exchange,anyM)

for tSym in (:reservoir,:h2Cavern)
    stLvl_df = combine(x -> (lvl = sum(value.(x.var)),), groupby(anyM.parts.tech[tSym].var[:stLvl],[:Ts_dis,:scr]))
    stLvl_df = unstack(sort(stLvl_df,:Ts_dis),:scr,:lvl)
    CSV.write(resultDir_str * "/stLvl_" * string(tSym) * "_" * h * "hours_inSub" * inSub * "_impH2_" * impH2 * ".csv",stLvl_df)
end

reportTimeSeries(:electricity,anyM)
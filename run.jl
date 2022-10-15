
<<<<<<< HEAD
# ! import AnyMOD and packages

b = "C:/Users/pacop/.julia/dev/AnyMOD.jl/"
=======
# ! string here define scenario, overwrite ARGS with respective values for hard-coding scenarios according to comments
h = ARGS[1] # resolution of time-series for actual solve, can be 96, 1752, 4392, or 8760
h_heu = ARGS[2] # resolution of time-series for pre-screening, can be 96, 1752, 4392, or 8760
grid = ARGS[3] # scenario for grid expansion, can be "_gridExp" and "_noGridExp"
t_int = parse(Int,ARGS[4]) # number of threads

obj_str = h * "hours_" * h_heu * "hoursHeu" * grid
temp_dir = "tempFix_" * obj_str # directory for temporary folder
>>>>>>> 98ce0c599e3d910e891f14494065154c634ced35

using Base.Threads, CSV, Dates, LinearAlgebra, Requires, YAML
using MathOptInterface, Reexport, Statistics, PyCall, SparseArrays
using DataFrames, JuMP, Suppressor
using DelimitedFiles

<<<<<<< HEAD
pyimport_conda("networkx","networkx")
pyimport_conda("matplotlib.pyplot","matplotlib")
pyimport_conda("plotly","plotly")
=======
inputMod_arr = ["_basis",grid,"timeSeries/" * h * "hours_2008_only2040",temp_dir]
inputHeu_arr = ["_basis",grid,"timeSeries/" * h_heu * "hours_2008_only2040"]
resultDir_str = "results"
>>>>>>> 98ce0c599e3d910e891f14494065154c634ced35

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

# ! run model
h = "1752"

anyM = anyModel(["_basis","timeSeries/" * h * "hours_2008_only2040"],"results", supTsLvl = 2, shortExp = 5, redStep = 1.0, emissionLoss = false)
createOptModel!(anyM)
setObjective!(:cost,anyM)

set_optimizer(anyM.optModel, Gurobi.Optimizer)
set_optimizer_attribute(anyM.optModel, "Method", 2);
set_optimizer_attribute(anyM.optModel, "Crossover", 0);
set_optimizer_attribute(anyM.optModel, "BarConvTol", 1e-5);

optimize!(anyM.optModel)

reportResults(:summary,anyM)

<<<<<<< HEAD
printObject(anyM.parts.tech[:heatpumpAirSpace].cns[:stBal],anyM)
=======
include("plottingFiles/formatForPlots.jl")

plotSankeyDiagram(anyM,ymlFilter = "plottingFiles/powerAll.yml", name = "powerAll", dropDown = (:timestep,), savaData = true)
plotSankeyDiagram(anyM,ymlFilter = "plottingFiles/transport.yml", name = "powerToX", dropDown = (:timestep,))
plotSankeyDiagram(anyM,ymlFilter = "plottingFiles/powerToX.yml", name = "powerToX", dropDown = (:timestep,))
plotSankeyDiagram(anyM,ymlFilter = "plottingFiles/processHeat.yml", name = "processHeat", dropDown = (:timestep,))
plotSankeyDiagram(anyM,ymlFilter = "plottingFiles/spaceAndDistrictHeat.yml", name = "spaceAndDistrictHeat", dropDown = (:timestep,))

plotSankeyDiagram(anyM,ymlFilter = "plottingFiles/powerFull.yml", name = "powerFull", dropDown = (:timestep,),  rmvNode = ("exchange losses; H2","exchange losses; crude oil","final demand; process heat - low","final demand; process heat - medium","final demand; process heat - high","trade buy; non-solid biomass"))
plotSankeyDiagram(anyM,ymlFilter = "plottingFiles/h2Full.yml", name = "h2Full", dropDown = (:timestep,), rmvNode = ("final demand; electricity","exchange losses; electricity","exchange losses; crude oil"))

#endregion
>>>>>>> 98ce0c599e3d910e891f14494065154c634ced35

tSym = :heatpumpAirSpace
tInt = sysInt(tSym,anyM.sets[:Te])
part = anyM.parts.tech[tSym]
prepTech_dic = prepSys_dic[:Te][tSym]



inDir = ["_basis","timeSeries/" * h * "hours_2008_only2040"]
outDir = "results"

objName = ""

csvDelim = ","
interCapa = :linear
supTsLvl = 1
shortExp = 10
redStep = 1.0
holdFixed = false
emissionLoss = true
forceScr = nothing
reportLvl = 2
errCheckLvl = 1
errWrtLvl = 1
coefRng = (mat = (1e-2,1e4), rhs = (1e-2,1e2))
scaFac = (capa = 1e2,  capaStSize = 1e2, insCapa = 1e1,dispConv = 1e3, dispSt = 1e5, dispExc = 1e3, dispTrd = 1e3, costDisp = 1e1, costCapa = 1e2, obj = 1e0)
bound = (capa = NaN, disp = NaN, obj = NaN)
avaMin = 0.01
checkRng = (print = false, all = true)
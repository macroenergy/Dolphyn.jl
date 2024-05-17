using Dolphyn
using Gurobi

EP, myinputs, mysetup, adjusted_outpath = run_case(@__DIR__; optimizer=Gurobi.Optimizer, return_outputs=true)

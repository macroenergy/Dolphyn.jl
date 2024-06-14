using Dolphyn
using Gurobi
using JuMP
using DataFrames
using CSV
EP, myinputs, mysetup, adjusted_outpath = run_case(@__DIR__; optimizer=Gurobi.Optimizer)

println("CarProcH2Cap ", JuMP.value.(EP[:vCarProcH2Cap]))

# df = DataFrame(value.(EP[:eCarProcH2Supply]),:auto)

## Export all time-dependent variables
#vCarProcOutput
#vCarProcH2output
#vCarProcInput

# for i in eachindex(constraint_ref)
#     println("Constraint $(i): ", constraint_ref[i])
# end



#CSV.write(joinpath(adjusted_outpath, "HSC_carrier_H2_supply.csv"), df)
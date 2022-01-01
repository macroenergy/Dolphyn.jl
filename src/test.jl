using JuMP
value.(sum(EP[:eH2NetpowerConsumptionByAll]))
#value.(EP[:vH2CAPCHARGE])
# Script to test outputs of the model
println(string("ParameterScale = "), mysetup["ParameterScale"])

println(string("Power System Capacity \n"), value.(EP[:eTotalCap]))
println(string("H2 Gen. Capacity \n"), value.(EP[:eH2GenTotalCap])[:])
dfH2Gen = myinputs["dfH2Gen"]
println(string("H2 process fuel use: "),dfH2Gen[!,:etaFuel_MMBtu_p_tonne])
println(string("H2 process elec use: "),dfH2Gen[!,:etaP2G_MWh_p_tonne])
println(string("H2 GEN COMMIT: "),myinputs["H2_GEN_COMMIT"])
println(string("H2 GEN NO COMMIT: "), myinputs["H2_GEN_NO_COMMIT"])

T = myinputs["T"]
Z = myinputs["Z"]


println(string("H2 Gen Decision Variable \n"),value.(EP[:vH2GenNewCap])[:])

println(string("Objective function value: "),value.(EP[:eObj]))
println(string("Power Fix Cost by type: "), value.(EP[:eCFix]))
println(string("Power Var Cost by type: "), sum(value.(EP[:eCVar_out])[:,t] for t in 1:T))

println(string("H2 Fix Cost by type: "), value.(EP[:eH2GenCFix]))
println(string("H2 Var Cost by type: "), sum(value.(EP[:eCH2GenVar_out])[:,t] for t in 1:T))

# Summations are missing omega multiplier for scaling up to annual numbers
println(string("power use by H2GenCommit:"),sum(sum(value.(EP[:ePowerBalanceH2GenCommit])[t,z] for t in 1:T) for z in 1:Z))
println(string("power use by H2GenNoCommit:"),sum(sum(value.(EP[:ePowerBalanceH2GenNoCommit])[t,z] for t in 1:T) for z in 1:Z))
println(string("power use by Compresion:"),sum(sum(value.(EP[:ePowerBalanceH2PipeCompression])[t,z] for t in 1:T) for z in 1:Z))
#println(sum(sum(value.(EP[:ePowerBalanceH2GenNoCommit])[t,z] for t in 1:T) for z in 1:Z))


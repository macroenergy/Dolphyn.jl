@doc raw"""
	write_reliability(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting dual variable of maximum non-served energy constraint (shadow price of reliability constraint) for each model zone and time step.
"""
function write_reliability(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	T = inputs["T"]::Int     # Number of time steps (hours)
	Z = inputs["Z"]::Int     # Number of zones

	# reliability: Dual variable of maximum NSE constraint = shadow value of reliability constraint
	dfReliability = DataFrame(Zone = 1:Z)
	# Dividing dual variable for each hour with corresponding hourly weight to retrieve marginal cost of generation
	scale_factor = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1
	dfReliability = hcat(dfReliability, DataFrame(AnnualMean=Array{Union{Missing,Float32}}(undef, Z)), DataFrame(transpose(dual.(EP[:cMaxNSE])./inputs["omega"]*scale_factor), :auto))

	auxNew_Names=[Symbol("Zone");Symbol("AnnualMean");[Symbol("t$t") for t in 1:T]]
	rename!(dfReliability,auxNew_Names)

        dfReliability.AnnualMean .= [sum(dfReliability[i, r"t"])/T for i in 1:Z] 

	CSV.write(joinpath(path, "reliability.csv"), dftranspose(dfReliability, false), writeheader=false)

end

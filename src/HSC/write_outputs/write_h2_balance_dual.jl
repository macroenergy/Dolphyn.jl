

function write_h2_balance_dual(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	
	T = inputs["T"]::Int     # Number of time steps (hours)
	Z = inputs["Z"]::Int     # Number of zones

	# # Dual of storage level (state of charge) balance of each resource in each time step
	dfH2BalanceDual = DataFrame(Zone = 1:Z)
	# Define an empty array
	x1 = Array{Float64}(undef, Z, T)
	dual_values =Array{Float64}(undef, Z, T)

	# Loop over W separately hours_per_subperiod
	for z in 1:Z
		for t in 1:T
			x1[z,t] = dual.(EP[:cH2Balance])[t,z] #Use this for getting dual values and put in the extracted codes from PJM
		end
	end

	# Incorporating effect of time step weights (When OperationWrapping=1) and Parameter scaling (ParameterScale=1) on dual variables
	for z in 1:Z
		if setup["ParameterScale"]==1
			dual_values[z,:] = x1[z,:]./inputs["omega"] *ModelScalingFactor
		else
			dual_values[z,:] = x1[z,:]./inputs["omega"]
		end
	end

	dfH2BalanceDual=hcat(dfH2BalanceDual, DataFrame(dual_values, :auto))
	rename!(dfH2BalanceDual,[Symbol("Zone");[Symbol("t$t") for t in 1:T]])

	CSV.write(string(path,sep,"HSC_h2_balance_dual.csv"), dftranspose(dfH2BalanceDual, false), writeheader=false)

end
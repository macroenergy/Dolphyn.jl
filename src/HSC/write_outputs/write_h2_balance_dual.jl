

function write_h2_balance_dual(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	omega = inputs["omega"] # Time step weights
	setup["ParameterScale"]==1 ? SCALING = ModelScalingFactor : SCALING = 1.0

	# # Dual of storage level (state of charge) balance of each resource in each time step
	dfH2BalanceDual = DataFrame(Zone = 1:Z)
	dual_values = transpose(dual.(EP[:cH2Balance]) ./ omega) .* SCALING

	dfH2BalanceDual=hcat(dfH2BalanceDual, DataFrame(dual_values, :auto))
	rename!(dfH2BalanceDual,[Symbol("Zone");[Symbol("t$t") for t in 1:T]])

	CSV.write(string(path,sep,"HSC_h2_balance_dual.csv"), dftranspose(dfH2BalanceDual, false), writeheader=false)

end
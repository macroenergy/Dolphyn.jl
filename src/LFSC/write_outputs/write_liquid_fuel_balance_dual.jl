@doc raw"""
	write_liquid_fuel_balance_dual(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the liquid fuels balance dual of resources across different zones with time for each type of fuels.
"""
function write_liquid_fuel_balance_dual(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	omega = inputs["omega"] # Time step weights
	setup["ParameterScale"]==1 ? SCALING = ModelScalingFactor : SCALING = 1.0

	# # Dual of storage level (state of charge) balance of each resource in each time step
	dfDieselBalanceDual = DataFrame(Zone = 1:Z)
	# Define an empty array
	dual_values = Array{Float64}(undef, Z, T)
	dual_values .= dual(EP[:cLFAnnualDieselBalance]) * SCALING
	dual_values ./= transpose(omega)

	dfDieselBalanceDual=hcat(dfDieselBalanceDual, DataFrame(dual_values, :auto))
	rename!(dfDieselBalanceDual,[Symbol("Zone");[Symbol("t$t") for t in 1:T]])

	CSV.write(string(path,sep,"LF_Diesel_Balance_Dual.csv"), dftranspose(dfDieselBalanceDual, false), writeheader=false)

	# # Dual of storage level (state of charge) balance of each resource in each time step
	dfJetfuelBalanceDual = DataFrame(Zone = 1:Z)
	# Define an empty array
	dual_values = Array{Float64}(undef, Z, T)
	dual_values .= dual(EP[:cLFAnnualJetfuelBalance]) * SCALING
	dual_values ./= transpose(omega)

	dfJetfuelBalanceDual=hcat(dfJetfuelBalanceDual, DataFrame(dual_values, :auto))
	rename!(dfJetfuelBalanceDual,[Symbol("Zone");[Symbol("t$t") for t in 1:T]])

	CSV.write(string(path,sep,"LF_Jetfuel_Balance_Dual.csv"), dftranspose(dfJetfuelBalanceDual, false), writeheader=false)

	# # Dual of storage level (state of charge) balance of each resource in each time step
	dfGasolineBalanceDual = DataFrame(Zone = 1:Z)
	# Define an empty array
	dual_values = Array{Float64}(undef, Z, T)
	dual_values .= dual(EP[:cLFAnnualGasolineBalance]) * SCALING
	dual_values ./= transpose(omega)

	dfGasolineBalanceDual=hcat(dfGasolineBalanceDual, DataFrame(dual_values, :auto))
	rename!(dfGasolineBalanceDual,[Symbol("Zone");[Symbol("t$t") for t in 1:T]])

	CSV.write(string(path,sep,"LF_Gasoline_Balance_Dual.csv"), dftranspose(dfGasolineBalanceDual, false), writeheader=false)

	if setup["ModelBESC"] == 1
		if setup["Bio_Ethanol_On"] == 1

			# # Dual of storage level (state of charge) balance of each resource in each time step
			dfBioethanolBalanceDual = DataFrame(Zone = 1:Z)
			# Define an empty array
			dual_values = Array{Float64}(undef, Z, T)
			dual_values .= dual(EP[:cAnnualEthanolBalance]) * SCALING
			dual_values ./= transpose(omega)

			dfBioethanolBalanceDual=hcat(dfBioethanolBalanceDual, DataFrame(dual_values, :auto))
			rename!(dfBioethanolBalanceDual,[Symbol("Zone");[Symbol("t$t") for t in 1:T]])

			CSV.write(string(path,sep,"LF_Ethanol_Balance_Dual.csv"), dftranspose(dfBioethanolBalanceDual, false), writeheader=false)
		end
	end

end

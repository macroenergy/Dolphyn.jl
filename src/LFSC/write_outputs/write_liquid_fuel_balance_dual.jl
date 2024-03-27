
@doc raw"""
	write_liquid_fuel_balance_dual(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the liquid fuels balance dual of resources across different zones with time for each type of fuels.
"""
function write_liquid_fuel_balance_dual(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

	T = inputs["T"]::Int     # Number of time steps (hours)
	Z = inputs["Z"]::Int     # Number of zones

	# # Dual of storage level (state of charge) balance of each resource in each time step
	dfDieselBalanceDual = DataFrame(Zone = 1:Z)
	# Define an empty array
	x1 = Array{Float64}(undef, Z, T)
	dual_values =Array{Float64}(undef, Z, T)

	# Loop over W separately hours_per_subperiod
	for z in 1:Z
		for t in 1:T
			x1[z,t] = dual.(EP[:cLFAnnualDieselBalance]) #Use this for getting dual values and put in the extracted codes from PJM
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

	dfDieselBalanceDual=hcat(dfDieselBalanceDual, DataFrame(dual_values, :auto))
	rename!(dfDieselBalanceDual,[Symbol("Zone");[Symbol("t$t") for t in 1:T]])

	CSV.write(string(path,sep,"LF_Diesel_Balance_Dual.csv"), dftranspose(dfDieselBalanceDual, false), writeheader=false)

	# # Dual of storage level (state of charge) balance of each resource in each time step
	dfJetfuelBalanceDual = DataFrame(Zone = 1:Z)
	# Define an empty array
	x1 = Array{Float64}(undef, Z, T)
	dual_values =Array{Float64}(undef, Z, T)

	# Loop over W separately hours_per_subperiod
	for z in 1:Z
		for t in 1:T
			x1[z,t] = dual.(EP[:cLFAnnualJetfuelBalance]) #Use this for getting dual values and put in the extracted codes from PJM
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

	dfJetfuelBalanceDual=hcat(dfJetfuelBalanceDual, DataFrame(dual_values, :auto))
	rename!(dfJetfuelBalanceDual,[Symbol("Zone");[Symbol("t$t") for t in 1:T]])

	CSV.write(string(path,sep,"LF_Jetfuel_Balance_Dual.csv"), dftranspose(dfJetfuelBalanceDual, false), writeheader=false)

	# # Dual of storage level (state of charge) balance of each resource in each time step
	dfGasolineBalanceDual = DataFrame(Zone = 1:Z)
	# Define an empty array
	x1 = Array{Float64}(undef, Z, T)
	dual_values =Array{Float64}(undef, Z, T)

	# Loop over W separately hours_per_subperiod
	for z in 1:Z
		for t in 1:T
			x1[z,t] = dual.(EP[:cLFAnnualGasolineBalance]) #Use this for getting dual values and put in the extracted codes from PJM
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

	dfGasolineBalanceDual=hcat(dfGasolineBalanceDual, DataFrame(dual_values, :auto))
	rename!(dfGasolineBalanceDual,[Symbol("Zone");[Symbol("t$t") for t in 1:T]])

	CSV.write(string(path,sep,"LF_Gasoline_Balance_Dual.csv"), dftranspose(dfGasolineBalanceDual, false), writeheader=false)

	if setup["ModelBIO"] == 1
		if setup["BIO_Ethanol_On"] == 1

			# # Dual of storage level (state of charge) balance of each resource in each time step
			dfBioethanolBalanceDual = DataFrame(Zone = 1:Z)
			# Define an empty array
			x1 = Array{Float64}(undef, Z, T)
			dual_values =Array{Float64}(undef, Z, T)

			# Loop over W separately hours_per_subperiod
			for z in 1:Z
				for t in 1:T
					x1[z,t] = dual.(EP[:cAnnualEthanolBalance]) #Use this for getting dual values and put in the extracted codes from PJM
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

			dfBioethanolBalanceDual=hcat(dfBioethanolBalanceDual, DataFrame(dual_values, :auto))
			rename!(dfBioethanolBalanceDual,[Symbol("Zone");[Symbol("t$t") for t in 1:T]])

			CSV.write(string(path,sep,"LF_Ethanol_Balance_Dual.csv"), dftranspose(dfBioethanolBalanceDual, false), writeheader=false)
		end
	end

end

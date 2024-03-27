

@doc raw"""
	write_co2_storage_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting CO2 storage capacity.
"""
function write_co2_storage_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	# Capacity decisions
	dfCO2Storage = inputs["dfCO2Storage"]
	capcapture = zeros(size(inputs["CO2_STORAGE_NAME"]))

	for i in 1:inputs["CO2_STOR_ALL"]
		if setup["ParameterScale"]==1
			capcapture[i] = value(EP[:vCapacity_CO2_Storage_per_type][i])*ModelScalingFactor
		else
			capcapture[i] = value(EP[:vCapacity_CO2_Storage_per_type][i])
		end
	end

	dfCap = DataFrame(
		Resource = inputs["CO2_STORAGE_NAME"], Zone = dfCO2Storage[!,:Zone],
		Capacity_tonne_per_yr = capcapture[:],
	)


	total = DataFrame(
			Resource = "Total", Zone = "n/a",
			Capacity_tonne_per_yr = sum(dfCap[!,:Capacity_tonne_per_yr]),
		)

	dfCap = vcat(dfCap, total)
	CSV.write(string(path,sep,"CSC_storage_capacity.csv"), dfCap)
	
	return dfCap
end

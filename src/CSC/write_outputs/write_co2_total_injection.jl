

@doc raw"""
	write_co2_total_injection(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting CO2 storage injection.
"""
function write_co2_total_injection(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

	dfCO2Storage = inputs["dfCO2Storage"]
	capcapture = zeros(size(inputs["CO2_STORAGE_NAME"]))

	for i in 1:inputs["CO2_STOR_ALL"]
		if setup["ParameterScale"]==1
			capcapture[i] = value(EP[:eCO2_Injected_per_year][i])*ModelScalingFactor
		else
			capcapture[i] = value(EP[:eCO2_Injected_per_year][i])
		end
	end

	dfCap = DataFrame(
		Resource = inputs["CO2_STORAGE_NAME"], Zone = dfCO2Storage[!,:Zone],
		Injection_tonne_per_yr = capcapture[:],
	)


	total = DataFrame(
			Resource = "Total", Zone = "n/a",
			Injection_tonne_per_yr = sum(dfCap[!,:Injection_tonne_per_yr]),
		)

	dfCap = vcat(dfCap, total)
	CSV.write(string(path,sep,"CSC_injection_per_year.csv"), dfCap)

	return dfCap
end

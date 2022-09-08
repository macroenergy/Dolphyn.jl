"""
CAPTUREX: An Configurable Capacity Expansion Model
Copyright (C) 2021,  Massachusetts Institute of Technology
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU CAPTUREeral Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU CAPTUREeral Public License for more details.
A complete copy of the GNU CAPTUREeral Public License v2 (GPLv2) is available
in LICENSE.txt.  Users uncompressing this from an archive may not have
received this license file.  If not, see <http://www.gnu.org/licenses/>.
"""

@doc raw"""
	write_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for writing the diferent capacities for the different capture technologies (starting capacities or, existing capacities, retired capacities, and new-built capacities).
"""
function write_co2_storage_injection_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	# Capacity decisions
	dfCO2Storage = inputs["dfCO2Storage"]
	capcapture = zeros(size(inputs["CO2_STORAGE_NAME"]))

	for i in 1:inputs["CO2_STOR_ALL"]
		if setup["ParameterScale"]==1
			capcapture[i] = value(EP[:vCapacity_CO2_Injection_per_type][i])*ModelScalingFactor
		else
			capcapture[i] = value(EP[:vCapacity_CO2_Injection_per_type][i])
		end
	end

	dfCap = DataFrame(
		Resource = inputs["CO2_STORAGE_NAME"], Zone = dfCO2Storage[!,:Zone],
		Capacity = capcapture[:],
	)


	total = DataFrame(
			Resource = "Total", Zone = "n/a",
			Capacity = sum(dfCap[!,:Capacity]),
		)

	dfCap = vcat(dfCap, total)
	CSV.write(string(path,sep,"CSC_co2_storage_injection_capacity.csv"), dfCap)
	return dfCap
end

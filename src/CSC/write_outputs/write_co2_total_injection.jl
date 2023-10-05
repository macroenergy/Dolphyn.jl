"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
Copyright (C) 2022,  Massachusetts Institute of Technology
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt.  Users uncompressing this from an archive may not have
received this license file.  If not, see <http://www.gnu.org/licenses/>.
"""

@doc raw"""
	write_co2_storage_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for writing the diferent capacities for CO2 storage
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
		Resource = inputs["CO2_STORAGE_NAME"], Site = dfCO2Storage[!,:Site],
		Capacity_tonne_per_yr = capcapture[:],
	)


	total = DataFrame(
			Resource = "Total", Site = "n/a",
			Capacity_tonne_per_yr = sum(dfCap[!,:Capacity_tonne_per_yr]),
		)

	dfCap = vcat(dfCap, total)
	CSV.write(string(path,sep,"CSC_injection_per_year.csv"), dfCap)

	return dfCap
end

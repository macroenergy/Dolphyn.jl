"""
GenX: An Configurable Capacity Expansion Model
Copyright (C) 2021,  Massachusetts Institute of Technology
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
	write_co2_capacity(EP::Model, path::AbstractString, inputs::Dict, setup::Dict)

Function for writing the diferent capacities for the different generation technologies (starting capacities or, existing capacities, retired capacities, and new-built capacities).
"""
function write_co2_storage_capacity(EP::Model, path::AbstractString, inputs::Dict, setup::Dict)
	# Capacity decisions
	dfCO2Stor = inputs["dfCO2Stor"]

	capcharge = zeros(size(inputs["CO2_STORAGE_NAME"]))

	for i in inputs["CO2_STOR_ALL"]
		capcharge[i] = value(EP[:vCO2CAPCHARGE][i])
	end

	capcarbon = zeros(size(inputs["CO2_STORAGE_NAME"]))

	for i in inputs["CO2_STOR_ALL"]
		capcarbon[i] = value(EP[:vCO2CAPCARBON][i])
	end

	dfStorageCap = DataFrame(
		Storage = inputs["CO2_STORAGE_NAME"], Zone = dfCO2Stor[!,:Zone],
		NewCarbonCap = capcarbon[:],
		NewChargeCap = capcharge[:],
	)

	total = DataFrame(
			Storage = "Total", Zone = "n/a",
			NewCarbonCap = sum(dfStorageCap[!,:NewCarbonCap]), 
			NewChargeCap = sum(dfStorageCap[!,:NewChargeCap]), 
		)

	dfStorageCap = vcat(dfStorageCap, total)

	CSV.write(joinpath(path, "CSC_storage_capacity.csv"), dfStorageCap)
	
	return dfStorageCap
end

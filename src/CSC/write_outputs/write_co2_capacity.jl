"""
DOLPHYN: An Configurable Capacity Expansion Model
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
	write_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model))

Function for writing the diferent capacities for the different capture technologies (starting capacities or, existing capacities, retired capacities, and new-built capacities).
"""
function write_co2_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	# Capacity decisions
	dfCO2Capture = inputs["dfCO2Capture"]
	capdischarge = zeros(size(inputs["CO2_RESOURCES_NAME"]))
	for i in inputs["CO2_CAPTURE_NEW_CAP"]
		if i in inputs["CO2_CAPTURE_COMMIT"]
			capdischarge[i] = value(EP[:vCO2CaptureNewCap][i]) * dfCO2Capture[!,:Cap_Size_tonne_p_hr][i]
		else
			capdischarge[i] = value(EP[:vCO2CaptureNewCap][i])
		end
	end

	dfCap = DataFrame(
		Resource = inputs["CO2_RESOURCES_NAME"], Zone = dfCO2Capture[!,:Zone],
		StartCap = dfCO2Capture[!,:Existing_Cap_tonne_p_hr],
		NewCap = capdischarge[:],
		EndCap = value.(EP[:eCO2CaptureTotalCap]),
	)

	total = DataFrame(
		Resource = "Total", Zone = "n/a",
		StartCap = sum(dfCap[!,:StartCap]),
		NewCap = sum(dfCap[!,:NewCap]),
		EndCap = sum(dfCap[!,:EndCap]),
	)

	dfCap = vcat(dfCap, total)

	CSV.write(string(path,sep,"CSC_capture_capacity.csv"), dfCap)
	
	return dfCap
end

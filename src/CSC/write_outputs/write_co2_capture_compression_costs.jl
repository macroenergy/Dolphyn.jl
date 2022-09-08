"""
DOLPHYN: Decision Optimization for Low-carbon for Power and Hydrogen Networks
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
	write_co2_capture_costs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for writing the diferent capacities for the different capture technologies (starting capacities or, existing capacities, retired capacities, and new-built capacities).
"""
function write_co2_capture_compression_costs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	## Cost results
	dfCO2CaptureComp = inputs["dfCO2CaptureComp"]
	Z = inputs["Z"]     # Number of zones
	T = inputs["T"]     # Number of time steps (hours)

	dfCO2CaptureCompCost = DataFrame(Costs = ["cCO2CaptureCompTotal"])
	if setup["ParameterScale"]==1 # Convert costs in millions to $
		cCO2CaptureCompTotal = value(EP[:eFixed_Cost_CO2_Capture_Comp_total]) * ModelScalingFactor^2
	else
		cCO2CaptureCompTotal = value(EP[:eFixed_Cost_CO2_Capture_Comp_total])
	end

    dfCO2CaptureCompCost[!,Symbol("Total")] = [cCO2CaptureCompTotal]


	CSV.write(string(path,sep,"CSC_co2_capture_compression_total_cost.csv"), dfCO2CaptureCompCost)

	
	# Capacity decisions
	CAPEX = zeros(size(inputs["CO2_CAPTURE_COMP_NAME"]))
	FixedOM = zeros(size(inputs["CO2_CAPTURE_COMP_NAME"]))
	TotalCost = zeros(size(inputs["CO2_CAPTURE_COMP_NAME"]))

	for i in 1:inputs["CO2_CAPTURE_COMP_ALL"]
		if setup["ParameterScale"]==1 # Convert costs in millions to $
			CAPEX[i] = value(EP[:eCAPEX_CO2_Capture_Comp_per_type][i]) * ModelScalingFactor^2
			FixedOM[i] = value(EP[:eFixed_OM_CO2_Capture_Comp_per_type][i]) * ModelScalingFactor^2
		else
			CAPEX[i] = value(EP[:eCAPEX_CO2_Capture_Comp_per_type][i])
			FixedOM[i] = value(EP[:eFixed_OM_CO2_Capture_Comp_per_type][i])
		end
		TotalCost[i] = CAPEX[i] + FixedOM[i]
	end
	


	dfCost_Capture_Compression = DataFrame(
		Resource = inputs["CO2_CAPTURE_COMP_NAME"], 
		Zone = dfCO2CaptureComp[!,:Zone],
		Investment_Cost = CAPEX[:],
		Fixed_OM_Cost = FixedOM[:],
		Total_Cost = TotalCost[:],
	)

	dfCost_Capture_Compression = vcat(dfCost_Capture_Compression)
	CSV.write(string(path,sep,"CSC_co2_capture_compression_cost.csv"), dfCost_Capture_Compression)

end

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
function write_co2_storage_injection_costs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	## Cost results
	dfCO2Storage = inputs["dfCO2Storage"]
	Z = inputs["Z"]     # Number of zones
	T = inputs["T"]     # Number of time steps (hours)

	dfCO2InjectionCost = DataFrame(Costs = ["cCO2InjectionTotal"])
	if setup["ParameterScale"]==1 # Convert costs in millions to $
		cCO2InjectionTotal = value(EP[:eFixed_Cost_CO2_Injection_total]) * ModelScalingFactor^2
	else
		cCO2InjectionTotal = value(EP[:eFixed_Cost_CO2_Injection_total])
	end

    dfCO2InjectionCost[!,Symbol("Total")] = [cCO2InjectionTotal]


	CSV.write(string(path,sep,"CSC_co2_storage_injection_total_cost.csv"), dfCO2InjectionCost)

	
	# Capacity decisions
	CAPEX = zeros(size(inputs["CO2_STORAGE_NAME"]))
	FixedOM = zeros(size(inputs["CO2_STORAGE_NAME"]))
	TotalCost = zeros(size(inputs["CO2_STORAGE_NAME"]))

	for i in 1:inputs["CO2_STOR_ALL"]
		CAPEX[i] = value(EP[:eCAPEX_CO2_Injection_per_type][i])
		FixedOM[i] = value(EP[:eFixed_OM_CO2_Injection_per_type][i])
		TotalCost[i] = CAPEX[i] + FixedOM[i]
	end
	


	dfCost_Injection = DataFrame(
		Resource = inputs["CO2_STORAGE_NAME"], 
		Zone = dfCO2Storage[!,:Zone],
		Investment_Cost = CAPEX[:],
		Fixed_OM_Cost = FixedOM[:],
		Total_Cost = TotalCost[:],
	)

	dfCost_Injection = vcat(dfCost_Injection)
	CSV.write(string(path,sep,"CSC_co2_storage_injection_cost.csv"), dfCost_Injection)

end

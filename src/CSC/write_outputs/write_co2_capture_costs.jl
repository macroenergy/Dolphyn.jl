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
function write_co2_capture_costs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	## Cost results
	dfCO2Capture = inputs["dfCO2Capture"]
	Z = inputs["Z"]     # Number of zones
	T = inputs["T"]     # Number of time steps (hours)
	CO2_CAPTURE_SOLID = inputs["CO2_CAPTURE_SOLID"] # Solid DAC with unit commitment

	cDACStart = 0

	dfDACCost = DataFrame(Costs = ["cDACTotal", "cDACFix", "cDACVar", "cDACStart"])
	if setup["ParameterScale"]==1 # Convert costs in millions to $
		cDACVar = value(EP[:eVar_OM_DAC]) * ModelScalingFactor^2
		cDACFix = value(EP[:eFixed_Cost_DAC_total]) * ModelScalingFactor^2
	else
		cDACVar = value(EP[:eVar_OM_DAC])
		cDACFix = value(EP[:eFixed_Cost_DAC_total])
	end


	if !isempty(inputs["CO2_CAPTURE_SOLID"])
		if setup["ParameterScale"]==1 # Convert costs in millions to $
			cDACStart += value(EP[:eTotal_Startup_Cost_DAC])*ModelScalingFactor^2
		else
	    	cDACStart += value(EP[:eTotal_Startup_Cost_DAC])
		end
	end

	 
    cDACTotal = cDACVar + cDACFix + cDACStart 

    dfDACCost[!,Symbol("Total")] = [cDACTotal, cDACFix, cDACVar, cDACStart]


	CSV.write(string(path,sep,"CSC_DAC_costs.csv"), dfDACCost)

	
	# Capacity decisions
	CAPEX = zeros(size(inputs["CO2_RESOURCES_NAME"]))
	FixedOM = zeros(size(inputs["CO2_RESOURCES_NAME"]))
	VarOM = zeros(size(inputs["CO2_RESOURCES_NAME"]))
	Startup = zeros(size(inputs["CO2_RESOURCES_NAME"]))

	for i in 1:inputs["CO2_RES_ALL"]
		CAPEX[i] = value(EP[:eCAPEX_DAC_per_type][i])
		FixedOM[i] = value(EP[:eFixed_OM_DAC_per_type][i])
		VarOM[i] = value(EP[:eVar_OM_DAC_per_type_per_time][i])
		Startup[i] = 0
		if i in CO2_CAPTURE_SOLID
			Startup[i] = value(EP[:eTotal_Startup_Cost_DAC_per_type][i])
		end
	end
	


	dfCost_Plant = DataFrame(
		Resource = inputs["CO2_RESOURCES_NAME"], 
		Zone = dfCO2Capture[!,:Zone],
		Investment_Cost = CAPEX[:],
		Fixed_OM_Cost = FixedOM[:],
		Var_OM_Cost = VarOM[:],
		Startup_Cost = Startup[:],
	)

	dfCost_Plant = vcat(dfCost_Plant)
	CSV.write(string(path,sep,"CSC_Plant_Cost.csv"), dfCost_Plant)

end

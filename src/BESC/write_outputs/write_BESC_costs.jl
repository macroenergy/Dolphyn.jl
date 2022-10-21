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
	write_BESC_costs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for writing the cost for the different sectors of the bioenergy supply chain (Biorefineries, herbaceous and woody resources).
"""
function write_BESC_costs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	## Cost results
	dfbiorefinery = inputs["dfbiorefinery"]
	Z = inputs["Z"]     # Number of zones
	T = inputs["T"]     # Number of time steps (hours)
	
	dfCost = DataFrame(Costs = ["cTotal", "cBiorefineryFix", "cBiorefineryVar", "cHerb", "cWood"])
	if setup["ParameterScale"] == 1
		cBiorefineryVar = value(EP[:eVar_Cost_BIO]) * ModelScalingFactor^2
		cBiorefineryFix = value(EP[:eFixed_Cost_BIO_total]) * ModelScalingFactor^2
		cHerb =  value(EP[:eHerb_biomass_supply_cost]) * ModelScalingFactor^2
		cWood = value(EP[:eWood_biomass_supply_cost]) * ModelScalingFactor^2
	else
		cBiorefineryVar = value(EP[:eVar_Cost_BIO])
		cBiorefineryFix = value(EP[:eFixed_Cost_BIO_total])
		cHerb = value(EP[:eHerb_biomass_supply_cost])
		cWood = value(EP[:eWood_biomass_supply_cost])
	end

	# Define total costs
	cTotal = cBiorefineryFix + cBiorefineryVar + cHerb + cWood

	# Define total column, i.e. column 2
	dfCost[!,Symbol("Total")] = [cTotal, cBiorefineryFix, cBiorefineryVar, cHerb, cWood]

	# Computing zonal cost breakdown by cost category
	for z in 1:Z
		tempCTotal = 0
		tempCBIOFix = 0
		tempCBIOVar = 0
		tempCBIOHerb = 0
		tempCBIOWood = 0

		for y in dfbiorefinery[dfbiorefinery[!,:Zone].==z,:][!,:R_ID]

			tempCBIOFix = tempCBIOFix + value.(EP[:eFixed_Cost_BIO_per_type])[y]
			tempCBIOVar = tempCBIOVar + sum(value.(EP[:eVar_Cost_BIO_per_plant])[y,:])

			tempCTotal = tempCTotal + value.(EP[:eFixed_Cost_BIO_per_type])[y] + sum(value.(EP[:eVar_Cost_BIO_per_plant])[y,:])
		end

		tempCBIOHerb = tempCBIOHerb + value.(EP[:eHerb_biomass_supply_cost_per_zone][z])
		tempCBIOWood = tempCBIOWood + value.(EP[:eWood_biomass_supply_cost_per_zone][z])
		tempCTotal = tempCTotal + value.(EP[:eHerb_biomass_supply_cost_per_zone][z]) + value.(EP[:eWood_biomass_supply_cost_per_zone][z])


		if setup["ParameterScale"] == 1
			tempCTotal = tempCTotal * (ModelScalingFactor^2)
			tempCBIOFix = tempCBIOFix * (ModelScalingFactor^2)
			tempCBIOVar = tempCBIOVar * (ModelScalingFactor^2)
			tempCBIOHerb = tempCBIOHerb * (ModelScalingFactor^2)
			tempCBIOWood = tempCBIOWood * (ModelScalingFactor^2)
		end

		dfCost[!,Symbol("Zone$z")] = [tempCTotal, tempCBIOFix, tempCBIOVar, tempCBIOHerb, tempCBIOWood]
	end

	CSV.write(string(path,sep,"BESC_costs.csv"), dfCost)

end

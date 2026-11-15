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
	ethane_production_constraint(EP::Model, inputs::Dict, setup::Dict)

This function establishes constraints that can be flexibily applied to define alternative forms of policies that require generation of a quantity of conventional ng in the entire system across the entire year

	"""
function ethane_production_constraint(EP::Model, inputs::Dict, setup::Dict)
	println(" -- Conventional NG and Ethane production Policies Module")
	
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	
	
    
	### NG
	if setup["Model_Ethane_production_constraint"] == 1

		## Conventional Ethylene Purchase Share Requirements
		@expression(EP, eAnnualEthaneRequired, sum(sum(inputs["omega"][t] * EP[:vConv_Ethane_Demand][t,z] for z = 1:Z) for t = 1:T) + sum(sum(inputs["omega"][t] * EP[:eEthylene_Ethane_RES][t,z] for z = 1:Z) for t = 1:T) + sum(sum(inputs["omega"][t] * EP[:eEthylene_Ethane_Plant][t,z] for z = 1:Z) for t = 1:T))

		@expression(EP, eAnnualNGProduced, sum(sum(inputs["omega"][t] * EP[:vConv_NG_Demand][t,z] for z = 1:Z) for t = 1:T))
		
		@constraint(EP, cConvEthaneNG_max, EP[:eAnnualEthaneRequired]*NG_MMBtu_to_ethane_tonne_min <= EP[:eAnnualNGProduced])

		# @constraint(EP, cConvEthaneNG_min, EP[:eAnnualNGProduced] <= EP[:eAnnualEthaneRequired]*NG_MMBtu_to_ethane_tonne_max)

	end

	return EP
end

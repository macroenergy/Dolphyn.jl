"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
Copyright (C) 2021, Massachusetts Institute of Technology and Peking University
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt. Users uncompressing this from an archive may not have
received this license file. If not, see <http://www.gnu.org/licenses/>.
"""

@doc raw"""
	co2_cap_power_csc(EP::Model, inputs::Dict, setup::Dict)

This policy constraints mimics the CO$_2$ emissions cap and permit trading systems, allowing for emissions trading across each zone for which the cap applies. The constraint $p \in \mathcal{P}^{CO_2}$ can be flexibly defined for mass-based or rate-based emission limits for one or more model zones, where zones can trade CO$_2$ emissions permits and earn revenue based on their CO$_2$ allowance. Note that if the model is fully linear (e.g. no unit commitment or linearized unit commitment), the dual variable of the emissions constraints can be interpreted as the marginal CO$_2$ price per tonne associated with the emissions target. Alternatively, for integer model formulations, the marginal CO$_2$ price can be obtained after solving the model with fixed integer/binary variables.

The CO$_2$ emissions limit can be defined in one of the following ways: a) a mass-based limit defined in terms of annual CO$_2$ emissions budget (in million tonnes of CO2), b) a load-side rate-based limit defined in terms of tonnes CO$_2$ per MWh of demand and c) a generation-side rate-based limit defined in terms of tonnes CO$_2$ per MWh of generation.

"""
function co2_cap_power_csc(EP::Model, inputs::Dict, setup::Dict)

	println("C02 Policies Module for power and carbon system combined")


	SEG = inputs["SEG"]  # Number of non-served energy segments for power demand
	G = inputs["G"]     # Number of resources (generators, storage, DR, and DERs)
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	if setup["SystemCO2Constraint"] ==1 # Independent constraints for Power and HSC
		# CO2 constraint for power system imposed separately
		EP = co2_cap_power(EP, inputs, setup)
		# No CSC constraint for emissions as it is capturing co2

	elseif setup["SystemCO2Constraint"] ==2 # Joint emissions constraint for power and HSC and CSC sector
		# In this case, we impose a single emissions constraint across both sectors
		# Constraint type to be imposed is read from genx_settings.yml

		## Mass-based: Emissions constraint in absolute emissions limit (tons)
		if setup["CO2Cap"] == 1
			@constraint(EP, cCO2Emissions_systemwide[cap=1:inputs["NCO2Cap"]],
				sum(inputs["omega"][t] * EP[:eEmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T) -
				sum(inputs["omega"][t] * EP[:eCO2NegativeEmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
				<=
				sum(inputs["dfMaxCO2"][z,cap] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]))
			)

		## Load + Rate-based: Emissions constraint in terms of rate (tons/MWh)
		# Emissions from power - Negative Emissions from CSC < =
		# Emissions intensity * (Power demand served + storage losses) +
		# Carbon capture not considered in the RHS as the purpose of carbon capture is to offset the emissions of power

		elseif setup["CO2Cap"] == 2
			@constraint(EP, cCO2Emissions_systemwide[cap=1:inputs["NCO2Cap"]],
				sum(inputs["omega"][t] * EP[:eEmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T) -
				sum(inputs["omega"][t] * EP[:eCO2NegativeEmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
				<=
				sum(inputs["dfMaxCO2Rate"][z,cap] * sum(inputs["omega"][t] * (inputs["pD"][t,z] - sum(EP[:vNSE][s,t,z] for s in 1:SEG)) for t=1:T) for z = findall(x->x==1, inputs["dfCO2CapZones"][:,cap])) +
				sum(inputs["dfMaxCO2Rate"][z,cap] * setup["StorageLosses"] *  EP[:eELOSSByZone][z] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]))
			)


		## Generation + Rate-based: Emissions constraint in terms of rate (tons/MWh)
		# Emissions from power - Negative Emissions from CSC < =
		# Emissions intensity * (Power Generation) +

		elseif (setup["CO2Cap"]==3)
			@constraint(EP, cCO2Emissions_systemwide[cap=1:inputs["NCO2Cap"]],
				sum(inputs["omega"][t] * EP[:eEmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T) -
				sum(inputs["omega"][t] * EP[:eCO2NegativeEmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
					<=
				sum(inputs["dfMaxCO2Rate"][z,cap] * inputs["omega"][t] * EP[:eGenerationByZone][z,t] for t=1:T, z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]))
			)

		end



	end


	return EP

end

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
	co2_cap_power_hsc(EP::Model, inputs::Dict, setup::Dict)

This policy constraints mimics the CO$_2$ emissions cap and permit trading systems, allowing for emissions trading across each zone for which the cap applies. The constraint $p \in \mathcal{P}^{CO_2}$ can be flexibly defined for mass-based or rate-based emission limits for one or more model zones, where zones can trade CO$_2$ emissions permits and earn revenue based on their CO$_2$ allowance. Note that if the model is fully linear (e.g. no unit commitment or linearized unit commitment), the dual variable of the emissions constraints can be interpreted as the marginal CO$_2$ price per tonne associated with the emissions target. Alternatively, for integer model formulations, the marginal CO$_2$ price can be obtained after solving the model with fixed integer/binary variables.

The CO$_2$ emissions limit can be defined in one of the following ways: a) a mass-based limit defined in terms of annual CO$_2$ emissions budget (in million tonnes of CO2), b) a load-side rate-based limit defined in terms of tonnes CO$_2$ per MWh of demand and c) a generation-side rate-based limit defined in terms of tonnes CO$_2$ per MWh of generation.

"""
function co2_cap_power_hsc(EP::Model, inputs::Dict, setup::Dict)

	println("C02 Policies Module for power and hydrogen system combined")


	SEG = inputs["SEG"]  # Number of non-served energy segments for power demand
	H2_SEG = inputs["H2_SEG"]  # Number of non-served energy segments for H2 demand
	G = inputs["G"]     # Number of resources (generators, storage, DR, and DERs)
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	if setup["SystemCO2Constraint"] ==1 # Independent constraints for Power and HSC
		# CO2 constraint for power system imposed separately
		EP = co2_cap_power(EP, inputs, setup)
		# HSC constraint for power system imposed separately
		EP = co2_cap_hsc(EP,inputs,setup)

	elseif setup["SystemCO2Constraint"] ==2 # Joint emissions constraint for power and HSC sector
		# In this case, we impose a single emissions constraint across both sectors
		# Constraint type to be imposed is read from genx_settings.yml
		# NOTE: constraint type denoted by setup parameter H2CO2Cap ignored


		## Mass-based: Emissions constraint in absolute emissions limit (tons)
		if setup["CO2Cap"] == 1
			@constraint(EP, cCO2Emissions_systemwide[cap=1:inputs["NCO2Cap"]],
				sum(inputs["omega"][t] * EP[:eEmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)+
				sum(inputs["omega"][t] * EP[:eH2EmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T) <=
				sum(inputs["dfMaxCO2"][z,cap] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]))
			)

		## Load + Rate-based: Emissions constraint in terms of rate (tons/MWh)
		# Emissions from power + Emissions from HSC < =
		# Emissions intensity * (Power demand served + storage losses) +
		# Emissions intensity * H2 LHV * (H2 demand served)
		### Emissions intensity adjusted from tonnes/MWh to tonnes/ Tonne H2 using H2_LHV
		elseif setup["CO2Cap"] == 2
			if setup["ParameterScale"] ==1 # MaxCO2Rate is kton/MWH, so need to adjust H2 demand to be in ktonne as well  on RHS of constraint if ParameterScale=1
				@constraint(EP, cCO2Emissions_systemwide[cap=1:inputs["NCO2Cap"]],
					sum(inputs["omega"][t] * EP[:eEmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T) +
					sum(inputs["omega"][t] * EP[:eH2EmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T) <=
					sum(inputs["dfMaxCO2Rate"][z,cap] * sum(inputs["omega"][t] * (inputs["pD"][z,t] - sum(EP[:vNSE][s,z,t] for s in 1:SEG)) for t=1:T) for z = findall(x->x==1, inputs["dfCO2CapZones"][:,cap])) +
					sum(inputs["dfMaxCO2Rate"][z,cap] * setup["StorageLosses"] *  EP[:eELOSSByZone][z] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap])) +
					sum(inputs["dfMaxCO2Rate"][z,cap] * H2_LHV/ModelScalingFactor * sum(inputs["omega"][t] * (inputs["H2_D"][z,t] + EP[:eH2DemandByZoneG2P][z,t] - sum(EP[:vH2NSE][s,z,t] for s in 1:H2_SEG)) for t=1:T) for z = findall(x->x==1, inputs["dfCO2CapZones"][:,cap]))
				)

			else
				@constraint(EP, cCO2Emissions_systemwide[cap=1:inputs["NCO2Cap"]],
				sum(inputs["omega"][t] * EP[:eEmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T) +
				sum(inputs["omega"][t] * EP[:eH2EmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T) <=
				sum(inputs["dfMaxCO2Rate"][z,cap] * sum(inputs["omega"][t] * (inputs["pD"][z,t] - sum(EP[:vNSE][s,z,t] for s in 1:SEG)) for t=1:T) for z = findall(x->x==1, inputs["dfCO2CapZones"][:,cap])) +
				sum(inputs["dfMaxCO2Rate"][z,cap] * setup["StorageLosses"] *  EP[:eELOSSByZone][z] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap])) +
				sum(inputs["dfMaxCO2Rate"][z,cap] * H2_LHV * sum(inputs["omega"][t] * (inputs["H2_D"][z,t] + EP[:eH2DemandByZoneG2P][z,t] - sum(EP[:vH2NSE][s,z,t] for s in 1:H2_SEG)) for t=1:T) for z = findall(x->x==1, inputs["dfCO2CapZones"][:,cap]))
			)

			end


		## Generation + Rate-based: Emissions constraint in terms of rate (tons/MWh)
		### Emissions intensity adjusted from tonnes/MWh to tonnes/ Tonne H2 using H2_LHV
		# Emissions from power + Emissions from HSC < =
		# Emissions intensity * (Power Generation) +
		# Emissions intensity * H2 LHV * (H2 generation)

		elseif (setup["CO2Cap"]==3)
			if setup["ParameterScale"]==1 # MaxCO2Rate is kton/GWH, so need to adjust H2 demand to be in ktonne as well  on RHS of constraint if ParameterScale=1
				@constraint(EP, cCO2Emissions_systemwide[cap=1:inputs["NCO2Cap"]],
					sum(inputs["omega"][t] * EP[:eEmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T) +
					sum(inputs["omega"][t] * EP[:eH2EmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T) <=
					sum(inputs["dfMaxCO2Rate"][z,cap] * inputs["omega"][t] * EP[:eGenerationByZone][t,z] for t=1:T, z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]))+
					sum(inputs["dfMaxCO2Rate"][z,cap] *H2_LHV/ModelScalingFactor *inputs["omega"][t] * EP[:eH2GenerationByZone][z,t] for t=1:T, z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]))
				)
			else
				@constraint(EP, cCO2Emissions_systemwide[cap=1:inputs["NCO2Cap"]],
					sum(inputs["omega"][t] * EP[:eEmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T) +
					sum(inputs["omega"][t] * EP[:eH2EmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T) <=
					sum(inputs["dfMaxCO2Rate"][z,cap] * inputs["omega"][t] * EP[:eGenerationByZone][t,z] for t=1:T, z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]))+
					sum(inputs["dfMaxCO2Rate"][z,cap] *H2_LHV *inputs["omega"][t] * EP[:eH2GenerationByZone][z,t] for t=1:T, z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]))
				)
			end

		end



	end


	return EP

end

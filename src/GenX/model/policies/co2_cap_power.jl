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
	co2_cap_power(EP::Model, inputs::Dict, setup::Dict)

This policy constraints mimics the $CO_2$ emissions cap and permit trading systems, allowing for emissions trading across each zone for which the cap applies. 
The constraint $p \in \mathcal{P}^{CO_2}$ can be flexibly defined for mass-based or rate-based emission limits for one or more model zones, where zones can trade $CO_2$ emissions permits and earn revenue based on their $CO_2$ allowance. 
Note that if the model is fully linear (e.g. no unit commitment or linearized unit commitment), the dual variable of the emissions constraints can be interpreted as the marginal $CO_2$ price per tonne associated with the emissions target. 
Alternatively, for integer model formulations, the marginal $CO_2$ price can be obtained after solving the model with fixed integer/binary variables.

The $CO_2$ emissions limit can be defined in one of the following ways: 
a) a mass-based limit defined in terms of annual $CO_2$ emissions budget (in million tonnes of CO2), 
b) a load-side rate-based limit defined in terms of tonnes $CO_2$ per MWh of demand and 
c) a generation-side rate-based limit defined in terms of tonnes $CO_2$ per MWh of generation.

**Mass-based emissions constraint**

Mass-based emission limits are implemented in the following expression. For each constraint, $p \in \mathcal{P}_{mass}^{CO_2}$, we define a set of zones $z \in \mathcal{Z}_{p,mass}^{CO_2}$ that can trade $CO_2$ allowance. 
Input data for each constraint $p \in \mathcal{P}_{mass}^{CO_2}$ requires the $CO_2$ allowance budget for each model zone, $\epsilon_{z,p,mass}^{CO_2}$, to be provided in terms of million metric tonnes. 
For every generator $g$, the parameter $\epsilon_{g,z}^{CO_2}$ reflects the specific $CO_2$ emission intensity in t$CO_2$/MWh associated with its operation. 
The resulting constraint is given as:

```math
\begin{equation*}
    \sum_{z \in \mathcal{Z}_{p,mass}^{CO_2}} \sum_{g \in \mathcal{G}} \sum_{t \in \mathcal{T}} \left(\epsilon_{g,z}^{CO_2} \times \omega_t \times x_{g,z,t}^{\textrm{E,GEN}}\right) \leq \sum_{z \in \mathcal{Z}_{p,mass}^{CO_2}} \epsilon_{z,p,mass}^{CO_{2}} \forall p \in \mathcal{P}_{mass}^{CO_2}
\end{equation*}
```

In the above constraint, we include both power discharge and charge term for each resource to account for the potential for $CO_2$ emissions (or removal when considering negative emissions technologies) associated with each step. Note that if a limit is applied to each zone separately, then the set $\mathcal{Z}_{p,mass}^{CO_2}$ will contain only one zone with no possibility of trading. 
If a system-wide emission limit constraint is applied, then $\mathcal{Z}_{p,mass}^{CO_2}$ will be equivalent to a set of all zones.

**Load-side rate-based emissions constraint**

We modify the right hand side of the above mass-based constraint, $p \in \mathcal{P}_{load}^{CO_2}$, to set emissions target based on a $CO_2$ emission rate limit in t$CO_2$/MWh $\times$ the total demand served in each zone. 
In the following constraint, total demand served takes into account non-served energy and storage related losses. Here, $overline{\epsilon_{z,p,load}^{CO_2}}$ denotes the emission limit in terms on t$CO_2$/MWh.

```math
\begin{equation*}
    \sum_{z \in \mathcal{Z}_{p,load}^{CO_2}} \sum_{g \in \mathcal{G}} \sum_{t \in \mathcal{T}} \left(\epsilon_{g,z}^{CO_2} \times \omega_t \times x_{g,z,t}^{\textrm{E,GEN}} \right) \leq \sum_{z \in \mathcal{Z}_{p,load}^{CO_2}} \sum_{t \in \mathcal{T}}  \left(\epsilon_{z,p,load}^{CO_2} \times \omega_t \times D_{z,t}\right) + \sum_{z \in \mathcal{Z}_{p,load}^{CO_2}} \sum_{o \in \mathcal{O}} \sum_{t \in \mathcal{T}} \left(\epsilon_{z,p,load}^{CO_2} \times \omega_t \times \left(x_{s,z,t}^{E,CHA} - x_{s,z,t}^{\textrm{E,DIS}}\right)\right) - \sum_{z \in \mathcal{Z}_{p,load}^{CO_2}} \sum_{s \in \mathcal{SEG}} \sum_{t \in \mathcal{T}} \left(\epsilon_{z,p,load}^{CO_2} \times \omega_t \times x_{s,z,t}^{\textrm{E,NSD}}\right) \forall p \in \mathcal{P}_{load}^{CO_2}
\end{equation*}
```

**Generator-side emissions rate-based constraint**

Similarly, a generation based emission constraint is defined by setting the emission limit based on the total generation times the carbon emission rate limit in t$CO_2$/MWh of the region. The resulting constraint is given as:

```math
\begin{equation*}
	\sum_{z \in \mathcal{Z}_{p,gen}^{CO_2}} \sum_{g \in \mathcal{G}} \sum_{t \in \mathcal{T}} \left(\epsilon_{g,z}^{CO_2} \times \omega_t \times x_{g,z,t}^{\textrm{E,GEN}} \right) \leq \sum_{z \in \mathcal{Z}_{p,gen}^{CO_2}} \sum_{g \in \mathcal{G}} \sum_{t \in \mathcal{T}} \left(\epsilon_{z,p,gen}^{CO_2} \times \omega_t \times x_{g,z,t} \right) \forall p \in \mathcal{P}_{gen}^{CO_2}
\end{equation*}
```

Note that the generator-side rate-based constraint can be used to represent a fee-rebate (``feebate'') system: the dirty generators that emit above the bar ($\overline{\epsilon_{z,p,gen}^{CO_2}}$) have to buy emission allowances from the emission regulator in the region $z$ where they are located; in the same vein, the clean generators get rebates from the emission regulator at an emission allowance price being the dual variable of the emissions rate constraint.
"""
function co2_cap_power(EP::Model, inputs::Dict, setup::Dict)

	print_and_log("C02 Policies Module")

	dfGen = inputs["dfGen"]
	SEG = inputs["SEG"]  # Number of lines
	G = inputs["G"]     # Number of resources (generators, storage, DR, and DERs)
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	### Constraints ###
	if setup["ModelCO2"] == 1 #Include Carbon supply chain captured carbon from DAC and emissions

		if setup["ModelBIO"] == 1 #Include Bioenergy supply chain captured carbon and emissions

			## Mass-based: Emissions constraint in absolute emissions limit (tons)
			if setup["CO2Cap"] == 1
				@constraint(EP, cCO2Emissions_systemwide[cap=1:inputs["NCO2Cap"]],
					sum(inputs["omega"][t] * EP[:eEmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
					+ sum(inputs["omega"][t] * EP[:eCSC_Emissions_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
					+ sum(inputs["omega"][t] * EP[:eBiorefinery_CO2_emissions_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
					+ sum(inputs["omega"][t] * EP[:eHerb_biomass_emission_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
					+ sum(inputs["omega"][t] * EP[:eWood_biomass_emission_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
					- sum(inputs["omega"][t] * EP[:eDAC_CO2_Captured_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
					- sum(inputs["omega"][t] * EP[:eBIO_CO2_captured_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T) <=
					sum(inputs["dfMaxCO2"][z,cap] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]))
				)

			## Load + Rate-based: Emissions constraint in terms of rate (tons/MWh)
			elseif setup["CO2Cap"] == 2 
				if setup["ModelH2"] == 0
					@constraint(EP, cCO2Emissions_systemwide[cap=1:inputs["NCO2Cap"]],
						sum(inputs["omega"][t] * EP[:eEmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
						+ sum(inputs["omega"][t] * EP[:eCSC_Emissions_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
						+ sum(inputs["omega"][t] * EP[:eBiorefinery_CO2_emissions_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
						+ sum(inputs["omega"][t] * EP[:eHerb_biomass_emission_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
						+ sum(inputs["omega"][t] * EP[:eWood_biomass_emission_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
						- sum(inputs["omega"][t] * EP[:eDAC_CO2_Captured_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
						- sum(inputs["omega"][t] * EP[:eBIO_CO2_captured_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)  <=
						sum(inputs["dfMaxCO2Rate"][z,cap] * sum(inputs["omega"][t] * (inputs["pD"][t,z] + EP[:eCSCNetpowerConsumptionByAll][t,z] - sum(EP[:vNSE][s,t,z] for s in 1:SEG)) for t=1:T) for z = findall(x->x==1, inputs["dfCO2CapZones"][:,cap])) +
						sum(inputs["dfMaxCO2Rate"][z,cap] * setup["StorageLosses"] *  EP[:eELOSSByZone][z] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]))
					)
				elseif setup["ModelH2"] == 1 # Add NetPowerConsumption term to Demand side - could positive or negative
					@constraint(EP, cCO2Emissions_systemwide[cap=1:inputs["NCO2Cap"]],
						sum(inputs["omega"][t] * EP[:eEmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
						+ sum(inputs["omega"][t] * EP[:eCSC_Emissions_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
						+ sum(inputs["omega"][t] * EP[:eBiorefinery_CO2_emissions_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
						+ sum(inputs["omega"][t] * EP[:eHerb_biomass_emission_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
						+ sum(inputs["omega"][t] * EP[:eWood_biomass_emission_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
						- sum(inputs["omega"][t] * EP[:eDAC_CO2_Captured_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
						- sum(inputs["omega"][t] * EP[:eBIO_CO2_captured_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T) <=
						sum(inputs["dfMaxCO2Rate"][z,cap] * sum(inputs["omega"][t] * (inputs["pD"][t,z] + EP[:eH2NetpowerConsumptionByAll][t,z] + EP[:eCSCNetpowerConsumptionByAll][t,z] - sum(EP[:vNSE][s,t,z] for s in 1:SEG)) for t=1:T) for z = findall(x->x==1, inputs["dfCO2CapZones"][:,cap])) +
						sum(inputs["dfMaxCO2Rate"][z,cap] * setup["StorageLosses"] *  EP[:eELOSSByZone][z] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]))
					)
				end


			## Generation + Rate-based: Emissions constraint in terms of rate (tons/MWh)
			elseif (setup["CO2Cap"]==3)
				@constraint(EP, cCO2Emissions_systemwide[cap=1:inputs["NCO2Cap"]],
					sum(inputs["omega"][t] * EP[:eEmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
					+ sum(inputs["omega"][t] * EP[:eCSC_Emissions_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
					+ sum(inputs["omega"][t] * EP[:eBiorefinery_CO2_emissions_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
					+ sum(inputs["omega"][t] * EP[:eHerb_biomass_emission_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
					+ sum(inputs["omega"][t] * EP[:eWood_biomass_emission_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
					- sum(inputs["omega"][t] * EP[:eDAC_CO2_Captured_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
					- sum(inputs["omega"][t] * EP[:eBIO_CO2_captured_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T) <=
					sum(inputs["dfMaxCO2Rate"][z,cap] * inputs["omega"][t] * EP[:eGenerationByZone][z,t] for t=1:T, z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]))
				)
			end 

		elseif setup["ModelBIO"] == 0

			## Mass-based: Emissions constraint in absolute emissions limit (tons)
			if setup["CO2Cap"] == 1
				@constraint(EP, cCO2Emissions_systemwide[cap=1:inputs["NCO2Cap"]],
					sum(inputs["omega"][t] * EP[:eEmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
					+ sum(inputs["omega"][t] * EP[:eCSC_Emissions_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
					- sum(inputs["omega"][t] * EP[:eDAC_CO2_Captured_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T) <=
					sum(inputs["dfMaxCO2"][z,cap] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]))
				)

			## Load + Rate-based: Emissions constraint in terms of rate (tons/MWh)
			elseif setup["CO2Cap"] == 2 
				if setup["ModelH2"] == 0
					@constraint(EP, cCO2Emissions_systemwide[cap=1:inputs["NCO2Cap"]],
						sum(inputs["omega"][t] * EP[:eEmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
						+ sum(inputs["omega"][t] * EP[:eCSC_Emissions_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
						- sum(inputs["omega"][t] * EP[:eDAC_CO2_Captured_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T) <=
						sum(inputs["dfMaxCO2Rate"][z,cap] * sum(inputs["omega"][t] * (inputs["pD"][t,z] + EP[:eCSCNetpowerConsumptionByAll][t,z] - sum(EP[:vNSE][s,t,z] for s in 1:SEG)) for t=1:T) for z = findall(x->x==1, inputs["dfCO2CapZones"][:,cap])) +
						sum(inputs["dfMaxCO2Rate"][z,cap] * setup["StorageLosses"] *  EP[:eELOSSByZone][z] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]))
					)
				elseif setup["ModelH2"] == 1 # Add NetPowerConsumption term to Demand side - could positive or negative
					@constraint(EP, cCO2Emissions_systemwide[cap=1:inputs["NCO2Cap"]],
						sum(inputs["omega"][t] * EP[:eEmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
						+ sum(inputs["omega"][t] * EP[:eCSC_Emissions_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
						- sum(inputs["omega"][t] * EP[:eDAC_CO2_Captured_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T) <=
						sum(inputs["dfMaxCO2Rate"][z,cap] * sum(inputs["omega"][t] * (inputs["pD"][t,z] + EP[:eH2NetpowerConsumptionByAll][t,z] + EP[:eCSCNetpowerConsumptionByAll][t,z] - sum(EP[:vNSE][s,t,z] for s in 1:SEG)) for t=1:T) for z = findall(x->x==1, inputs["dfCO2CapZones"][:,cap])) +
						sum(inputs["dfMaxCO2Rate"][z,cap] * setup["StorageLosses"] *  EP[:eELOSSByZone][z] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]))
					)
				end


			## Generation + Rate-based: Emissions constraint in terms of rate (tons/MWh)
			elseif (setup["CO2Cap"]==3)
				@constraint(EP, cCO2Emissions_systemwide[cap=1:inputs["NCO2Cap"]],
					sum(inputs["omega"][t] * EP[:eEmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
					+ sum(inputs["omega"][t] * EP[:eCSC_Emissions_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
					- sum(inputs["omega"][t] * EP[:eDAC_CO2_Captured_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T) <=
					sum(inputs["dfMaxCO2Rate"][z,cap] * inputs["omega"][t] * EP[:eGenerationByZone][z,t] for t=1:T, z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]))
				)
			end 
		end

	elseif setup["ModelCO2"] == 0

		## Mass-based: Emissions constraint in absolute emissions limit (tons)
		if setup["CO2Cap"] == 1
			@constraint(EP, cCO2Emissions_systemwide[cap=1:inputs["NCO2Cap"]],
				sum(inputs["omega"][t] * EP[:eEmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T) <=
				sum(inputs["dfMaxCO2"][z,cap] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]))
			)

		## Load + Rate-based: Emissions constraint in terms of rate (tons/MWh)
		elseif setup["CO2Cap"] == 2 
			if setup["ModelH2"] == 0
				@constraint(EP, cCO2Emissions_systemwide[cap=1:inputs["NCO2Cap"]],
					sum(inputs["omega"][t] * EP[:eEmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T) <=
					sum(inputs["dfMaxCO2Rate"][z,cap] * sum(inputs["omega"][t] * (inputs["pD"][t,z] - sum(EP[:vNSE][s,t,z] for s in 1:SEG)) for t=1:T) for z = findall(x->x==1, inputs["dfCO2CapZones"][:,cap])) +
					sum(inputs["dfMaxCO2Rate"][z,cap] * setup["StorageLosses"] *  EP[:eELOSSByZone][z] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]))
				)
			elseif setup["ModelH2"] == 1 # Add NetPowerConsumption term to Demand side - could positive or negative
				@constraint(EP, cCO2Emissions_systemwide[cap=1:inputs["NCO2Cap"]],
					sum(inputs["omega"][t] * EP[:eEmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T) <=
					sum(inputs["dfMaxCO2Rate"][z,cap] * sum(inputs["omega"][t] * (inputs["pD"][t,z] +EP[:eH2NetpowerConsumptionByAll][t,z] - sum(EP[:vNSE][s,t,z] for s in 1:SEG)) for t=1:T) for z = findall(x->x==1, inputs["dfCO2CapZones"][:,cap])) +
					sum(inputs["dfMaxCO2Rate"][z,cap] * setup["StorageLosses"] *  EP[:eELOSSByZone][z] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]))
				)
			end


		## Generation + Rate-based: Emissions constraint in terms of rate (tons/MWh)
		elseif (setup["CO2Cap"]==3)
			@constraint(EP, cCO2Emissions_systemwide[cap=1:inputs["NCO2Cap"]],
				sum(inputs["omega"][t] * EP[:eEmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T) <=
				sum(inputs["dfMaxCO2Rate"][z,cap] * inputs["omega"][t] * EP[:eGenerationByZone][z,t] for t=1:T, z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]))
			)
		end 
	end

	#@constraint(eP, cCO2Emissions_systemwide[cap=1:inputs["NCO2Cap"]], EP[:eCO2Cap][cap]<=0)
	return EP

end

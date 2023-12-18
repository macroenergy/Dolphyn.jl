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
    bio_herb_supply(EP::Model, inputs::Dict, setup::Dict)

Sets up herb biomass variables

This module defines the herb biomass resource decision variable $x_{z,t}^{\textrm{B,Herb}} \forall z \in \mathcal{Z}, t \in \mathcal{T}$, representing herb biomass utilized in zone $z$ at time period $t$. 

The variables defined in this file named after ```vHerb_biomass_utilized_per_zone_per_time``` covers all variables $x_{z,t}^{\textrm{B,Herb}}$.

**Cost expressions**

This module additionally defines contributions to the objective function from variable costs of generation (variable OM) from herb biomass supply over all time periods.

```math
\begin{equation*}
	\textrm{C}^{\textrm{Herb,o}} = \sum_{z \in \mathcal{Z}} \sum_{t \in \mathcal{T}} \omega_t \times \textrm{c}_{r}^{\textrm{Herb,VOM}} \times x_{z,t}^{\textrm{B,Herb}}
\end{equation*}
```	

**Maximum herb biomass supply**

```math
\begin{equation*}
	x_{z,t}^{\textrm{B,Herb}} \leq  y_{z}^{\textrm{B,Herb}} \quad \forall z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

This function creates expression to add the CO2 emissions for herb biomass in each zone, which is subsequently added to the total emissions.
"""
function bio_herb_supply(EP::Model, inputs::Dict, setup::Dict)

	println("Bioenergy herbaceous biomass supply cost module")

	#Define sets
	T = inputs["T"]     # Number of time steps (hours)
    Z = inputs["Z"]     # Zones

	#Variables
	@variable(EP,vHerb_biomass_utilized_per_zone_per_time[z in 1:Z, t in 1:T] >= 0)

	Herb_biomass_supply_df = inputs["Herb_biomass_supply_df"]

	if setup["ParameterScale"] ==1
		Herb_biomass_Supply_Max = Herb_biomass_supply_df[!,:Max_tonne_per_hr]/ModelScalingFactor #Convert to ktonne
		Herb_biomass_cost_per_tonne = Herb_biomass_supply_df[!,:Cost_per_tonne_per_hr]/ModelScalingFactor #Convert to $M/ktonne
		Herb_biomass_emission_per_tonne = Herb_biomass_supply_df[!,:Emissions_tonne_per_tonne] #Convert to ktonne/ktonne = tonne/tonne
	else
		Herb_biomass_Supply_Max = Herb_biomass_supply_df[!,:Max_tonne_per_hr]
		Herb_biomass_cost_per_tonne = Herb_biomass_supply_df[!,:Cost_per_tonne_per_hr]
		Herb_biomass_emission_per_tonne = Herb_biomass_supply_df[!,:Emissions_tonne_per_tonne]
	end

	#Add to Obj, need to account for time weight omega
	@expression(EP, eHerb_biomass_supply_cost_per_zone_per_time[z in 1:Z, t in 1:T], inputs["omega"][t] * EP[:vHerb_biomass_utilized_per_zone_per_time][z,t] * Herb_biomass_cost_per_tonne[z])
	@expression(EP, eHerb_biomass_emission_per_zone_per_time[z in 1:Z, t in 1:T], EP[:vHerb_biomass_utilized_per_zone_per_time][z,t] * Herb_biomass_emission_per_tonne[z])

	#Output without time weight to show hourly cost
	@expression(EP, eHerb_biomass_supply_cost_per_zone_per_time_output[z in 1:Z, t in 1:T], EP[:vHerb_biomass_utilized_per_zone_per_time][z,t] * Herb_biomass_cost_per_tonne[z])

	#Total biomass supply cost per zone
	@expression(EP, eHerb_biomass_supply_cost_per_zone[z in 1:Z], sum(EP[:eHerb_biomass_supply_cost_per_zone_per_time][z,t] for t in 1:T))

	#Total biomass supply cost
	@expression(EP, eHerb_biomass_supply_cost, sum(EP[:eHerb_biomass_supply_cost_per_zone][z] for z in 1:Z))

	#Max biomass supply constraint
	@constraint(EP,cHerb_biomass_Max[z in 1:Z, t in 1:T], EP[:vHerb_biomass_utilized_per_zone_per_time][z,t] <= Herb_biomass_Supply_Max[z])

	EP[:eObj] += EP[:eHerb_biomass_supply_cost]

	return EP

end

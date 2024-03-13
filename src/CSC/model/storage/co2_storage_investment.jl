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
	co2_storage_investment(EP::Model, inputs::Dict, setup::Dict)

This module defines the total fixed cost (Investment + Fixed O&M) of the CO2 storage infrastructure in the CO2 supply chain

Sets up constraints common to all CO2 storage resources.

This function defines the expressions and constraints keeping track of total available CO2 storage capacity $y_{s}^{\textrm{C,STO}}$ (per year) as well as constraints on capacity.

The expression defined in this file named after ```vCapacity\textunderscore{CO2}\textunderscore{Storage}\textunderscore{per}\textunderscore{type}``` covers all variables $y_{s}^{\textrm{C,STO}}$.

The total capacity (per year) of each CO2 storage resource is defined as the sum of newly invested capacity (per year) based on the assumption there are no existing CO2 storage resources. 

**Cost expressions**

This module additionally defines contributions to the objective function from investment costs of CO2 storage (fixed O\&M plus investment costs) from all resources $s \in \mathcal{S}$:

```math
\begin{equation*}
	\textrm{C}^{\textrm{C,STO,c}} = \sum_{s \in \mathcal{S}} \sum_{z \in \mathcal{Z}} y_{s, z}^{\textrm{C,STO}}\times \textrm{c}_{s}^{\textrm{STO,INV}} + \sum_{s \in \mathcal{S}} \sum_{z \in \mathcal{Z}} y_{g, z}^{\textrm{C,STO,total}} \times \textrm{c}_{s}^{\textrm{STO,FOM}}
\end{equation*}
```

**Constraints on CO2 storage capacity (per year)**

For resources where upper bound $\overline{y_{s}^{\textrm{C,STO}}}$ and lower bound $\underline{y_{s}^{\textrm{C,STO}}}$ of capacity is defined, then we impose constraints on minimum and maximum storage capacity (per year).

```math
\begin{equation*}
	\underline{y_{s,z}^{\textrm{C,STO}}} \leq y_{s,z}^{\textrm{C,STO}} \leq \overline{y_{s,z}^{\textrm{C,STO}}} \quad \forall k \in \mathcal{S}, z \in \mathcal{Z}
\end{equation*}
```
"""
function co2_storage_investment(EP::Model, inputs::Dict, setup::Dict)
	#Model the capacity and cost of injecting the CO2 into geological storage, ignore the cost of the geological storage itself as assume it is naturally ocurring and very large so no limit to how much can be stored

	println("Carbon Storage Injection Cost module")

    dfCO2Storage = inputs["dfCO2Storage"]
	CO2_STOR_ALL = inputs["CO2_STOR_ALL"]

	Z = inputs["Z"]
	T = inputs["T"]
	
	#General variables for non-piecewise and piecewise cost functions
	@variable(EP,vCapacity_CO2_Storage_per_type[i in 1:CO2_STOR_ALL])
	@variable(EP,vCAPEX_CO2_Storage_per_type[i in 1:CO2_STOR_ALL])

	if setup["ParameterScale"] == 1
		CO2_Storage_Capacity_Min_Limit = dfCO2Storage[!,:Min_capacity_tonne_per_yr]/ModelScalingFactor # kt/h
		CO2_Storage_Capacity_Max_Limit = dfCO2Storage[!,:Max_capacity_tonne_per_yr]/ModelScalingFactor # kt/h
		CO2_Storage_Inv_Cost_per_tonne_per_yr_yr = dfCO2Storage[!,:Inv_Cost_per_tonne_per_yr_yr]/ModelScalingFactor # $M/kton
		CO2_Storage_Fixed_OM_Cost_per_tonne_per_yr_yr = dfCO2Storage[!,:Fixed_OM_Cost_per_tonne_per_yr_yr]/ModelScalingFactor # $M/kton
	else
		CO2_Storage_Capacity_Min_Limit = dfCO2Storage[!,:Min_capacity_tonne_per_yr] # t/h
		CO2_Storage_Capacity_Max_Limit = dfCO2Storage[!,:Max_capacity_tonne_per_yr] # t/h
		CO2_Storage_Inv_Cost_per_tonne_per_yr_yr = dfCO2Storage[!,:Inv_Cost_per_tonne_per_yr_yr]
		CO2_Storage_Fixed_OM_Cost_per_tonne_per_yr_yr = dfCO2Storage[!,:Fixed_OM_Cost_per_tonne_per_yr_yr]
	end

	#CAPEX
	@expression(EP, eCAPEX_CO2_Storage_per_type[i in 1:CO2_STOR_ALL], EP[:vCapacity_CO2_Storage_per_type][i] * CO2_Storage_Inv_Cost_per_tonne_per_yr_yr[i])
	
	#Fixed OM cost
	@expression(EP, eFixed_OM_CO2_Storage_per_type[i in 1:CO2_STOR_ALL], EP[:vCapacity_CO2_Storage_per_type][i] * CO2_Storage_Fixed_OM_Cost_per_tonne_per_yr_yr[i])
	
	#####################################################################################################################################
	#Min and max capacity constraints
	@constraint(EP,cMinCapacity_CO2_Storage[i in 1:CO2_STOR_ALL], EP[:vCapacity_CO2_Storage_per_type][i] >= CO2_Storage_Capacity_Min_Limit[i])
	@constraint(EP,cMaxCapacity_CO2_Storage[i in 1:CO2_STOR_ALL], EP[:vCapacity_CO2_Storage_per_type][i] <= CO2_Storage_Capacity_Max_Limit[i])
	
	#####################################################################################################################################
	##Expressions
	#Cost per type of technology
	
	#Total fixed cost = CAPEX + Fixed OM
	@expression(EP, eFixed_Cost_CO2_Storage_per_type[i in 1:CO2_STOR_ALL], EP[:eFixed_OM_CO2_Storage_per_type][i] + EP[:eCAPEX_CO2_Storage_per_type][i])
	
	#Total cost
	#Expression for total CAPEX for all resoruce types (For output and to add to objective function)
	@expression(EP,eCAPEX_CO2_Storage_total, sum(EP[:eCAPEX_CO2_Storage_per_type][i] for i in 1:CO2_STOR_ALL))
	
	#Expression for total Fixed OM for all resoruce types (For output and to add to objective function)
	@expression(EP,eFixed_OM_CO2_Storage_total, sum(EP[:eFixed_OM_CO2_Storage_per_type][i] for i in 1:CO2_STOR_ALL))
	
	#Expression for total Fixed Cost for all resoruce types (For output and to add to objective function)
	@expression(EP,eFixed_Cost_CO2_Storage_total, sum(EP[:eFixed_Cost_CO2_Storage_per_type][i] for i in 1:CO2_STOR_ALL))
	
	# Add term to objective function expression
	add_similar_to_expression!(EP[:eObj], EP[:eFixed_Cost_CO2_Storage_total])

    return EP

end

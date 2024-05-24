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
	co2_capture_compression_investment(EP::Model, inputs::Dict, setup::Dict)

This module defines the total fixed cost (Investment + Fixed O&M) of compressing the CO2 after capture by DAC

Sets up constraints common to all CO2 compression resources.

This function defines the expressions and constraints keeping track of total available CO2 compression capacity $y_{k}^{\textrm{C,COMP}}$ as well as constraints on capacity.

The expression defined in this file named after ```vCapacity\textunderscore{CO2}\textunderscore{Caputure}\textunderscore{Comp}\textunderscore{per}\textunderscore{type}``` covers all variables $y_{k}^{\textrm{C,DAC}}$.

The total capacity of each CO2 compression resource is defined as the sum of newly invested capacity based on the assumption there are no existing CO2 compression resources. 

**Cost expressions**

This module additionally defines contributions to the objective function from investment costs of CO2 compression (fixed O\&M plus investment costs) from all resources $k \in \mathcal{K}$:

```math
\begin{equation*}
	\textrm{C}^{\textrm{C,COMP,c}} = \sum_{k \in \mathcal{K}} \sum_{z \in \mathcal{Z}} y_{k, z}^{\textrm{C,COMP}}\times \textrm{c}_{k}^{\textrm{COMP,INV}} + \sum_{k \in \mathcal{K}} \sum_{z \in \mathcal{Z}} y_{g, z}^{\textrm{C,COMP,total}} \times \textrm{c}_{k}^{\textrm{COMP,FOM}}
\end{equation*}
```
"""
function co2_capture_compression_investment(EP::Model, inputs::Dict, setup::Dict)
	#Model the capacity and cost of compressing the CO2 after capture

	println("Carbon Capture Compression Cost module")

	dfCO2CaptureComp = inputs["dfCO2CaptureComp"]
	CO2_CAPTURE_COMP_ALL = inputs["CO2_CAPTURE_COMP_ALL"]

	Z = inputs["Z"]
	T = inputs["T"]
	
	#General variables for non-piecewise and piecewise cost functions
	@variable(EP,vCapacity_CO2_Capture_Comp_per_type[i in 1:CO2_CAPTURE_COMP_ALL])
	@variable(EP,vCAPEX_CO2_Capture_Comp_per_type[i in 1:CO2_CAPTURE_COMP_ALL])

	if setup["ParameterScale"] == 1
		CO2_Capture_Comp_Capacity_Min_Limit = dfCO2CaptureComp[!,:Min_capacity_tonne_per_hr]/ModelScalingFactor # kt/h
		CO2_Capture_Comp_Capacity_Max_Limit = dfCO2CaptureComp[!,:Max_capacity_tonne_per_hr]/ModelScalingFactor # kt/h
		CO2_Capture_Comp_Inv_Cost_per_tonne_per_hr_yr = dfCO2CaptureComp[!,:Inv_Cost_per_tonne_per_hr_yr]/ModelScalingFactor #$M/kton
		CO2_Capture_Comp_Fixed_OM_Cost_per_tonne_per_hr_yr = dfCO2CaptureComp[!,:Fixed_OM_Cost_per_tonne_per_hr_yr]/ModelScalingFactor #$M/kton
	
	else
		CO2_Capture_Comp_Capacity_Min_Limit = dfCO2CaptureComp[!,:Min_capacity_tonne_per_hr] # t/h
		CO2_Capture_Comp_Capacity_Max_Limit = dfCO2CaptureComp[!,:Max_capacity_tonne_per_hr] # t/h
		CO2_Capture_Comp_Inv_Cost_per_tonne_per_hr_yr = dfCO2CaptureComp[!,:Inv_Cost_per_tonne_per_hr_yr]
		CO2_Capture_Comp_Fixed_OM_Cost_per_tonne_per_hr_yr = dfCO2CaptureComp[!,:Fixed_OM_Cost_per_tonne_per_hr_yr]
	
	end

	#Linear CAPEX using refcapex similar to fixed O&M cost calculation method
	#Consider using constraint for vCAPEX_CO2_Capture_Comp_per_type? Or expression is better
	@expression(EP, eCAPEX_CO2_Capture_Comp_per_type[i in 1:CO2_CAPTURE_COMP_ALL], EP[:vCapacity_CO2_Capture_Comp_per_type][i] * CO2_Capture_Comp_Inv_Cost_per_tonne_per_hr_yr[i])
	
	#Fixed OM cost #Check again to match capacity
	@expression(EP, eFixed_OM_CO2_Capture_Comp_per_type[i in 1:CO2_CAPTURE_COMP_ALL], EP[:vCapacity_CO2_Capture_Comp_per_type][i] * CO2_Capture_Comp_Fixed_OM_Cost_per_tonne_per_hr_yr[i])

	#####################################################################################################################################
	#Min and max capacity constraints
	@constraint(EP,cMinCapacity_CO2_Capture_Comp_per_unit[i in 1:CO2_CAPTURE_COMP_ALL], EP[:vCapacity_CO2_Capture_Comp_per_type][i] >= CO2_Capture_Comp_Capacity_Min_Limit[i])

	# Constraint on maximum capacity (if applicable) [set input to -1 if no constraint on maximum capacity]
	@constraint(EP, cMaxCapacity_CO2_Capture_Comp_per_unit[i in intersect(dfCO2CaptureComp[dfCO2CaptureComp.Max_capacity_tonne_per_hr.>0, :R_ID], 1:CO2_CAPTURE_COMP_ALL)], EP[:vCapacity_CO2_Capture_Comp_per_type][i] <= CO2_Capture_Comp_Capacity_Max_Limit[i])
	
	#####################################################################################################################################
	##Expressions
	#Cost per type of technology
	
	#Total fixed cost = CAPEX + Fixed OM
	@expression(EP, eFixed_Cost_CO2_Capture_Comp_per_type[i in 1:CO2_CAPTURE_COMP_ALL], EP[:eFixed_OM_CO2_Capture_Comp_per_type][i] + EP[:eCAPEX_CO2_Capture_Comp_per_type][i])
	
	#Total cost
	#Expression for total CAPEX for all resoruce types (For output and to add to objective function)
	@expression(EP,eCAPEX_CO2_Capture_Comp_total, sum(EP[:eCAPEX_CO2_Capture_Comp_per_type][i] for i in 1:CO2_CAPTURE_COMP_ALL))
	
	#Expression for total Fixed OM for all resoruce types (For output and to add to objective function)
	@expression(EP,eFixed_OM_CO2_Capture_Comp_total, sum(EP[:eFixed_OM_CO2_Capture_Comp_per_type][i] for i in 1:CO2_CAPTURE_COMP_ALL))
	
	#Expression for total Fixed Cost for all resoruce types (For output and to add to objective function)
	@expression(EP,eFixed_Cost_CO2_Capture_Comp_total, sum(EP[:eFixed_Cost_CO2_Capture_Comp_per_type][i] for i in 1:CO2_CAPTURE_COMP_ALL))
	
	# Add term to objective function expression
	EP[:eObj] += EP[:eFixed_Cost_CO2_Capture_Comp_total]

    return EP

end

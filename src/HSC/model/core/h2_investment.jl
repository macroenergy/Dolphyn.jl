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
    h2_discharge(EP::Model, inputs::Dict, UCommit::Int, Reserves::Int)

This module defines the production decision variable representing hydrogen injected into the network by resource $y$ by at time period $t$.

This module additionally defines contributions to the objective function from variable costs of generation (variable O&M plus fuel cost) from all resources over all time periods.

**Variables**
```math
\begin{aligned}
	\vartheta _{k}^{GenNewCap}\ge 0	
\end{aligned}
```	

```math
\begin{aligned}
	\vartheta _{k}^{GenRetCap}\ge 0
\end{aligned}
```

```math
\begin{aligned}
& \Delta^{total}_{y,z} =(\overline{\Delta_{y,z}}-\Delta_{y,z}) \forall y \in \mathcal{G}, z \in \mathcal{Z}
\end{aligned}
```
	
One cannot retire more capacity than existing capacity.
```math
\begin{aligned}
&\Delta_{y,z} \leq \overline{\Delta_{y,z}}
	\hspace{4 cm}  \forall y \in \mathcal{G}, z \in \mathcal{Z}
\end{aligned}
```
	

In addition, this function adds investment and fixed O\&M related costs related to discharge/generation capacity to the objective function:
```math
\begin{aligned}
& 	\sum_{y \in \mathcal{G} } \sum_{z \in \mathcal{Z}}
	\left( (\pi^{INVEST}_{y,z} \times \overline{\Omega}^{size}_{y,z} \times  )
	+ (\pi^{FOM}_{y,z} \times \Delta^{total}_{y,z})\right)
\end{aligned}
```
"""
function h2_investment(EP::Model, inputs::Dict, setup::Dict)

	println("Hydrogen Investment Discharge Module")

    dfH2Gen = inputs["dfH2Gen"]

    # Define sets
    H2_GEN_NEW_CAP = inputs["H2_GEN_NEW_CAP"]
    H2_GEN_RET_CAP = inputs["H2_GEN_RET_CAP"]
    H2_GEN_COMMIT = inputs["H2_GEN_COMMIT"]
    H = inputs["H2_RES_ALL"]

    # Capacity of New H2 Gen units (tonnes/hr)
    # For generation with unit commitment, this variable refers to the number of units, not capacity. 
    @variable(EP, vH2GenNewCap[k in H2_GEN_NEW_CAP] >= 0)
    # Capacity of Retired H2 Gen units bui(tonnes/hr)
    # For generation with unit commitment, this variable refers to the number of units, not capacity. 
    @variable(EP, vH2GenRetCap[k in H2_GEN_RET_CAP] >= 0)

    ### Expressions ###
    # Cap_Size is set to 1 for all variables when unit UCommit == 0
    # When UCommit > 0, Cap_Size is set to 1 for all variables except those where THERM == 1
    @expression(
        EP,
        eH2GenTotalCap[k in 1:H],
        if k in intersect(H2_GEN_NEW_CAP, H2_GEN_RET_CAP) # Resources eligible for new capacity and retirements
            if k in H2_GEN_COMMIT
                dfH2Gen[!, :Existing_Cap_tonne_p_hr][k] +
                dfH2Gen[!, :Cap_Size_tonne_p_hr][k] *
                (EP[:vH2GenNewCap][k] - EP[:vH2GenRetCap][k])
            else
                dfH2Gen[!, :Existing_Cap_tonne_p_hr][k] + EP[:vH2GenNewCap][k] -
                EP[:vH2GenRetCap][k]
            end
        elseif k in setdiff(H2_GEN_NEW_CAP, H2_GEN_RET_CAP) # Resources eligible for only new capacity
            if k in H2_GEN_COMMIT
                dfH2Gen[!, :Existing_Cap_tonne_p_hr][k] +
                dfH2Gen[!, :Cap_Size_tonne_p_hr][k] * EP[:vH2GenNewCap][k]
            else
                dfH2Gen[!, :Existing_Cap_tonne_p_hr][k] + EP[:vH2GenNewCap][k]
            end
        elseif k in setdiff(H2_GEN_RET_CAP, H2_GEN_NEW_CAP) # Resources eligible for only capacity retirements
            if k in H2_GEN_COMMIT
                dfH2Gen[!, :Existing_Cap_tonne_p_hr][k] -
                dfH2Gen[!, :Cap_Size_tonne_p_hr][k] * EP[:vH2GenRetCap][k]
            else
                dfH2Gen[!, :Existing_Cap_tonne_p_hr][k] - EP[:vH2GenRetCap][k]
            end
        else
            # Resources not eligible for new capacity or retirements
            dfH2Gen[!, :Existing_Cap_tonne_p_hr][k]
        end
    )

    ## Objective Function Expressions ##

    # Sum individual resource contributions to fixed costs to get total fixed costs
    #  ParameterScale = 1 --> objective function is in million $ . In power system case we only scale by 1000 because variables are also scaled. But here we dont scale variables.
    #  ParameterScale = 0 --> objective function is in $
    if setup["ParameterScale"] == 1
        # Fixed costs for resource "y" = annuitized investment cost plus fixed O&M costs
        # If resource is not eligible for new capacity, fixed costs are only O&M costs
        @expression(
            EP,
            eH2GenCFix[k in 1:H],
            if k in H2_GEN_NEW_CAP # Resources eligible for new capacity
                if k in H2_GEN_COMMIT
                    1 / ModelScalingFactor^2 * (
                        dfH2Gen[!, :Inv_Cost_p_tonne_p_hr_yr][k] *
                        dfH2Gen[!, :Cap_Size_tonne_p_hr][k] *
                        EP[:vH2GenNewCap][k] +
                        dfH2Gen[!, :Fixed_OM_Cost_p_tonne_p_hr_yr][k] * eH2GenTotalCap[k]
                    )
                else
                    1 / ModelScalingFactor^2 * (
                        dfH2Gen[!, :Inv_Cost_p_tonne_p_hr_yr][k] * EP[:vH2GenNewCap][k] +
                        dfH2Gen[!, :Fixed_OM_Cost_p_tonne_p_hr_yr][k] * eH2GenTotalCap[k]
                    )
                end
            else
                (dfH2Gen[!, :Fixed_OM_Cost_p_tonne_p_hr_yr][k] * eH2GenTotalCap[k]) /
                ModelScalingFactor^2
            end
        )
    else
        # Fixed costs for resource "y" = annuitized investment cost plus fixed O&M costs
        # If resource is not eligible for new capacity, fixed costs are only O&M costs
        @expression(
            EP,
            eH2GenCFix[k in 1:H],
            if k in H2_GEN_NEW_CAP # Resources eligible for new capacity
                if k in H2_GEN_COMMIT
                    dfH2Gen[!, :Inv_Cost_p_tonne_p_hr_yr][k] *
                    dfH2Gen[!, :Cap_Size_tonne_p_hr][k] *
                    EP[:vH2GenNewCap][k] +
                    dfH2Gen[!, :Fixed_OM_Cost_p_tonne_p_hr_yr][k] * eH2GenTotalCap[k]
                else
                    dfH2Gen[!, :Inv_Cost_p_tonne_p_hr_yr][k] * EP[:vH2GenNewCap][k] +
                    dfH2Gen[!, :Fixed_OM_Cost_p_tonne_p_hr_yr][k] * eH2GenTotalCap[k]
                end
            else
                dfH2Gen[!, :Fixed_OM_Cost_p_tonne_p_hr_yr][k] * eH2GenTotalCap[k]
            end
        )
    end

    @expression(EP, eTotalH2GenCFix, sum(EP[:eH2GenCFix][k] for k = 1:H))

    # Add term to objective function expression
    EP[:eObj] += eTotalH2GenCFix

    return EP

end

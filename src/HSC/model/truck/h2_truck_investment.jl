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
    h2_truck_investment(EP::Model, inputs::Dict, setup::Dict)

This function includes investment variables, expressions and related constraints for H2 trucks.

**Variables**

## Truck capacity built and retired
```math
\begin{equation*}
    0 \leq v_{CAP,j}^{\textrm{H,TRU}}
\end{equation*}
```

```math
\begin{equation*}
    0 \leq v_{RETCAP,j}^{\textrm{H,TRU}}
\end{equation*}
```

```math
\begin{equation*}
    0 \leq v_{CAP,j}^{\textrm{H,TRU}}
\end{equation*}
```

```math
\begin{equation*}
    0 \leq v_{NEWCAP,j}^{\textrm{H,TRU}}
\end{equation*}
```

**Constraints**

Truck retirements cannot retire more charge capacity than existing charge capacity
```math
\begin{equation*}
    v_{RETCAPNUM,j}^{\textrm{H,TRU}} \leq v_{ExistNum,j}^{\textrm{H,TRU}} \quad \forall j \in \mathbb{J}
\end{equation*}
```
Truck compression energy cannot retire more energy capacity than existing energy capacity
```math
\begin{equation*}
    v_{RETCAPEnergy,j}^{\textrm{H,TRU}} \leq v_{ExistEnergyCap,j}^{\textrm{H,TRU}} \quad \forall j \in \mathbb{J}
\end{equation*}
```

**Expressions**
```math
\begin{align*}
    C_{\textrm{\textrm{H,TRU}}}^{\textrm{o}}=& \sum_{z \rightarrow z^{\prime} \in \mathbb{B}} \sum_{j \in \mathbb{J}} \sum_{t \in \mathbb{T}} \omega_t \textrm{L}_{z \rightarrow z^{\prime}} \\
    & \times\left(\textrm{o}_{j}^{\textrm{\textrm{H,TRU}}, \textrm{F}} y_{z \rightarrow z^{\prime}, j, t}^{\textrm{F}}+\textrm{o}_{j}^{\textrm{\textrm{H,TRU}}, \textrm{E}} y_{z \rightarrow z^{\prime}, j, t}^{\textrm{E}}\right)
\end{align*}
```
"""
function h2_truck_investment(EP::Model, inputs::Dict, setup::Dict)

    print_and_log("H2 Truck Investment Module")

    dfH2Truck = inputs["dfH2Truck"]

    Z = inputs["Z"] # Model zones - assumed to be same for H2 and electricity
    H2_TRUCK_TYPES = inputs["H2_TRUCK_TYPES"] # Set of all truck types

    NEW_CAP_TRUCK = inputs["NEW_CAP_TRUCK"] # Set of hydrogen truck types eligible for new capacity
    RET_CAP_TRUCK = inputs["RET_CAP_TRUCK"] # Set of hydrogen truck eligible for capacity retirements

    ### Variables ###

    ## Truck capacity built and retired

    # New installed charge capacity of truck type "j"
    @variable(EP, vH2TruckNumber[j in NEW_CAP_TRUCK] >= 0)

    # Retired charge capacity of truck type "j" from existing capacity
    @variable(EP, vH2RetTruckNumber[j in RET_CAP_TRUCK] >= 0)

    # New installed energy capacity of truck type "j" on zone "z"
    @variable(EP, vH2TruckComp[z = 1:Z, j in NEW_CAP_TRUCK] >= 0)

    # Retired energy capacity of truck type "j" on zone "z" from existing capacity
    @variable(EP, vH2RetTruckComp[z = 1:Z, j in RET_CAP_TRUCK] >= 0)

    # Total available truck loading capacity in truck number, for hydrogen in tonnes (unit capacity of each truck is needed)
    @expression(
        EP,
        eTotalH2TruckNumber[j in H2_TRUCK_TYPES],
        if (j in intersect(NEW_CAP_TRUCK, RET_CAP_TRUCK))
            dfH2Truck[!, :Existing_Number][j] + EP[:vH2TruckNumber][j] -
            EP[:vH2RetTruckNumber][j]
        elseif (j in setdiff(NEW_CAP_TRUCK, RET_CAP_TRUCK))
            dfH2Truck[!, :Existing_Number][j] + EP[:vH2TruckNumber][j]
        elseif (j in setdiff(RET_CAP_TRUCK, NEW_CAP_TRUCK))
            dfH2Truck[!, :Existing_Number][j] - EP[:vH2RetTruckNumber][j]
        else
            dfH2Truck[!, :Existing_Number][j]
        end
    )

    # Total available compression capacity in tonnes/hour
    @expression(
        EP,
        eTotalH2TruckComp[z = 1:Z, j in H2_TRUCK_TYPES],
        if (j in intersect(NEW_CAP_TRUCK, RET_CAP_TRUCK))
            dfH2Truck[!, Symbol("Existing_Comp_Cap_tonne_p_hr_z$z")][j] + EP[:vH2TruckComp][z, j] -
            EP[:vH2RetTruckComp][z, j]
        elseif (j in setdiff(NEW_CAP_TRUCK, RET_CAP_TRUCK))
            dfH2Truck[!, Symbol("Existing_Comp_Cap_tonne_p_hr_z$z")][j] + EP[:vH2TruckComp][z, j]
        elseif (j in setdiff(RET_CAP_TRUCK, NEW_CAP_TRUCK))
            dfH2Truck[!, Symbol("Existing_Comp_Cap_tonne_p_hr_z$z")][j] - EP[:vH2RetTruckComp][z, j]
        else
            dfH2Truck[!, Symbol("Existing_Comp_Cap_tonne_p_hr_z$z")][j]
        end
    )

    ## Objective Function Expressions ##

    # Charge capacity costs
    # Fixed costs for truck type "j" = annuitized investment cost
    # If truck is not eligible for new charge capacity, fixed costs are zero
    # Sum individual truck type contributions to fixed costs to get total fixed costs
    #  ParameterScale = 1 --> objective function is in million $ . In power system case we only scale by 1000 because variables are also scaled. But here we dont scale variables.
    #  ParameterScale = 0 --> objective function is in $
    if setup["ParameterScale"] ==1
        @expression(EP, eCFixH2TruckCharge[j in H2_TRUCK_TYPES],
            if j in NEW_CAP_TRUCK # Truck types eligible for new charge capacity
                (dfH2Truck[!,:Inv_Cost_p_unit_p_yr][j]*vH2TruckNumber[j])/ModelScalingFactor^2
            else
                EP[:vZERO]
            end
        )
    else
        @expression(EP, eCFixH2TruckCharge[j in H2_TRUCK_TYPES],
            if j in NEW_CAP_TRUCK # Truck types eligible for new charge capacity
                dfH2Truck[!,:Inv_Cost_p_unit_p_yr][j]*vH2TruckNumber[j]
            else
                EP[:vZERO]
            end
        )
    end

    # Sum individual resource contributions to fixed costs to get total fixed costs
    @expression(EP, eTotalCFixH2TruckCharge, sum(EP[:eCFixH2TruckCharge][j] for j in H2_TRUCK_TYPES))

    # Add term to objective function expression
    EP[:eObj] += eTotalCFixH2TruckCharge

    # Energy capacity costs
    # Fixed costs for truck type "j" on zone "z" = annuitized investment cost plus fixed O&M costs
    # If resource is not eligible for new energy capacity, fixed costs are only O&M costs
    #  ParameterScale = 1 --> objective function is in million $ . In power system case we only scale by 1000 because variables are also scaled. But here we dont scale variables.
    #  ParameterScale = 0 --> objective function is in $
    if setup["ParameterScale"]==1
        @expression(EP, eCFixH2TruckComp[z = 1:Z, j in H2_TRUCK_TYPES],
        if j in NEW_CAP_TRUCK # Resources eligible for new capacity
            1/ModelScalingFactor^2*(dfH2Truck[!,:Inv_Cost_Comp_p_tonne_p_hr_yr][j]*vH2TruckComp[z, j] + dfH2Truck[!,:Fixed_OM_Cost_Comp_p_tonne_p_hr_yr][j]*eTotalH2TruckComp[z, j])
        else
            1/ModelScalingFactor^2*(dfH2truck[!,:Fixed_OM_Cost_Comp_p_tonne_p_hr_yr][j]*eTotalH2TruckComp[z, j])
        end
        )
    else
        @expression(EP, eCFixH2TruckComp[z = 1:Z, j in H2_TRUCK_TYPES],
        if j in NEW_CAP_TRUCK # Resources eligible for new capacity
            dfH2Truck[!,:Inv_Cost_Comp_p_tonne_p_hr_yr][j]*vH2TruckComp[z, j] + dfH2Truck[!,:Fixed_OM_Cost_Comp_p_tonne_p_hr_yr][j]*eTotalH2TruckComp[z, j]
        else
            dfH2Truck[!,:Fixed_OM_Cost_Comp_p_tonne_p_hr_yr][y]*eTotalH2TruckComp[z, j]
        end
        )
    end

    # Sum individual zone and individual resource contributions to fixed costs to get total fixed costs
    @expression(EP, eTotalCFixH2TruckCompPerType[z in 1:Z], sum(EP[:eCFixH2TruckComp][z, j] for j in H2_TRUCK_TYPES))
    @expression(EP, eTotalCFixH2TruckComp, sum(EP[:eTotalCFixH2TruckCompPerType][z] for z in 1:Z))

    # Add term to objective function expression
    EP[:eObj] += eTotalCFixH2TruckComp


    ### Constratints ###

    ## Constraints on truck retirements
    #Cannot retire more charge capacity than existing charge capacity
     @constraint(EP, cMaxRetH2TruckNumber[j in RET_CAP_TRUCK], vH2RetTruckNumber[j] <= dfH2Truck[!,:Existing_Number][j])


      ## Constraints on truck compression
    # Cannot retire more capacity than existing compression capacity
    @constraint(EP, cMaxRetH2TruckComp[z = 1:Z, j in RET_CAP_TRUCK], vH2RetTruckComp[z,j] <= dfH2Truck[!, Symbol("Existing_Comp_Cap_tonne_p_hr$z")][j])

    ## Constraints on new built truck compression capacity
    # Constraint on maximum compression capacity (if applicable) [set input to -1 if no constraint on maximum compression capacity]
    # DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MWh is >= Max_Cap_MWh and lead to infeasabilty
    @constraint(EP, cMaxCapH2TruckComp[z = 1:Z, j in intersect(dfH2Truck[dfH2Truck.Max_Comp_Cap_tonne.>0,:T_TYPE], H2_TRUCK_TYPES)], eTotalH2TruckComp[z, j] <= dfH2Truck[!,:Max_Comp_Cap_tonne][j])

    # Constraint on minimum compression capacity (if applicable) [set input to -1 if no constraint on minimum compression apacity]
    # DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MWh is <= Min_Cap_MWh and lead to infeasabilty
    @constraint(EP, cMinCapH2TruckComp[z = 1:Z, j in intersect(dfH2Truck[dfH2Truck.Min_Comp_Cap_tonne.>0,:T_TYPE], H2_TRUCK_TYPES)], eTotalH2TruckComp[z, j] >= dfH2Truck[!,:Min_Comp_Cap_tonne][j])

    return EP
end

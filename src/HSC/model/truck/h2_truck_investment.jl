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
\begin{aligned}
    v_{CAP,j}^{TRU} \geq 0
\end{aligned}
```

```math
\begin{aligned}
    v_{RETCAP,j}^{TRU} \geq 0
\end{aligned}
```

```math
\begin{aligned}
   v_{CAP,j}^{TRU} \geq 0
\end{aligned}
```

```math
\begin{aligned}
    v_{NEWCAP,j}^{TRU} \geq 0
\end{aligned}
```

**Constraints**

Truck retirements cannot retire more charge capacity than existing charge capacity
```math
\begin{aligned}
    v_{RETCAPNUM,j}^{TRU} \le v_{ExistNum,j}^{TRU}
\end{aligned}
```
Truck compression energy: Cannot retire more energy capacity than existing energy capacity
```math
\begin{aligned}
    v_{RETCAPEnergy,j}^{TRU} \le v_{ExistEnergyCap,j}^{TRU} 
\end{aligned}
```

**Expressions**
```math
\begin{aligned}
    C_{\mathrm{TRU}}^{\mathrm{o}}=& \sum_{z \rightarrow z^{\prime} \in \mathbb{B}} \sum_{j \in \mathbb{J}} \sum_{t \in \mathbb{T}} \Omega_{t} \mathrm{~L}_{z \rightarrow z^{\prime}} \\
    & \times\left(\mathrm{o}_{j}^{\mathrm{TRU}, \mathrm{F}} y_{z \rightarrow z,{ }^{\prime} j, t}^{\mathrm{F}}+\mathrm{o}_{j}^{\mathrm{TRU}, \mathrm{E}} y_{z \rightarrow z,,^{\prime} j, t}^{\mathrm{E}}\right)
\end{aligned}
```
"""
function h2_truck_investment(EP::Model, inputs::Dict, setup::Dict)

    println("H2 Truck Investment Module")

    dfH2Truck = inputs["dfH2Truck"]

	Z = inputs["Z"] # Model zones - assumed to be same for H2 and electricity 
    H2_TRUCK_TYPES = inputs["H2_TRUCK_TYPES"] # Set of all truck types

    NEW_CAP_H2_TRUCK_CHARGE = inputs["NEW_CAP_H2_TRUCK_CHARGE"] # Set of hydrogen truck types eligible for new capacity
    RET_CAP_H2_TRUCK_CHARGE = inputs["RET_CAP_H2_TRUCK_CHARGE"] # Set of hydrogen truck eligible for capacity retirements

    NEW_CAP_H2_TRUCK_ENERGY = inputs["NEW_CAP_H2_TRUCK_ENERGY"] # Set of hydrogen truck compression eligible for new energy capacity
    RET_CAP_H2_TRUCK_ENERGY = inputs["RET_CAP_H2_TRUCK_ENERGY"] # Set of hydrogen truck compression eligible for energy capacity retirements

    ### Variables ###

    ## Truck capacity built and retired

    # New installed charge capacity of truck type "j"
    @variable(EP, vH2TruckNumber[j in NEW_CAP_H2_TRUCK_CHARGE] >= 0)

    # Retired charge capacity of truck type "j" from existing capacity
    @variable(EP, vH2RetTruckNumber[j in RET_CAP_H2_TRUCK_CHARGE] >= 0)

    # New installed energy capacity of truck type "j" on zone "z"
    @variable(EP, vH2TruckEnergy[z = 1:Z, j in NEW_CAP_H2_TRUCK_ENERGY] >= 0)

    # Retired energy capacity of truck type "j" on zone "z" from existing capacity
    @variable(EP, vH2RetTruckEnergy[z = 1:Z, j in RET_CAP_H2_TRUCK_ENERGY] >= 0)

    # Total available charging capacity in tonnes/hour
    @expression(
        EP,
        eTotalH2TruckNumber[j in H2_TRUCK_TYPES],
        if (j in intersect(NEW_CAP_H2_TRUCK_CHARGE, RET_CAP_H2_TRUCK_CHARGE))
            dfH2Truck[!, :Existing_Number][j] + EP[:vH2TruckNumber][j] -
            EP[:vH2RetTruckNumber][j]
        elseif (j in setdiff(NEW_CAP_H2_TRUCK_CHARGE, RET_CAP_H2_TRUCK_CHARGE))
            dfH2Truck[!, :Existing_Number][j] + EP[:vH2TruckNumber][j]
        elseif (j in setdiff(RET_CAP_H2_TRUCK_CHARGE, NEW_CAP_H2_TRUCK_CHARGE))
            dfH2Truck[!, :Existing_Number][j] - EP[:vH2RetTruckNumber][j]
        else
            dfH2Truck[!, :Existing_Number][j]
        end
    )


    # Total available energy capacity in tonnes
    @expression(
        EP,
        eTotalH2TruckEnergy[z = 1:Z, j in H2_TRUCK_TYPES],
        if (j in intersect(NEW_CAP_H2_TRUCK_ENERGY, RET_CAP_H2_TRUCK_ENERGY))
            dfH2Truck[!, Symbol("Existing_Energy_Cap_tonne_z$z")][j] + EP[:vH2TruckEnergy][z, j] -
            EP[:vH2RetTruckEnergy][z, j]
        elseif (j in setdiff(NEW_CAP_H2_TRUCK_ENERGY, RET_CAP_H2_TRUCK_ENERGY))
            dfH2Truck[!, Symbol("Existing_Energy_Cap_tonne_z$z")][j] + EP[:vH2TruckEnergy][z, j]
        elseif (j in setdiff(RET_CAP_H2_TRUCK_ENERGY, NEW_CAP_H2_TRUCK_ENERGY))
            dfH2Truck[!, Symbol("Existing_Energy_Cap_tonne_z$z")][j] - EP[:vH2RetTruckEnergy][z, j]
        else
            dfH2Truck[!, Symbol("Existing_Energy_Cap_tonne_z$z")][j]
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
            if j in NEW_CAP_H2_TRUCK_CHARGE # Truck types eligible for new charge capacity
                (dfH2Truck[!,:Inv_Cost_p_unit_p_yr][j]*vH2TruckNumber[j])/ModelScalingFactor^2
            else
                EP[:vZERO]
            end
        )
    else
        @expression(EP, eCFixH2TruckCharge[j in H2_TRUCK_TYPES],
            if j in NEW_CAP_H2_TRUCK_CHARGE # Truck types eligible for new charge capacity
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
		@expression(EP, eCFixH2TruckEnergy[z = 1:Z, j in H2_TRUCK_TYPES],
		if j in NEW_CAP_H2_TRUCK_ENERGY # Resources eligible for new capacity
			1/ModelScalingFactor^2*(dfH2Truck[!,:Inv_Cost_Energy_p_tonne_yr][j]*vH2TruckEnergy[z, j] + dfH2Truck[!,:Fixed_OM_Cost_Energy_p_tonne_yr][j]*eTotalH2TruckEnergy[z, j])
		else
			1/ModelScalingFactor^2*(dfH2truck[!,:Fixed_OM_Cost_Energy_p_tonne_yr][j]*eTotalH2TruckEnergy[z, j])
		end
		)
	else
		@expression(EP, eCFixH2TruckEnergy[z = 1:Z, j in H2_TRUCK_TYPES],
		if j in NEW_CAP_H2_TRUCK_ENERGY # Resources eligible for new capacity
			dfH2Truck[!,:Inv_Cost_Energy_p_tonne_yr][j]*vH2TruckEnergy[z, j] + dfH2Truck[!,:Fixed_OM_Cost_Energy_p_tonne_yr][j]*eTotalH2TruckEnergy[z, j]
		else
			dfH2Truck[!,:Fixed_OM_Cost_Energy_p_tonne_yr][y]*eTotalH2TruckEnergy[z, j]
		end
		)
	end

    # Sum individual zone and individual resource contributions to fixed costs to get total fixed costs
    @expression(EP, eTotalCFixH2TruckEnergy, sum(EP[:eCFixH2TruckEnergy][z, j] for z = 1:Z, j in H2_TRUCK_TYPES))

    # Add term to objective function expression
    EP[:eObj] += eTotalCFixH2TruckEnergy


	### Constratints ###

	## Constraints on truck retirements
	#Cannot retire more charge capacity than existing charge capacity
 	@constraint(EP, cMaxRetH2TruckNumber[j in RET_CAP_H2_TRUCK_CHARGE], vH2RetTruckNumber[j] <= dfH2Truck[!,:Existing_Number][j])


  	## Constraints on truck compression energy
		
	# Cannot retire more energy capacity than existing energy capacity
	@constraint(EP, cMaxRetH2TruckEnergy[z = 1:Z, j in RET_CAP_H2_TRUCK_ENERGY], vH2RetTruckEnergy[z,j] <= dfH2Truck[!, Symbol("Existing_Energy_Cap_tonne_z$z")][j])

	## Constraints on new built truck compression energy capacity
	# Constraint on maximum energy capacity (if applicable) [set input to -1 if no constraint on maximum energy capacity]
	# DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MWh is >= Max_Cap_MWh and lead to infeasabilty
	@constraint(EP, cMaxCapH2TruckEnergy[z = 1:Z, j in intersect(dfH2Truck[dfH2Truck.Max_Energy_Cap_tonne.>0,:T_TYPE], H2_TRUCK_TYPES)], eTotalH2TruckEnergy[z, j] <= dfH2Truck[!,:Max_Energy_Cap_tonne][j])

	# Constraint on minimum energy capacity (if applicable) [set input to -1 if no constraint on minimum energy apacity]
	# DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MWh is <= Min_Cap_MWh and lead to infeasabilty
	@constraint(EP, cMinCapH2TruckEnergy[z = 1:Z, j in intersect(dfH2Truck[dfH2Truck.Min_Energy_Cap_tonne.>0,:T_TYPE], H2_TRUCK_TYPES)], eTotalH2TruckEnergy[z, j] >= dfH2Truck[!,:Min_Energy_Cap_tonne][j])

	return EP
end

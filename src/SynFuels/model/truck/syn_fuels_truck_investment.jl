"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
Copyright (C) 2021,  Massachusetts Institute of Technology
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

"""
function syn_fuels_truck_investment(EP::Model, inputs::Dict, setup::Dict)

    println("Synthesis Fuels Truck Investment Module")

    dfSynTruck = inputs["dfSynTruck"]

	Z = inputs["Z"] # Model zones - assumed to be same for H2 and electricity
    SYN_TRUCK_TYPES = inputs["SYN_TRUCK_TYPES"] # Set of all truck types

    NEW_CAP_SYN_TRUCK_CHARGE = inputs["NEW_CAP_SYN_TRUCK_CHARGE"] # Set of hydrogen truck types eligible for new capacity
    RET_CAP_SYN_TRUCK_CHARGE = inputs["RET_CAP_SYN_TRUCK_CHARGE"] # Set of hydrogen truck eligible for capacity retirements

    NEW_CAP_SYN_TRUCK_ENERGY = inputs["NEW_CAP_SYN_TRUCK_ENERGY"] # Set of hydrogen truck compression eligible for new energy capacity
    RET_CAP_SYN_TRUCK_ENERGY = inputs["RET_CAP_SYN_TRUCK_ENERGY"] # Set of hydrogen truck compression eligible for energy capacity retirements

    ### Variables ###

    ## Truck capacity built and retired

    # New installed charge capacity of truck type "j"
    @variable(EP, vSynTruckNumber[j in NEW_CAP_SYN_TRUCK_CHARGE] >= 0)

    # Retired charge capacity of truck type "j" from existing capacity
    @variable(EP, vSynRetTruckNumber[j in RET_CAP_SYN_TRUCK_CHARGE] >= 0)

    # New installed energy capacity of truck type "j" on zone "z"
    @variable(EP, vSynTruckEnergy[z = 1:Z, j in NEW_CAP_SYN_TRUCK_ENERGY] >= 0)

    # Retired energy capacity of truck type "j" on zone "z" from existing capacity
    @variable(EP, vSynRetTruckEnergy[z = 1:Z, j in RET_CAP_SYN_TRUCK_ENERGY] >= 0)

    # Total available charging capacity in tonnes/hour
    @expression(
        EP,
        eTotalSynTruckNumber[j in SYN_TRUCK_TYPES],
        if (j in intersect(NEW_CAP_SYN_TRUCK_CHARGE, RET_CAP_SYN_TRUCK_CHARGE))
            dfSynTruck[!, :Existing_Number][j] + EP[:vSynTruckNumber][j] -
            EP[:vSynRetTruckNumber][j]
        elseif (j in setdiff(NEW_CAP_SYN_TRUCK_CHARGE, RET_CAP_SYN_TRUCK_CHARGE))
            dfSynTruck[!, :Existing_Number][j] + EP[:vSynTruckNumber][j]
        elseif (j in setdiff(RET_CAP_SYN_TRUCK_CHARGE, NEW_CAP_SYN_TRUCK_CHARGE))
            dfSynTruck[!, :Existing_Number][j] - EP[:vSynRetTruckNumber][j]
        else
            dfSynTruck[!, :Existing_Number][j]
        end
    )


    # Total available energy capacity in tonnes
    @expression(
        EP,
        eTotalSynTruckEnergy[z = 1:Z, j in SYN_TRUCK_TYPES],
        if (j in intersect(NEW_CAP_SYN_TRUCK_ENERGY, RET_CAP_SYN_TRUCK_ENERGY))
            dfSynTruck[!, Symbol("Existing_Energy_Cap_tonne_z$z")][j] + EP[:vSynTruckEnergy][z, j] -
            EP[:vSynRetTruckEnergy][z, j]
        elseif (j in setdiff(NEW_CAP_SYN_TRUCK_ENERGY, RET_CAP_SYN_TRUCK_ENERGY))
            dfSynTruck[!, Symbol("Existing_Energy_Cap_tonne_z$z")][j] + EP[:vSynTruckEnergy][z, j]
        elseif (j in setdiff(RET_CAP_SYN_TRUCK_ENERGY, NEW_CAP_SYN_TRUCK_ENERGY))
            dfSynTruck[!, Symbol("Existing_Energy_Cap_tonne_z$z")][j] - EP[:vSynRetTruckEnergy][z, j]
        else
            dfSynTruck[!, Symbol("Existing_Energy_Cap_tonne_z$z")][j]
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
        @expression(EP, eCFixSynTruckCharge[j in SYN_TRUCK_TYPES],
            if j in NEW_CAP_SYN_TRUCK_CHARGE # Truck types eligible for new charge capacity
                (dfSynTruck[!,:Inv_Cost_p_unit_p_yr][j]*vSynTruckNumber[j])/ModelScalingFactor^2
            else
                EP[:vZERO]
            end
        )
    else
        @expression(EP, eCFixSynTruckCharge[j in SYN_TRUCK_TYPES],
            if j in NEW_CAP_SYN_TRUCK_CHARGE # Truck types eligible for new charge capacity
                dfSynTruck[!,:Inv_Cost_p_unit_p_yr][j]*vSynTruckNumber[j]
            else
                EP[:vZERO]
            end
        )
    end

	# Sum individual resource contributions to fixed costs to get total fixed costs
	@expression(EP, eTotalCFixSynTruckCharge, sum(EP[:eCFixSynTruckCharge][j] for j in SYN_TRUCK_TYPES))

	# Add term to objective function expression
	EP[:eObj] += eTotalCFixSynTruckCharge

    # Energy capacity costs
	# Fixed costs for truck type "j" on zone "z" = annuitized investment cost plus fixed O&M costs
	# If resource is not eligible for new energy capacity, fixed costs are only O&M costs
	#  ParameterScale = 1 --> objective function is in million $ . In power system case we only scale by 1000 because variables are also scaled. But here we dont scale variables.
	#  ParameterScale = 0 --> objective function is in $
	if setup["ParameterScale"]==1
		@expression(EP, eCFixSynTruckEnergy[z = 1:Z, j in SYN_TRUCK_TYPES],
		if j in NEW_CAP_SYN_TRUCK_ENERGY # Resources eligible for new capacity
			1/ModelScalingFactor^2*(dfSynTruck[!,:Inv_Cost_Energy_p_tonne_yr][j]*vSynTruckEnergy[z, j] + dfSynTruck[!,:Fixed_OM_Cost_Energy_p_tonne_yr][j]*eTotalSynTruckEnergy[z, j])
		else
			1/ModelScalingFactor^2*(dfSyntruck[!,:Fixed_OM_Cost_Energy_p_tonne_yr][j]*eTotalSynTruckEnergy[z, j])
		end
		)
	else
		@expression(EP, eCFixSynTruckEnergy[z = 1:Z, j in SYN_TRUCK_TYPES],
		if j in NEW_CAP_SYN_TRUCK_ENERGY # Resources eligible for new capacity
			dfSynTruck[!,:Inv_Cost_Energy_p_tonne_yr][j]*vSynTruckEnergy[z, j] + dfSynTruck[!,:Fixed_OM_Cost_Energy_p_tonne_yr][j]*eTotalSynTruckEnergy[z, j]
		else
			dfSynTruck[!,:Fixed_OM_Cost_Energy_p_tonne_yr][y]*eTotalSynTruckEnergy[z, j]
		end
		)
	end

    # Sum individual zone and individual resource contributions to fixed costs to get total fixed costs
    @expression(EP, eTotalCFixSynTruckEnergy, sum(EP[:eCFixSynTruckEnergy][z, j] for z = 1:Z, j in SYN_TRUCK_TYPES))

    # Add term to objective function expression
    EP[:eObj] += eTotalCFixSynTruckEnergy


	### Constratints ###

	## Constraints on truck retirements
	#Cannot retire more charge capacity than existing charge capacity
 	@constraint(EP, cMaxRetSynTruckNumber[j in RET_CAP_SYN_TRUCK_CHARGE], vSynRetTruckNumber[j] <= dfSynTruck[!,:Existing_Number][j])


  	## Constraints on truck compression energy

	# Cannot retire more energy capacity than existing energy capacity
	@constraint(EP, cMaxRetSynTruckEnergy[z = 1:Z, j in RET_CAP_SYN_TRUCK_ENERGY], vSynRetTruckEnergy[z,j] <= dfSynTruck[!, Symbol("Existing_Energy_Cap_tonne_z$z")][j])

	## Constraints on new built truck compression energy capacity
	# Constraint on maximum energy capacity (if applicable) [set input to -1 if no constraint on maximum energy capacity]
	# DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MWh is >= Max_Cap_MWh and lead to infeasabilty
	@constraint(EP, cMaxCapSynTruckEnergy[z = 1:Z, j in intersect(dfSynTruck[dfSynTruck.Max_Energy_Cap_tonne.>0,:T_TYPE], SYN_TRUCK_TYPES)], eTotalSynTruckEnergy[z, j] <= dfSynTruck[!,:Max_Energy_Cap_tonne][j])

	# Constraint on minimum energy capacity (if applicable) [set input to -1 if no constraint on minimum energy apacity]
	# DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MWh is <= Min_Cap_MWh and lead to infeasabilty
	@constraint(EP, cMinCapSynTruckEnergy[z = 1:Z, j in intersect(dfSynTruck[dfSynTruck.Min_Energy_Cap_tonne.>0,:T_TYPE], SYN_TRUCK_TYPES)], eTotalSynTruckEnergy[z, j] >= dfSynTruck[!,:Min_Energy_Cap_tonne][j])

	return EP
end

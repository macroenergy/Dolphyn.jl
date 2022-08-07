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

function co2_truck_investment(EP::Model, inputs::Dict, setup::Dict)

    println("CO2 Truck Investment Module")

    dfCO2Truck = inputs["dfCO2Truck"]

	Z = inputs["Z"] # Model zones - assumed to be same for H2 and electricity 
    CO2_TRUCK_TYPES = inputs["CO2_TRUCK_TYPES"] # Set of all truck types

    NEW_CAP_CO2_TRUCK_CHARGE = inputs["NEW_CAP_CO2_TRUCK_CHARGE"] # Set of hydrogen truck types eligible for new capacity
    RET_CAP_CO2_TRUCK_CHARGE = inputs["RET_CAP_CO2_TRUCK_CHARGE"] # Set of hydrogen truck eligible for capacity retirements

    NEW_CAP_CO2_TRUCK_ENERGY = inputs["NEW_CAP_CO2_TRUCK_ENERGY"] # Set of hydrogen truck compression eligible for new energy capacity
    RET_CAP_CO2_TRUCK_ENERGY = inputs["RET_CAP_CO2_TRUCK_ENERGY"] # Set of hydrogen truck compression eligible for energy capacity retirements

    ### Variables ###

    ## Truck capacity built and retired

    # New installed charge capacity of truck type "j"
    @variable(EP, vCO2TruckNumber[j in NEW_CAP_CO2_TRUCK_CHARGE] >= 0)

    # Retired charge capacity of truck type "j" from existing capacity
    @variable(EP, vCO2RetTruckNumber[j in RET_CAP_CO2_TRUCK_CHARGE] >= 0)

    # New installed energy capacity of truck type "j" on zone "z"
    @variable(EP, vCO2TruckEnergy[z = 1:Z, j in NEW_CAP_CO2_TRUCK_ENERGY] >= 0)

    # Retired energy capacity of truck type "j" on zone "z" from existing capacity
    @variable(EP, vCO2RetTruckEnergy[z = 1:Z, j in RET_CAP_CO2_TRUCK_ENERGY] >= 0)

    # Total available charging capacity in tonnes/hour
    @expression(
        EP,
        eTotalCO2TruckNumber[j in CO2_TRUCK_TYPES],
        if (j in intersect(NEW_CAP_CO2_TRUCK_CHARGE, RET_CAP_CO2_TRUCK_CHARGE))
            dfCO2Truck[!, :Existing_Number][j] + EP[:vCO2TruckNumber][j] -
            EP[:vCO2RetTruckNumber][j]
        elseif (j in setdiff(NEW_CAP_CO2_TRUCK_CHARGE, RET_CAP_CO2_TRUCK_CHARGE))
            dfCO2Truck[!, :Existing_Number][j] + EP[:vCO2TruckNumber][j]
        elseif (j in setdiff(RET_CAP_CO2_TRUCK_CHARGE, NEW_CAP_CO2_TRUCK_CHARGE))
            dfCO2Truck[!, :Existing_Number][j] - EP[:vCO2RetTruckNumber][j]
        else
            dfCO2Truck[!, :Existing_Number][j]
        end
    )


    # Total available energy capacity in tonnes
    @expression(
        EP,
        eTotalCO2TruckEnergy[z = 1:Z, j in CO2_TRUCK_TYPES],
        if (j in intersect(NEW_CAP_CO2_TRUCK_ENERGY, RET_CAP_CO2_TRUCK_ENERGY))
            dfCO2Truck[!, Symbol("Existing_Energy_Cap_tonne_z$z")][j] + EP[:vCO2TruckEnergy][z, j] -
            EP[:vCO2RetTruckEnergy][z, j]
        elseif (j in setdiff(NEW_CAP_CO2_TRUCK_ENERGY, RET_CAP_CO2_TRUCK_ENERGY))
            dfCO2Truck[!, Symbol("Existing_Energy_Cap_tonne_z$z")][j] + EP[:vCO2TruckEnergy][z, j]
        elseif (j in setdiff(RET_CAP_CO2_TRUCK_ENERGY, NEW_CAP_CO2_TRUCK_ENERGY))
            dfCO2Truck[!, Symbol("Existing_Energy_Cap_tonne_z$z")][j] - EP[:vCO2RetTruckEnergy][z, j]
        else
            dfCO2Truck[!, Symbol("Existing_Energy_Cap_tonne_z$z")][j]
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
        @expression(EP, eCFixCO2TruckCharge[j in CO2_TRUCK_TYPES],
            if j in NEW_CAP_CO2_TRUCK_CHARGE # Truck types eligible for new charge capacity
                (dfCO2Truck[!,:Inv_Cost_p_unit_p_yr][j]*vCO2TruckNumber[j])/ModelScalingFactor^2
            else
                EP[:vZERO]
            end
        )
    else
        @expression(EP, eCFixCO2TruckCharge[j in CO2_TRUCK_TYPES],
            if j in NEW_CAP_CO2_TRUCK_CHARGE # Truck types eligible for new charge capacity
                dfCO2Truck[!,:Inv_Cost_p_unit_p_yr][j]*vCO2TruckNumber[j]
            else
                EP[:vZERO]
            end
        )
    end

	# Sum individual resource contributions to fixed costs to get total fixed costs
	@expression(EP, eTotalCFixCO2TruckCharge, sum(EP[:eCFixCO2TruckCharge][j] for j in CO2_TRUCK_TYPES))

	# Add term to objective function expression
	EP[:eObj] += eTotalCFixCO2TruckCharge

    # Energy capacity costs
	# Fixed costs for truck type "j" on zone "z" = annuitized investment cost plus fixed O&M costs
	# If resource is not eligible for new energy capacity, fixed costs are only O&M costs
	#  ParameterScale = 1 --> objective function is in million $ . In power system case we only scale by 1000 because variables are also scaled. But here we dont scale variables.
	#  ParameterScale = 0 --> objective function is in $
	if setup["ParameterScale"]==1
		@expression(EP, eCFixCO2TruckEnergy[z = 1:Z, j in CO2_TRUCK_TYPES],
		if j in NEW_CAP_CO2_TRUCK_ENERGY # Resources eligible for new capacity
			1/ModelScalingFactor^2*(dfCO2Truck[!,:Inv_Cost_Energy_p_tonne_yr][j]*vCO2TruckEnergy[z, j] + dfCO2Truck[!,:Fixed_OM_Cost_Energy_p_tonne_yr][j]*eTotalCO2TruckEnergy[z, j])
		else
			1/ModelScalingFactor^2*(dfCO2truck[!,:Fixed_OM_Cost_Energy_p_tonne_yr][j]*eTotalCO2TruckEnergy[z, j])
		end
		)
	else
		@expression(EP, eCFixCO2TruckEnergy[z = 1:Z, j in CO2_TRUCK_TYPES],
		if j in NEW_CAP_CO2_TRUCK_ENERGY # Resources eligible for new capacity
			dfCO2Truck[!,:Inv_Cost_Energy_p_tonne_yr][j]*vCO2TruckEnergy[z, j] + dfCO2Truck[!,:Fixed_OM_Cost_Energy_p_tonne_yr][j]*eTotalCO2TruckEnergy[z, j]
		else
			dfCO2Truck[!,:Fixed_OM_Cost_Energy_p_tonne_yr][y]*eTotalCO2TruckEnergy[z, j]
		end
		)
	end

    # Sum individual zone and individual resource contributions to fixed costs to get total fixed costs
    @expression(EP, eTotalCFixCO2TruckEnergy, sum(EP[:eCFixCO2TruckEnergy][z, j] for z = 1:Z, j in CO2_TRUCK_TYPES))

    # Add term to objective function expression
    EP[:eObj] += eTotalCFixCO2TruckEnergy


	### Constratints ###

	## Constraints on truck retirements
	#Cannot retire more charge capacity than existing charge capacity
 	@constraint(EP, cMaxRetCO2TruckNumber[j in RET_CAP_CO2_TRUCK_CHARGE], vCO2RetTruckNumber[j] <= dfCO2Truck[!,:Existing_Number][j])


  	## Constraints on truck compression energy
		
	# Cannot retire more energy capacity than existing energy capacity
	@constraint(EP, cMaxRetCO2TruckEnergy[z = 1:Z, j in RET_CAP_CO2_TRUCK_ENERGY], vCO2RetTruckEnergy[z,j] <= dfCO2Truck[!, Symbol("Existing_Energy_Cap_tonne_z$z")][j])

	## Constraints on new built truck compression energy capacity
	# Constraint on maximum energy capacity (if applicable) [set input to -1 if no constraint on maximum energy capacity]
	# DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MWh is >= Max_Cap_MWh and lead to infeasabilty
	@constraint(EP, cMaxCapCO2TruckEnergy[z = 1:Z, j in intersect(dfCO2Truck[dfCO2Truck.Max_Energy_Cap_tonne.>0,:T_TYPE], CO2_TRUCK_TYPES)], eTotalCO2TruckEnergy[z, j] <= dfCO2Truck[!,:Max_Energy_Cap_tonne][j])

	# Constraint on minimum energy capacity (if applicable) [set input to -1 if no constraint on minimum energy apacity]
	# DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MWh is <= Min_Cap_MWh and lead to infeasabilty
	@constraint(EP, cMinCapCO2TruckEnergy[z = 1:Z, j in intersect(dfCO2Truck[dfCO2Truck.Min_Energy_Cap_tonne.>0,:T_TYPE], CO2_TRUCK_TYPES)], eTotalCO2TruckEnergy[z, j] >= dfCO2Truck[!,:Min_Energy_Cap_tonne][j])

	return EP
end

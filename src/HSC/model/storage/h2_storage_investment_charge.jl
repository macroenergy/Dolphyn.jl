"""
DOLPHYN: Decision Optimization for Low-carbon for Power and Hydrogen Networks
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
	h2_storage_investment_charge(EP::Model, inputs::Dict, setup::Dict)

This module defines the decision variables representing charging investment of hydrogen storage technologies.

"""
function h2_storage_investment_charge(EP::Model, inputs::Dict, setup::Dict)

    println("H2 Storage Charging Investment Module")

    dfH2Gen = inputs["dfH2Gen"]

    H2_STOR_ALL = inputs["H2_STOR_ALL"] # Set of H2 storage resources - all have asymmetric (separate) charge/discharge capacity components

    NEW_CAP_H2_CHARGE = inputs["NEW_CAP_H2_CHARGE"] # Set of asymmetric charge/discharge storage resources eligible for new charge capacity
    RET_CAP_H2_CHARGE = inputs["RET_CAP_H2_CHARGE"] # Set of asymmetric charge/discharge storage resources eligible for charge capacity retirements

    ### Variables ###

    ## Storage capacity built and retired for storage resources with independent charge and discharge power capacities (STOR=2)

    # New installed charge capacity of resource "y"
    @variable(EP, vH2CAPCHARGE[y in NEW_CAP_H2_CHARGE] >= 0)

    # Retired charge capacity of resource "y" from existing capacity
    @variable(EP, vH2RETCAPCHARGE[y in RET_CAP_H2_CHARGE] >= 0)

    ### Expressions ###
    # Total available charging capacity in tonnes/hour
    @expression(
        EP,
        eTotalH2CapCharge[y in H2_STOR_ALL],
        if (y in intersect(NEW_CAP_H2_CHARGE, RET_CAP_H2_CHARGE))
            dfH2Gen[!, :Existing_Charge_Cap_tonne_p_hr][y] + EP[:vH2CAPCHARGE][y] -
            EP[:vH2RETCAPCHARGE][y]
        elseif (y in setdiff(NEW_CAP_H2_CHARGE, RET_CAP_H2_CHARGE))
            dfH2Gen[!, :Existing_Charge_Cap_tonne_p_hr][y] + EP[:vH2CAPCHARGE][y]
        elseif (y in setdiff(RET_CAP_H2_CHARGE, NEW_CAP_H2_CHARGE))
            dfH2Gen[!, :Existing_Charge_Cap_tonne_p_hr][y] - EP[:vH2RETCAPCHARGE][y]
        else
            dfH2Gen[!, :Existing_Charge_Cap_tonne_p_hr][y]
        end
    )

    ## Objective Function Expressions ##

    # Fixed costs for resource "y" = annuitized investment cost plus fixed O&M costs
    # If resource is not eligible for new charge capacity, fixed costs are only O&M costs
    # Sum individual resource contributions to fixed costs to get total fixed costs
    #  ParameterScale = 1 --> objective function is in million $ . In power system case we only scale by 1000 because variables are also scaled. But here we dont scale variables.
    #  ParameterScale = 0 --> objective function is in $
    if setup["ParameterScale"] == 1

        @expression(
            EP,
            eCFixH2Charge[y in H2_STOR_ALL],
            if y in NEW_CAP_H2_CHARGE # Resources eligible for new charge capacity
                1 / ModelScalingFactor^2 * (
                    dfH2Gen[!, :Inv_Cost_Charge_p_tonne_p_hr_yr][y] * vH2CAPCHARGE[y] +
                    dfH2Gen[!, :Fixed_OM_Cost_Charge_p_tonne_p_hr_yr][y] *
                    eTotalH2CapCharge[y]
                )
            else
                1 / ModelScalingFactor^2 * (
                    dfH2Gen[!, :Fixed_OM_Cost_Charge_p_tonne_p_hr_yr][y] *
                    eTotalH2CapCharge[y]
                )
            end
        )

    else
        @expression(
            EP,
            eCFixH2Charge[y in H2_STOR_ALL],
            if y in NEW_CAP_H2_CHARGE # Resources eligible for new charge capacity
                dfH2Gen[!, :Inv_Cost_Charge_p_tonne_p_hr_yr][y] * vH2CAPCHARGE[y] +
                dfH2Gen[!, :Fixed_OM_Cost_Charge_p_tonne_p_hr_yr][y] * eTotalH2CapCharge[y]
            else
                dfH2Gen[!, :Fixed_OM_Cost_Charge_p_tonne_p_hr_yr][y] * eTotalH2CapCharge[y]
            end
        )
    end

    # Sum individual resource contributions to fixed costs to get total fixed costs
    @expression(EP, eTotalCFixH2Charge, sum(EP[:eCFixH2Charge][y] for y in H2_STOR_ALL))

    # Add term to objective function expression
    EP[:eObj] += eTotalCFixH2Charge

    ### Constratints ###

    ## Constraints on retirements and capacity additions
    #Cannot retire more charge capacity than existing charge capacity
    @constraint(
        EP,
        cMaxRetH2Charge[y in RET_CAP_H2_CHARGE],
        vH2RETCAPCHARGE[y] <= dfH2Gen[!, :Existing_Cap_Charge_tonne_p_hr][y]
    )

    # Constraints on new built capacity

    # Constraint on maximum charge capacity (if applicable) [set input to -1 if no constraint on maximum charge capacity]
    # DEV NOTE: This constraint may be violated in some cases where Existing_Charge_Cap_MW is >= Max_Charge_Cap_MWh and lead to infeasabilty
    @constraint(
        EP,
        cMaxCapH2Charge[y in intersect(
            dfH2Gen[!, :Max_Charge_Cap_tonne_p_hr] .> 0,
            H2_STOR_ALL,
        )],
        eTotalH2CapCharge[y] <= dfH2Gen[!, :Max_Charge_Cap_tonne_p_hr][y]
    )

    # Constraint on minimum charge capacity (if applicable) [set input to -1 if no constraint on minimum charge capacity]
    # DEV NOTE: This constraint may be violated in some cases where Existing_Charge_Cap_MW is <= Min_Charge_Cap_MWh and lead to infeasabilty
    @constraint(
        EP,
        cMinCapH2Charge[y in intersect(
            dfH2Gen[!, :Min_Charge_Cap_tonne_p_hr] .> 0,
            H2_STOR_ALL,
        )],
        eTotalH2CapCharge[y] >= dfH2Gen[!, :Min_Charge_Cap_tonne_p_hr][y]
    )

    return EP
end
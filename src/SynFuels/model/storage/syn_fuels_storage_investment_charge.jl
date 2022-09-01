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
	syn_fuels_storage_investment_charge(EP::Model, inputs::Dict, setup::Dict)

This module defines the  decision variable representing charging components of hydrogen storage technologies

"""

function syn_fuels_storage_investment_charge(EP::Model, inputs::Dict, setup::Dict)

    println("Synthesis Fuels Storage Charging Investment Module")

    dfSynGen = inputs["dfSynGen"]

    SYN_STOR_ALL = inputs["SYN_STOR_ALL"] # Set of H2 storage resources - all have asymmetric (separate) charge/discharge capacity components

    NEW_CAP_SYN_CHARGE = inputs["NEW_CAP_SYN_CHARGE"] # Set of asymmetric charge/discharge storage resources eligible for new charge capacity
    RET_CAP_SYN_CHARGE = inputs["RET_CAP_SYN_CHARGE"] # Set of asymmetric charge/discharge storage resources eligible for charge capacity retirements

    ### Variables ###

    ## Storage capacity built and retired for storage resources with independent charge and discharge power capacities (STOR=2)

    # New installed charge capacity of resource "y"
    @variable(EP, vSYNCAPCHARGE[y in NEW_CAP_SYN_CHARGE] >= 0)

    # Retired charge capacity of resource "y" from existing capacity
    @variable(EP, vSYNRETCAPCHARGE[y in RET_CAP_SYN_CHARGE] >= 0)

    ### Expressions ###
    # Total available charging capacity in tonnes/hour
    @expression(
        EP,
        eTotalSynCapCharge[y in SYN_STOR_ALL],
        if (y in intersect(NEW_CAP_SYN_CHARGE, RET_CAP_SYN_CHARGE))
            dfSynGen[!, :Existing_Charge_Cap_tonne_p_hr][y] + EP[:vSYNCAPCHARGE][y] -
            EP[:vSYNRETCAPCHARGE][y]
        elseif (y in setdiff(NEW_CAP_SYN_CHARGE, RET_CAP_SYN_CHARGE))
            dfSynGen[!, :Existing_Charge_Cap_tonne_p_hr][y] + EP[:vSYNCAPCHARGE][y]
        elseif (y in setdiff(RET_CAP_SYN_CHARGE, NEW_CAP_SYN_CHARGE))
            dfSynGen[!, :Existing_Charge_Cap_tonne_p_hr][y] - EP[:vSYNRETCAPCHARGE][y]
        else
            dfSynGen[!, :Existing_Charge_Cap_tonne_p_hr][y]
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
            eCFixH2Charge[y in SYN_STOR_ALL],
            if y in NEW_CAP_SYN_CHARGE # Resources eligible for new charge capacity
                1 / ModelScalingFactor^2 * (
                    dfSynGen[!, :Inv_Cost_Charge_p_tonne_p_hr_yr][y] * vSYNCAPCHARGE[y] +
                    dfSynGen[!, :Fixed_OM_Cost_Charge_p_tonne_p_hr_yr][y] *
                    eTotalSYNCapCharge[y]
                )
            else
                1 / ModelScalingFactor^2 * (
                    dfSynGen[!, :Fixed_OM_Cost_Charge_p_tonne_p_hr_yr][y] *
                    eTotalSYNCapCharge[y]
                )
            end
        )

    else
        @expression(
            EP,
            eCFixSYNCharge[y in SYN_STOR_ALL],
            if y in NEW_CAP_SYN_CHARGE # Resources eligible for new charge capacity
                dfSynGen[!, :Inv_Cost_Charge_p_tonne_p_hr_yr][y] * vSYNCAPCHARGE[y] +
                dfSynGen[!, :Fixed_OM_Cost_Charge_p_tonne_p_hr_yr][y] *
                eTotalSYNCapCharge[y]
            else
                dfSynGen[!, :Fixed_OM_Cost_Charge_p_tonne_p_hr_yr][y] *
                eTotalSYNCapCharge[y]
            end
        )
    end

    # Sum individual resource contributions to fixed costs to get total fixed costs
    @expression(EP, eTotalCFixSYNCharge, sum(EP[:eCFixSYNCharge][y] for y in SYN_STOR_ALL))

    # Add term to objective function expression
    EP[:eObj] += eTotalCFixSYNCharge

    ### Constratints ###

    ## Constraints on retirements and capacity additions
    #Cannot retire more charge capacity than existing charge capacity
    @constraint(
        EP,
        cMaxRetSYNCharge[y in RET_CAP_SYN_CHARGE],
        vSYNRETCAPCHARGE[y] <= dfSynGen[!, :Existing_Cap_Charge_tonne_p_hr][y]
    )

    # Constraints on new built capacity

    # Constraint on maximum charge capacity (if applicable) [set input to -1 if no constraint on maximum charge capacity]
    # DEV NOTE: This constraint may be violated in some cases where Existing_Charge_Cap_MW is >= Max_Charge_Cap_MWh and lead to infeasabilty
    @constraint(
        EP,
        cMaxCapSYNCharge[y in intersect(
            dfSynGen[!, :Max_Charge_Cap_tonne_p_hr] .> 0,
            SYN_STOR_ALL,
        )],
        eTotalSYNCapCharge[y] <= dfSynGen[!, :Max_Charge_Cap_tonne_p_hr][y]
    )

    # Constraint on minimum charge capacity (if applicable) [set input to -1 if no constraint on minimum charge capacity]
    # DEV NOTE: This constraint may be violated in some cases where Existing_Charge_Cap_MW is <= Min_Charge_Cap_MWh and lead to infeasabilty
    @constraint(
        EP,
        cMinCapSYNCharge[y in intersect(
            dfSynGen[!, :Min_Charge_Cap_tonne_p_hr] .> 0,
            SYN_STOR_ALL,
        )],
        eTotalSYNCapCharge[y] >= dfSynGen[!, :Min_Charge_Cap_tonne_p_hr][y]
    )

    return EP
end

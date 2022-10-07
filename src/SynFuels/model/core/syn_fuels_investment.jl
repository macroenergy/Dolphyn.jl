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
    syn_fuels_discharge(EP::Model, inputs::Dict, UCommit::Int, Reserves::Int)

This module defines the production decision variable  representing hydrogen injected into the network by resource $y$ by at time period $t$.

This module additionally defines contributions to the objective function from variable costs of generation (variable O&M plus fuel cost) from all resources over all time periods.

"""
function syn_fuels_investment(EP::Model, inputs::Dict, setup::Dict)

	println("Synthesis Fuels Investment Discharge Module")

    dfSynGen = inputs["dfSynGen"]

    # Define sets
    SYN_GEN_NEW_CAP = inputs["SYN_GEN_NEW_CAP"]
    SYN_GEN_RET_CAP = inputs["SYN_GEN_RET_CAP"]
    SYN_GEN_COMMIT = inputs["SYN_GEN_COMMIT"]

    H = inputs["SYN_RES_ALL"]

    # Capacity of New Synthesis Gen units (tonnes/hr)
    # For generation with unit commitment, this variable refers to the number of units, not capacity.
    @variable(EP, vSynGenNewCap[k in SYN_GEN_NEW_CAP] >= 0)
    # Capacity of Retired Synthesis Gen units bui(tonnes/hr)
    # For generation with unit commitment, this variable refers to the number of units, not capacity.
    @variable(EP, vSynGenRetCap[k in SYN_GEN_RET_CAP] >= 0)

    ### Expressions ###
    # Cap_Size is set to 1 for all variables when unit UCommit == 0
    # When UCommit > 0, Cap_Size is set to 1 for all variables except those where THERM == 1
    @expression(
        EP,
        eSynGenTotalCap[k in 1:H],
        if k in intersect(SYN_GEN_NEW_CAP, SYN_GEN_RET_CAP) # Resources eligible for new capacity and retirements
            if k in SYN_GEN_COMMIT
                dfSynGen[!, :Existing_Cap_tonne_p_hr][k] +
                dfSynGen[!, :Cap_Size_tonne_p_hr][k] *
                (EP[:vSynGenNewCap][k] - EP[:vSynGenRetCap][k])
            else
                dfSynGen[!, :Existing_Cap_tonne_p_hr][k] + EP[:vSynGenNewCap][k] -
                EP[:vSynGenRetCap][k]
            end
        elseif k in setdiff(SYN_GEN_NEW_CAP, SYN_GEN_RET_CAP) # Resources eligible for only new capacity
            if k in SYN_GEN_COMMIT
                dfSynGen[!, :Existing_Cap_tonne_p_hr][k] +
                dfSynGen[!, :Cap_Size_tonne_p_hr][k] * EP[:vSynGenNewCap][k]
            else
                dfSynGen[!, :Existing_Cap_tonne_p_hr][k] + EP[:vSynGenNewCap][k]
            end
        elseif k in setdiff(SYN_GEN_RET_CAP, SYN_GEN_NEW_CAP) # Resources eligible for only capacity retirements
            if k in SYN_GEN_COMMIT
                dfSynGen[!, :Existing_Cap_tonne_p_hr][k] -
                dfSynGen[!, :Cap_Size_tonne_p_hr][k] * EP[:SynGenRetCap][k]
            else
                dfSynGen[!, :Existing_Cap_tonne_p_hr][k] - EP[:vSynGenRetCap][k]
            end
        else
            # Resources not eligible for new capacity or retirements
            dfSynGen[!, :Existing_Cap_tonne_p_hr][k]
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
            eSynGenCFix[k in 1:H],
            if k in SYN_GEN_NEW_CAP # Resources eligible for new capacity
                if k in SYN_GEN_COMMIT
                    1 / ModelScalingFactor^2 * (
                        dfSynGen[!, :Inv_Cost_p_tonne_p_hr_yr][k] *
                        dfSynGen[!, :Cap_Size_tonne_p_hr][k] *
                        EP[:vSynGenNewCap][k] +
                        dfSynGen[!, :Fixed_OM_Cost_p_tonne_p_hr_yr][k] * eSynGenTotalCap[k]
                    )
                else
                    1 / ModelScalingFactor^2 * (
                        dfSynGen[!, :Inv_Cost_p_tonne_p_hr_yr][k] * EP[:vSynGenNewCap][k] +
                        dfSynGen[!, :Fixed_OM_Cost_p_tonne_p_hr_yr][k] * eSynGenTotalCap[k]
                    )
                end
            else
                (dfSynGen[!, :Fixed_OM_Cost_p_tonne_p_hr_yr][k] * eSynGenTotalCap[k]) /
                ModelScalingFactor^2
            end
        )
    else
        # Fixed costs for resource "y" = annuitized investment cost plus fixed O&M costs
        # If resource is not eligible for new capacity, fixed costs are only O&M costs
        @expression(
            EP,
            eSynGenCFix[k in 1:H],
            if k in SYN_GEN_NEW_CAP # Resources eligible for new capacity
                if k in SYN_GEN_COMMIT
                    dfSynGen[!, :Inv_Cost_p_tonne_p_hr_yr][k] *
                    dfSynGen[!, :Cap_Size_tonne_p_hr][k] *
                    EP[:vSynGenNewCap][k] +
                    dfSynGen[!, :Fixed_OM_Cost_p_tonne_p_hr_yr][k] * eSynGenTotalCap[k]
                else
                    dfSynGen[!, :Inv_Cost_p_tonne_p_hr_yr][k] * EP[:vSynGenNewCap][k] +
                    dfSynGen[!, :Fixed_OM_Cost_p_tonne_p_hr_yr][k] * eSynGenTotalCap[k]
                end
            else
                dfSynGen[!, :Fixed_OM_Cost_p_tonne_p_hr_yr][k] * eSynGenTotalCap[k]
            end
        )
    end

    @expression(EP, eTotalSynGenCFix, sum(EP[:eSynGenCFix][k] for k = 1:H))

    # Add term to objective function expression
    EP[:eObj] += eTotalSynGenCFix

    return EP

end

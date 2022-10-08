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
	syn_fuels_storage_investment_energy(EP::Model, inputs::Dict, UCommit::Int, Reserves::Int)

This module defines the  decision variable representing energy components of hydrogen storage technologies

"""
function syn_fuels_storage_investment_energy(EP::Model, inputs::Dict, setup::Dict)

    println("Synthesis Fuels Storage Energy Investment Module")

    dfSynGen = inputs["dfSynGen"]

    SYN_STOR_ALL = inputs["SYN_STOR_ALL"] # Set of all hydrogen storage resources

    NEW_CAP_SYN_ENERGY = inputs["NEW_CAP_SYN_ENERGY"] # set of storage resource eligible for new energy capacity investment
    RET_CAP_SYN_ENERGY = inputs["RET_CAP_SYN_ENERGY"] # set of storage resource eligible for energy capacity retirements

    # New installed energy capacity of resource "y"
    @variable(EP, vSYNCAPENERGY[y in NEW_CAP_SYN_ENERGY] >= 0)

    # Retired energy capacity of resource "y" from existing capacity
    @variable(EP, vSYNRETCAPENERGY[y in RET_CAP_SYN_ENERGY] >= 0)

    # Total available energy capacity in tonnes
    @expression(
        EP,
        eSynTotalCapEnergy[y in SYN_STOR_ALL],
        if (y in intersect(NEW_CAP_SYN_ENERGY, RET_CAP_SYN_ENERGY))
            dfSynGen[!, :Existing_Energy_Cap_tonne][y] + EP[:vSYNCAPENERGY][y] -
            EP[:vSYNRETCAPENERGY][y]
        elseif (y in setdiff(NEW_CAP_SYN_ENERGY, RET_CAP_SYN_ENERGY))
            dfSynGen[!, :Existing_Energy_Cap_tonne][y] + EP[:vSYNCAPENERGY][y]
        elseif (y in setdiff(RET_CAP_SYN_ENERGY, NEW_CAP_SYN_ENERGY))
            dfSynGen[!, :Existing_Energy_Cap_tonne][y] - EP[:vSYNRETCAPENERGY][y]
        else
            dfSynGen[!, :Existing_Energy_Cap_tonne][y]
        end
    )

    ## Objective Function Expressions ##

    # Energy capacity costs
    # Fixed costs for resource "y" = annuitized investment cost plus fixed O&M costs
    # If resource is not eligible for new energy capacity, fixed costs are only O&M costs
    #  ParameterScale = 1 --> objective function is in million $ . In power system case we only scale by 1000 because variables are also scaled. But here we dont scale variables.
    #  ParameterScale = 0 --> objective function is in $
    if setup["ParameterScale"] == 1
        @expression(
            EP,
            eCFixSynEnergy[y in SYN_STOR_ALL],
            if y in NEW_CAP_SYN_ENERGY # Resources eligible for new capacity
                1 / ModelScalingFactor^2 * (
                    dfSynGen[!, :Inv_Cost_Energy_p_tonne_yr][y] * vSYNCAPENERGY[y] +
                    dfSynGen[!, :Fixed_OM_Cost_Energy_p_tonne_yr][y] * eSynTotalCapEnergy[y]
                )
            else
                1 / ModelScalingFactor^2 *
                (dfSynGen[!, :Fixed_OM_Cost_Energy_p_tonne_yr][y] * eSynTotalCapEnergy[y])
            end
        )
    else
        @expression(
            EP,
            eCFixSynEnergy[y in SYN_STOR_ALL],
            if y in NEW_CAP_SYN_ENERGY # Resources eligible for new capacity
                dfSynGen[!, :Inv_Cost_Energy_p_tonne_yr][y] * vSYNCAPENERGY[y] +
                dfSynGen[!, :Fixed_OM_Cost_Energy_p_tonne_yr][y] * eSynTotalCapEnergy[y]
            else
                dfSynGen[!, :Fixed_OM_Cost_Energy_p_tonne_yr][y] * eSynTotalCapEnergy[y]
            end
        )
    end

    # Sum individual resource contributions to fixed costs to get total fixed costs
    @expression(EP, eTotalCFixSYNEnergy, sum(EP[:eCFixSynEnergy][y] for y in SYN_STOR_ALL))

    # Add term to objective function expression
    EP[:eObj] += eTotalCFixSYNEnergy

    ### Constratints ###
    # Cannot retire more energy capacity than existing energy capacity
    @constraint(
        EP,
        cMaxRetSYNEnergy[y in RET_CAP_SYN_ENERGY],
        vSYNRETCAPENERGY[y] <= dfSynGen[!, :Existing_Energy_Cap_tonne][y]
    )

    ## Constraints on new built energy capacity
    # Constraint on maximum energy capacity (if applicable) [set input to -1 if no constraint on maximum energy capacity]
    # DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MWh is >= Max_Cap_MWh and lead to infeasabilty
    @constraint(
        EP,
        cMaxCapSYNEnergy[y in intersect(
            dfSynGen[dfSynGen.Max_Energy_Cap_tonne.>0, :R_ID],
            SYN_STOR_ALL,
        )],
        eSynTotalCapEnergy[y] <= dfSynGen[!, :Max_Energy_Cap_tonne][y]
    )

    # Constraint on minimum energy capacity (if applicable) [set input to -1 if no constraint on minimum energy apacity]
    # DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MWh is <= Min_Cap_MWh and lead to infeasabilty
    @constraint(
        EP,
        cMinCapSYNEnergy[y in intersect(
            dfSynGen[dfSynGen.Min_Energy_Cap_tonne.>0, :R_ID],
            SYN_STOR_ALL,
        )],
        eSynTotalCapEnergy[y] >= dfSynGen[!, :Min_Energy_Cap_tonne][y]
    )

    return EP
end

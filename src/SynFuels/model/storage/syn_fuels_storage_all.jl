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
    syn_fuels_storage_all(EP::Model, inputs::Dict, setup::Dict)

This module defines the basic decision variables and common expressions related to hydrogen storage, incluidng storage level and charging
capability.

"""
function syn_fuels_storage_all(EP::Model, inputs::Dict, setup::Dict)
    # Setup variables, constraints, and expressions common to all hydrogen storage resources
    println("Synthesis Fuels Storage Core Resources Module")

    dfSynGen = inputs["dfSynGen"]
    SYN_STOR_ALL = inputs["SYN_STOR_ALL"] # Set of all h2 storage resources

    Z = inputs["Z"]     # Number of zones
    T = inputs["T"] # Number of time steps (hours)

    START_SUBPERIODS = inputs["START_SUBPERIODS"] # Starting subperiod index for each representative period
    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"] # Index of interior subperiod for each representative period

    hours_per_subperiod = inputs["hours_per_subperiod"] #total number of hours per subperiod

    ### Variables ###
    # Storage level of resource "y" at hour "t" [tonne] on zone "z"
    @variable(EP, vSynS[y in SYN_STOR_ALL, t = 1:T] >= 0)

    # Rate of energy withdrawn from HSC by resource "y" at hour "t" [tonne/hour] on zone "z"
    @variable(EP, vSyn_CHARGE_STOR[y in SYN_STOR_ALL, t = 1:T] >= 0)

    # Energy losses related to storage technologies (increase in effective demand)
    #@expression(EP, eEH2LOSS[y in SYN_STOR_ALL], sum(inputs["omega"][t]*EP[:vH2_CHARGE_STOR][y,t] for t in 1:T) - sum(inputs["omega"][t]*EP[:vH2Gen][y,t] for t in 1:T))

    #Variable costs of "charging" for technologies "y" during hour "t" in zone "z"
    #  ParameterScale = 1 --> objective function is in million $
    #  ParameterScale = 0 --> objective function is in $
    if setup["ParameterScale"] == 1
        @expression(
            EP,
            eCVarSynStor_in[y in SYN_STOR_ALL, t = 1:T],
            if (dfSynGen[!, :SynStor_Charge_MMBtu_p_tonne][y] > 0) # Charging consumes fuel - fuel divided by 1000 since fuel cost already scaled in load_fuels_data.jl when ParameterScale =1
                inputs["omega"][t] *
                dfSynGen[!, :Var_OM_Cost_Charge_p_tonne][y] *
                vSyn_CHARGE_STOR[y, t] / ModelScalingFactor^2 +
                inputs["fuel_costs"][dfSynGen[!, :Fuel][k]][t] *
                dfSynGen[!, :SynStor_Charge_MMBtu_p_tonne][k] *
                vSyn_CHARGE_STOR[y, t] / ModelScalingFactor
            else
                inputs["omega"][t] *
                dfSynGen[!, :Var_OM_Cost_Charge_p_tonne][y] *
                vSyn_CHARGE_STOR[y, t] / ModelScalingFactor^2
            end
        )
    else
        @expression(
            EP,
            eCVarSynStor_in[y in SYN_STOR_ALL, t = 1:T],
            if (dfSynGen[!, :SynStor_Charge_MMBtu_p_tonne][y] > 0) # Charging consumes fuel
                inputs["omega"][t] *
                dfSynGen[!, :Var_OM_Cost_Charge_p_tonne][y] *
                vSyn_CHARGE_STOR[y, t] +
                inputs["fuel_costs"][dfSynGen[!, :Fuel][k]][t] *
                dfSynGen[!, :SynStor_Charge_MMBtu_p_tonne][k]
            else
                inputs["omega"][t] *
                dfSynGen[!, :Var_OM_Cost_Charge_p_tonne][y] *
                vSyn_CHARGE_STOR[y, t]
            end
        )
    end

    # Sum individual resource contributions to variable charging costs to get total variable charging costs
    @expression(
        EP,
        eTotalCVarSynStorInT[t = 1:T],
        sum(eCVarSynStor_in[y, t] for y in SYN_STOR_ALL)
    )
    @expression(EP, eTotalCVarSynStorIn, sum(eTotalCVarSynStorInT[t] for t = 1:T))
    EP[:eObj] += eTotalCVarSynStorIn


    # Term to represent electricity consumption associated with H2 storage charging and discharging
    @expression(
        EP,
        ePowerBalanceSynStor[t = 1:T, z = 1:Z],
        if setup["ParameterScale"] == 1 # If ParameterScale = 1, power system operation/capacity modeled in GW rather than MW
            sum(
                EP[:vSyn_CHARGE_STOR][y, t] * dfSynGen[!, :SynStor_Charge_MWh_p_tonne][y] /
                ModelScalingFactor for
                y in intersect(dfSynGen[dfSynGen.Zone.==z, :R_ID], SYN_STOR_ALL);
                init = 0.0,
            )
        else
            sum(
                EP[:vSyn_CHARGE_STOR][y, t] * dfSynGen[!, :SynStor_Charge_MWh_p_tonne][y]
                for y in intersect(dfSynGen[dfSynGen.Zone.==z, :R_ID], SYN_STOR_ALL);
                init = 0.0,
            )
        end
    )

    EP[:ePowerBalance] += -ePowerBalanceSynStor

    # Adding power consumption by storage
    EP[:eSynNetpowerConsumptionByAll] += ePowerBalanceSynStor

    # H2 Balance expressions
    @expression(
        EP,
        eSynBalanceStor[t = 1:T, z = 1:Z],
        sum(
            EP[:vSynGen][y, t] - EP[:vSyn_CHARGE_STOR][y, t] for
            y in intersect(SYN_STOR_ALL, dfSynGen[dfSynGen[!, :Zone].==z, :][!, :R_ID])
        )
    )

    EP[:eSynBalance] += eSynBalanceStor

    ### End Expressions ###

    ### Constraints ###
    ## Storage energy capacity and state of charge related constraints:

    # Links state of charge in first time step with decisions in last time step of each subperiod
    # We use a modified formulation of this constraint (cSoCBalLongDurationStorageStart) when operations wrapping and long duration storage are being modeled

    if setup["OperationWrapping"] == 1 && !isempty(inputs["SYN_STOR_LONG_DURATION"]) # Apply constraints to those storage technologies with short duration only
        @constraint(
            EP,
            cSynSoCBalStart[t in START_SUBPERIODS, y in SYN_STOR_SHORT_DURATION],
            EP[:vSynS][y, t] ==
            EP[:vSynS][y, t+hours_per_subperiod-1] -
            (1 / dfSynGen[!, :SynStor_eff_discharge][y] * EP[:vSynGen][y, t]) +
            (dfSynGen[!, :SynStor_eff_charge][y] * EP[:vSyn_CHARGE_STOR][y, t]) - (
                dfSynGen[!, :SynStor_self_discharge_rate_p_hour][y] *
                EP[:vSynS][y, t+hours_per_subperiod-1]
            )
        )
    else # Apply constraints to all storage technologies
        @constraint(
            EP,
            cSynSoCBalStart[t in START_SUBPERIODS, y in SYN_STOR_ALL],
            EP[:vSynS][y, t] ==
            EP[:vSynS][y, t+hours_per_subperiod-1] -
            (1 / dfSynGen[!, :SynStor_eff_discharge][y] * EP[:vSynGen][y, t]) +
            (dfSynGen[!, :SynStor_eff_charge][y] * EP[:vSyn_CHARGE_STOR][y, t]) - (
                dfSynGen[!, :SynStor_self_discharge_rate_p_hour][y] *
                EP[:vSynS][y, t+hours_per_subperiod-1]
            )
        )
    end

    @constraints(
        EP,
        begin

            [y in SYN_STOR_ALL, t in 1:T],
            EP[:eSynTotalCapEnergy][y] * dfSynGen[!, :SynStor_max_level][y] >=
            EP[:vSynS][y, t]
            [y in SYN_STOR_ALL, t in 1:T],
            EP[:eSynTotalCapEnergy][y] * dfSynGen[!, :SynStor_min_level][y] <=
            EP[:vSynS][y, t]

            # energy stored for the next hour
            cSynSoCBalInterior[t in INTERIOR_SUBPERIODS, y in SYN_STOR_ALL],
            EP[:vSynS][y, t] ==
            EP[:vSynS][y, t-1] -
            (1 / dfSynGen[!, :SynStor_eff_discharge][y] * EP[:vSynGen][y, t]) +
            (dfSynGen[!, :SynStor_eff_charge][y] * EP[:vSyn_CHARGE_STOR][y, t]) -
            (dfSynGen[!, :SynStor_self_discharge_rate_p_hour][y] * EP[:vSynS][y, t-1])
        end
    )

    ### End Constraints ###
    return EP
end

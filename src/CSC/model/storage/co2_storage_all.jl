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
    co2_storage_all(EP::Model, inputs::Dict, setup::Dict)

This module defines the basic decision variables and common expressions related to carbon storage, incluidng storage level and charging
capability.

"""

function co2_storage_all(EP::Model, inputs::Dict, setup::Dict)
    # Setup variables, constraints, and expressions common to all carbon storage resources
    println("CO2 Storage Core Resources Module")

    dfCO2Stor = inputs["dfCO2Stor"]
    CO2_STOR_ALL = inputs["CO2_STOR_ALL"] # Set of all co2 storage resources

    Z = inputs["Z"]     # Number of zones
    T = inputs["T"] # Number of time steps (hours) 


    START_SUBPERIODS = inputs["START_SUBPERIODS"] # Starting subperiod index for each representative period
    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"] # Index of interior subperiod for each representative period

    hours_per_subperiod = inputs["hours_per_subperiod"] #total number of hours per subperiod

    ### Variables ###
    # Storage level of resource "y" at hour "t" [tonne] on zone "z" 
    @variable(EP, vCO2S[y in CO2_STOR_ALL, t = 1:T] >= 0)

    # Rate of carbon withdrawn from CSC by resource "y" at hour "t" [tonne/hour] on zone "z"
    @variable(EP, vCO2CHARGE_STOR[y in CO2_STOR_ALL, t = 1:T] >= 0)
    @variable(EP, vCO2DISCHARGE_STOR[y in CO2_STOR_ALL, t = 1:T] >= 0)
    # Carbon losses related to storage technologies (increase in effective demand)
    #@expression(EP, eECO2LOSS[y in CO2_STOR_ALL], sum(inputs["omega"][t]*EP[:vCO2CHARGE_STOR][y,t] for t in 1:T) )

    #Variable costs of "charging" for technologies "y" during hour "t" in zone "z"
    #  ParameterScale = 1 --> objective function is in million $
    #  ParameterScale = 0 --> objective function is in $
    if setup["ParameterScale"] == 1
        @expression(
            EP,
            eCVarCO2Stor_in[y in CO2_STOR_ALL, t = 1:T],
            if (dfCO2Stor[!, :CO2Stor_Charge_MMBtu_p_tonne][y] > 0) # Charging consumes fuel - fuel divided by 1000 since fuel cost already scaled in load_fuels_data.jl when ParameterScale =1
                inputs["omega"][t] *
                dfCO2Stor[!, :Var_OM_Cost_Charge_p_tonne][y] *
                (vCO2CHARGE_STOR[y, t] + vCO2DISCHARGE_STOR[y, t]) / ModelScalingFactor^2 +
                inputs["fuel_costs"][dfCO2Stor[!, :Fuel][y]][t] *
                dfCO2Stor[!, :CO2Stor_Charge_MMBtu_p_tonne][y] *
                vCO2CHARGE_STOR[y, t] / ModelScalingFactor
            else
                inputs["omega"][t] *
                dfCO2Stor[!, :Var_OM_Cost_Charge_p_tonne][y] *
                (vCO2CHARGE_STOR[y, t] + vCO2DISCHARGE_STOR[y, t]) / ModelScalingFactor^2
            end
        )
    else
        @expression(
            EP,
            eCVarCO2Stor_in[y in CO2_STOR_ALL, t = 1:T],
            if (dfCO2Stor[!, :CO2Stor_Charge_MMBtu_p_tonne][y] > 0) # Charging consumes fuel 
                inputs["omega"][t] *
                dfCO2Stor[!, :Var_OM_Cost_Charge_p_tonne][y] *
                (vCO2CHARGE_STOR[y, t] + vCO2DISCHARGE_STOR[y, t]) +
                inputs["fuel_costs"][dfCO2Stor[!, :Fuel][y]][t] *
                dfCO2Stor[!, :CO2Stor_Charge_MMBtu_p_tonne][y]
            else
                inputs["omega"][t] *
                dfCO2Stor[!, :Var_OM_Cost_Charge_p_tonne][y] *
                (vCO2CHARGE_STOR[y, t] + vCO2DISCHARGE_STOR[y, t])
            end
        )
    end

    # Sum individual resource contributions to variable charging costs to get total variable charging costs
    @expression(
        EP,
        eTotalCVarCO2StorInT[t = 1:T],
        sum(eCVarCO2Stor_in[y, t] for y in CO2_STOR_ALL)
    )
    @expression(EP, eTotalCVarCO2Stor, sum(eTotalCVarCO2StorInT[t] for t = 1:T))
    EP[:eObj] += eTotalCVarCO2Stor


    # Term to represent electricity consumption associated with CO2 storage charging and discharging
    @expression(
        EP,
        ePowerBalanceCO2Stor[t = 1:T, z = 1:Z],
        if setup["ParameterScale"] == 1 # If ParameterScale = 1, power system operation/capacity modeled in GW rather than MW 
            sum(
                EP[:vCO2CHARGE_STOR][y, t] * dfCO2Stor[!, :CO2Stor_Charge_MWh_p_tonne][y] /
                ModelScalingFactor for
                y in intersect(dfCO2Stor[dfCO2Stor.Zone.==z, :R_ID], CO2_STOR_ALL);
                init = 0.0,
            )
        else
            sum(
                EP[:vCO2CHARGE_STOR][y, t] * dfCO2Stor[!, :CO2Stor_Charge_MWh_p_tonne][y]
                for y in intersect(dfCO2Stor[dfCO2Stor.Zone.==z, :R_ID], CO2_STOR_ALL);
                init = 0.0,
            )
        end
    )

    EP[:ePowerBalance] += -ePowerBalanceCO2Stor

    # Adding power consumption by storage
    EP[:eCO2NetpowerConsumptionByAll] += ePowerBalanceCO2Stor


    #CO2 Balance expressions
    @expression(
        EP,
        eCO2BalanceStor[t = 1:T, z = 1:Z],
        sum(
            EP[:vCO2DISCHARGE_STOR][k, t] / dfCO2Stor[!, :CO2Stor_eff_charge][k] -
            EP[:vCO2CHARGE_STOR][k, t] * dfCO2Stor[!, :CO2Stor_eff_charge][k] for
            k in intersect(CO2_STOR_ALL, dfCO2Stor[dfCO2Stor[!, :Zone].==z, :][!, :R_ID])
        )
    )

    #Activate only when CO2 demand is online
    EP[:eCO2Balance] += eCO2BalanceStor

    ### End Expressions ###

    ### Constraints ###
    ## Storage carbon capacity and state of charge related constraints:

    # Links state of charge in first time step with decisions in last time step of each subperiod
    # We use a modified formulation of this constraint (cSoCBalLongDurationStorageStart) when operations wrapping and long duration storage are being modeled

    if setup["OperationWrapping"] == 1 && !isempty(inputs["CO2_STOR_LONG_DURATION"]) # Apply constraints to those storage technologies with short duration only
        @constraint(
            EP,
            cCO2SoCBalStart[t in START_SUBPERIODS, y in CO2_STOR_SHORT_DURATION],
            EP[:vCO2S][y, t] ==
            EP[:vCO2S][y, t+hours_per_subperiod-1] + (
                dfCO2Stor[!, :CO2Stor_eff_charge][y] * EP[:vCO2CHARGE_STOR][y, t] -
                EP[:vCO2DISCHARGE_STOR][y, t] / dfCO2Stor[!, :CO2Stor_eff_charge][y]
            )
        )

    else # Apply constraints to all storage technologies
        @constraint(
            EP,
            cCO2SoCBalStart[t in START_SUBPERIODS, y in CO2_STOR_ALL],
            EP[:vCO2S][y, t] ==
            EP[:vCO2S][y, t+hours_per_subperiod-1] + (
                dfCO2Stor[!, :CO2Stor_eff_charge][y] * EP[:vCO2CHARGE_STOR][y, t] -
                EP[:vCO2DISCHARGE_STOR][y, t] / dfCO2Stor[!, :CO2Stor_eff_charge][y]
            )
        )
    end

    @constraints(
        EP,
        begin
            # Max and min storage inventory levels as proportion installed storage carbon capacity
            [y in CO2_STOR_ALL, t in 1:T],
            EP[:eTotalCO2CapCarbon][y] * dfCO2Stor[!, :CO2Stor_max_level][y] >=
            EP[:vCO2S][y, t]
            [y in CO2_STOR_ALL, t in 1:T],
            EP[:eTotalCO2CapCarbon][y] * dfCO2Stor[!, :CO2Stor_min_level][y] <=
            EP[:vCO2S][y, t]

            # Maximum charging rate constrained by charging capacity
            [y in CO2_STOR_ALL, t in 1:T],
            EP[:vCO2CHARGE_STOR][y, t] <= EP[:eTotalCO2CapCharge][y]
            # Minimum charging rate constrained by charging capacity
            [y in CO2_STOR_ALL, t in 1:T],
            EP[:vCO2DISCHARGE_STOR][y, t] <= EP[:eTotalCO2CapCharge][y]

            # Carbon stored for the next hour
            cCO2SoCBalInterior[t in INTERIOR_SUBPERIODS, y in CO2_STOR_ALL],
            EP[:vCO2S][y, t] ==
            EP[:vCO2S][y, t-1] + (
                dfCO2Stor[!, :CO2Stor_eff_charge][y] * EP[:vCO2CHARGE_STOR][y, t] -
                EP[:vCO2DISCHARGE_STOR][y, t] / dfCO2Stor[!, :CO2Stor_eff_charge][y]
            )
        end
    )

    ### End Constraints ###
    return EP
end

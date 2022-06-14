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
    co2_pipeline(EP::Model, inputs::Dict, setup::Dict)

This module defines the variables and constraints with carbon transimission via pipelines.
 
"""

function co2_pipeline(EP::Model, inputs::Dict, setup::Dict)

    println("Carbon Pipeline Module")

    T = inputs["T"] # Model operating time steps
    Z = inputs["Z"]  # Model demand zones - assumed to be same for H2 and electricity

    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
    START_SUBPERIODS = inputs["START_SUBPERIODS"]
    hours_per_subperiod = inputs["hours_per_subperiod"]

    CO2_P = inputs["CO2_P"] # Number of Hydrogen Pipelines
    CO2_Pipe_Map = inputs["CO2_Pipe_Map"]

    ### Variables ###
    @variable(EP, vCO2NPipe[p = 1:CO2_P] >= 0) # Number of Pipes
    @variable(EP, vCO2PipeLevel[p = 1:CO2_P, t = 1:T] >= 0) # Storage in the pipe
    @variable(EP, vCO2PipeFlow_pos[p = 1:CO2_P, t = 1:T, d = [1, -1]] >= 0) # positive pipeflow
    @variable(EP, vCO2PipeFlow_neg[p = 1:CO2_P, t = 1:T, d = [1, -1]] >= 0) # negative pipeflow


    ### Expressions ###
    # Calculate the number of new pipes
    @expression(EP, eCO2NPipeNew[p = 1:CO2_P], vCO2NPipe[p] - inputs["pCO2_Pipe_No_Curr"][p])

    # Calculate net flow at each pipe-zone interfrace
    @expression(
        EP,
        eCO2PipeFlow_net[p = 1:CO2_P, t = 1:T, d = [-1, 1]],
        vCO2PipeFlow_pos[p, t, d] - vCO2PipeFlow_neg[p, t, d]
    )

    ## Objective Function Expressions ##
    # Capital cost of pipelines 
    # DEV NOTE: To add fixed cost of existing + new pipelines
    #  ParameterScale = 1 --> objective function is in million $
    #  ParameterScale = 0 --> objective function is in $
    if setup["ParameterScale"] == 1
        @expression(
            EP,
            eCCO2Pipe,
            sum(
                eCO2NPipeNew[p] * inputs["pCAPEX_CO2_Pipe"][p] / (ModelScalingFactor)^2 for
                p = 1:CO2_P
            )
        )
    else
        @expression(
            EP,
            eCCO2Pipe,
            sum(eCO2NPipeNew[p] * inputs["pCAPEX_CO2_Pipe"][p] for p = 1:CO2_P)
        )
    end

    EP[:eObj] += eCCO2Pipe

    # Capital cost of booster compressors located along each pipeline - more booster compressors needed for longer pipelines than shorter pipelines
    # YS Formula doesn't make sense to me
    #  ParameterScale = 1 --> objective function is in million $
    #  ParameterScale = 0 --> objective function is in $
    if setup["ParameterScale"] == 1
        @expression(
            EP,
            eCCO2CompPipe,
            sum(eCO2NPipeNew[p] * inputs["pCAPEX_Comp_CO2_Pipe"][p] for p = 1:CO2_P) / ModelScalingFactor^2
        )
    else
        @expression(
            EP,
            eCCO2CompPipe,
            sum(eCO2NPipeNew[p] * inputs["pCAPEX_Comp_CO2_Pipe"][p] for p = 1:CO2_P)
        )
    end

    EP[:eObj] += eCCO2CompPipe

    ## End Objective Function Expressions ##

    ## Balance Expressions ##
    # CO2 PowCOr Consumption COalanCOe

    if setup["ParameterScale"] == 1 # IF ParameterScale = 1, power system operation/capacity modeled in GW rather than MW 
        @expression(
            EP,
            ePowerBalanceCO2PipeCompression[t = 1:T, z = 1:Z],
            sum(
                vCO2PipeFlow_neg[
                    p, t, CO2_Pipe_Map[(CO2_Pipe_Map[!, :Zone].==z).&(CO2_Pipe_Map[!, :pipe_no].==p), :,][!,:d][1]
                ] * inputs["pComp_MWh_per_tonne_Pipe"][p] for p in CO2_Pipe_Map[CO2_Pipe_Map[!, :Zone].==z, :][!, :pipe_no]
            ) / ModelScalingFactor
        )
    else # IF ParameterScale = 0, power system operation/capacity modeled in MW so no scaling of H2 related power consumption
        @expression(
            EP,
            ePowerBalanceCO2PipeCompression[t = 1:T, z = 1:Z],
            sum(
                vCO2PipeFlow_neg[
                    p, t, CO2_Pipe_Map[(CO2_Pipe_Map[!, :Zone].==z).&(CO2_Pipe_Map[!, :pipe_no].==p), :,][!,:d][1]
                ] * inputs["pComp_MWh_per_tonne_Pipe"][p] for p in CO2_Pipe_Map[CO2_Pipe_Map[!, :Zone].==z, :][!, :pipe_no]
            )
        )
    end

    EP[:ePowerBalance] += -ePowerBalanceCO2PipeCompression


    ## DEV NOTE: YS to add  power consumption by storage to right hand side of CO2 Polcy constraint using the following scripts - power consumption by pipeline compression in zone and each time step
    # if setup["ParameterScale"]==1 # Power consumption in GW
    # 	@expression(EP, eH2PowerConsumptionByPipe[z=1:Z, t=1:T], 
    # 	sum(EP[:vH2_CHARGE_STOR][y,t]*dfH2Gen[!,:H2Stor_Charge_MWh_p_tonne][y]/ModelScalingFactor for y in intersect(inputs["H2_STOR_ALL"], dfH2Gen[dfH2Gen[!,:Zone].==z,:R_ID])))

    # else  # Power consumption in MW
    # 	@expression(EP, eH2PowerConsumptionByPipe[z=1:Z, t=1:T], 
    # 	sum(EP[:vH2_CHARGE_STOR][y,t]*dfH2Gen[!,:H2Stor_Charge_MWh_p_tonne][y] for y in intersect(inputs["H2_STOR_ALL"], dfH2Gen[dfH2Gen[!,:Zone].==z,:R_ID])))

    # end

    # Adding power consumption by storage and pipelines
    #EP[:eH2NetpowerConsumptionByAll] += eH2PowerConsumptionByPipe


    # H2 balance - net flows of H2 from between z and zz via pipeline p over time period t
    @expression(
        EP,
        eCO2PipeZoneDemand[t = 1:T, z = 1:Z],
        sum(
            eCO2PipeFlow_net[p, t, CO2_Pipe_Map[(CO2_Pipe_Map[!, :Zone].==z).&(CO2_Pipe_Map[!, :pipe_no].==p), :][!,:d][1]] 
            for p in CO2_Pipe_Map[CO2_Pipe_Map[!, :Zone].==z, :][!, :pipe_no]
        )
    )

    EP[:eCO2Balance] += eCO2PipeZoneDemand

    ## End Balance Expressions ##
    ### End Expressions ###

    ### Constraints ###

    # Constraints
    if setup["CO2PipeInteger"] == 1
        for p = 1:CO2_P
            set_integer.(vCO2NPipe[p])
        end
    end

    # Modeling expansion of the pipleline network
    if setup["CO2NetworkExpansion"] == 1
        # If network expansion allowed Total no. of Pipes >= Existing no. of Pipe 
        @constraints(EP, begin
            [p in 1:CO2_P], EP[:eCO2NPipeNew][p] >= 0
        end)
    else
        # If network expansion is not alllowed Total no. of Pipes == Existing no. of Pipe 
        @constraints(EP, begin
            [p in 1:CO2_P], EP[:eCO2NPipeNew][p] == 0
        end)
    end

    # Constraint maximum pipe flow
    @constraints(
        EP,
        begin
            [p in 1:CO2_P, t = 1:T, d in [-1, 1]],
            EP[:eCO2PipeFlow_net][p, t, d] <=
            EP[:vCO2NPipe][p] * inputs["pCO2_Pipe_Max_Flow"][p]
            [p in 1:CO2_P, t = 1:T, d in [-1, 1]],
            -EP[:eCO2PipeFlow_net][p, t, d] <=
            EP[:vCO2NPipe][p] * inputs["pCO2_Pipe_Max_Flow"][p]
        end
    )

    # Constrain positive and negative pipe flows
    @constraints(
        EP,
        begin
            [p in 1:CO2_P, t = 1:T, d in [-1, 1]],
            vCO2NPipe[p] * inputs["pCO2_Pipe_Max_Flow"][p] >= vCO2PipeFlow_pos[p, t, d]
            [p in 1:CO2_P, t = 1:T, d in [-1, 1]],
            vCO2NPipe[p] * inputs["pCO2_Pipe_Max_Flow"][p] >= vCO2PipeFlow_neg[p, t, d]
        end
    )

    # Minimum and maximum pipe level constraint
    @constraints(
        EP,
        begin
            [p in 1:CO2_P, t = 1:T],
            vCO2PipeLevel[p, t] >= inputs["pCO2_Pipe_Min_Cap"][p] * vCO2NPipe[p]
            [p in 1:CO2_P, t = 1:T],
            inputs["pCO2_Pipe_Max_Cap"][p] * vCO2NPipe[p] >= vCO2PipeLevel[p, t]
        end
    )

    # Pipeline storage level change
    @constraints(
        EP,
        begin
            [p in 1:CO2_P, t in START_SUBPERIODS],
            vCO2PipeLevel[p, t] ==
            vCO2PipeLevel[p, t+hours_per_subperiod-1] - eCO2PipeFlow_net[p, t, -1] -
            eCO2PipeFlow_net[p, t, 1]
        end
    )

    @constraints(
        EP,
        begin
            [p in 1:CO2_P, t in INTERIOR_SUBPERIODS],
            vCO2PipeLevel[p, t] ==
            vCO2PipeLevel[p, t-1] - eCO2PipeFlow_net[p, t, -1] - eCO2PipeFlow_net[p, t, 1]
        end
    )

    @constraints(EP, begin
        [p in 1:CO2_P], vCO2NPipe[p] <= inputs["pCO2_Pipe_No_Max"][p]
    end)

    return EP
end # end pipeline module in carbon sector

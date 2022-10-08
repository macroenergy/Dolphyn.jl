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
    syn_fuels_production_commit(EP::Model, inputs::Dict, UCommit::Int, Reserves::Int)

The h2_generation module creates decision variables, expressions, and constraints related to various hydrogen generation technologies with unit commitment constraints (e.g. natural gas reforming etc.)

Documentation to follow ******
"""
function syn_fuels_production_commit(EP::Model, inputs::Dict, setup::Dict)

    println("Synthesis Fuels Production (Unit Commitment) Module")

    # Rename SynGen dataframe
    dfSynGen = inputs["dfSynGen"]

    T = inputs["T"]     # Number of time steps (hours)
    Z = inputs["Z"]     # Number of zones

    SYN_GEN_COMMIT = inputs["SYN_GEN_COMMIT"]
    SYN_GEN_NEW_CAP = inputs["SYN_GEN_NEW_CAP"]
    SYN_GEN_RET_CAP = inputs["SYN_GEN_RET_CAP"]

    #Define start subperiods and interior subperiods
    START_SUBPERIODS = inputs["START_SUBPERIODS"]
    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
    hours_per_subperiod = inputs["hours_per_subperiod"] #total number of hours per subperiod

    ###Variables###

    # commitment state variable
    @variable(EP, vSynGenCOMMIT[k in SYN_GEN_COMMIT, t = 1:T] >= 0)
    # Start up variable
    @variable(EP, vSynGenStart[k in SYN_GEN_COMMIT, t = 1:T] >= 0)
    # Shutdown Variable
    @variable(EP, vSynGenShut[k in SYN_GEN_COMMIT, t = 1:T] >= 0)

    ###Expressions###

    #Objective function expressions
    # Startup costs of "generation" for resource "y" during hour "t"
    #  ParameterScale = 1 --> objective function is in million $
    #  ParameterScale = 0 --> objective function is in $
    if setup["ParameterScale"] == 1
        @expression(
            EP,
            eSynGenCStart[k in SYN_GEN_COMMIT, t = 1:T],
            (
                inputs["omega"][t] * inputs["C_Syn_Start"][k] * vSynGenStart[k, t] /
                ModelScalingFactor^2
            )
        )
    else
        @expression(
            EP,
            eSynGenCStart[k in SYN_GEN_COMMIT, t = 1:T],
            (inputs["omega"][t] * inputs["C_Syn_Start"][k] * vSynGenStart[k, t])
        )
    end

    # Julia is fastest when summing over one row one column at a time
    @expression(
        EP,
        eTotalSynGenCStartT[t = 1:T],
        sum(eSynGenCStart[k, t] for k in SYN_GEN_COMMIT)
    )
    @expression(EP, eTotalSynGenCStart, sum(eTotalSynGenCStartT[t] for t = 1:T))

    EP[:eObj] += eTotalSynGenCStart

    # Synthesis fuels balance expressions
    @expression(
        EP,
        eSynGenCommit[t = 1:T, z = 1:Z],
        sum(
            EP[:vSynGen][k, t] for
            k in intersect(SYN_GEN_COMMIT, dfSynGen[dfSynGen[!, :Zone].==z, :][!, :R_ID])
        )
    )

    EP[:eSynBalance] += eSynGenCommit

    # Power Consumption for Syn Generation
    if setup["ParameterScale"] == 1 # IF ParameterScale = 1, power system operation/capacity modeled in GW rather than MW
        @expression(
            EP,
            ePowerBalanceSynGenCommit[t = 1:T, z = 1:Z],
            sum(
                EP[:vP2F][k, t] / ModelScalingFactor for k in
                intersect(SYN_GEN_COMMIT, dfSynGen[dfSynGen[!, :Zone].==z, :][!, :R_ID])
            )
        )
    else # IF ParameterScale = 0, power system operation/capacity modeled in MW so no scaling of Syn related power consumption
        @expression(
            EP,
            ePowerBalanceSynGenCommit[t = 1:T, z = 1:Z],
            sum(
                EP[:vP2F][k, t] for k in
                intersect(SYN_GEN_COMMIT, dfSynGen[dfSynGen[!, :Zone].==z, :][!, :R_ID])
            )
        )
    end

    EP[:ePowerBalance] += -ePowerBalanceSynGenCommit

    ##For CO2 Polcy constraint right hand side development - power consumption by zone and each time step
    EP[:eSynNetpowerConsumptionByAll] += ePowerBalanceSynGenCommit

    # Hydrogen Consumption for Syn Generation
    @expression(
        EP,
        eH2BalanceSynGenCommit[t = 1:T, z = 1:Z],
        sum(
            EP[:vP2H][k, t] for k in
            intersect(SYN_GEN_COMMIT, dfSynGen[dfSynGen[!, :Zone].==z, :][!, :R_ID])
        )
    )

    EP[:eH2Balance] += -eH2BalanceSynGenCommit

    # Carbon Consumption for Syn Generation
    @expression(
        EP,
        eCO2BalanceSynGenCommit[t = 1:T, z = 1:Z],
        sum(
            EP[:vP2C][k, t] for k in
            intersect(SYN_GEN_COMMIT, dfSynGen[dfSynGen[!, :Zone].==z, :][!, :R_ID])
        )
    )

    EP[:eCO2Balance] += -eCO2BalanceSynGenCommit

    ### Constraints ###
    ## Declaration of integer/binary variables
    if setup["SynGenCommit"] == 1 # Integer UC constraints
        for k in SYN_GEN_COMMIT
            set_integer.(vSynGenCOMMIT[k, :])
            set_integer.(vSynGenStart[k, :])
            set_integer.(vSynGenShut[k, :])
            if k in SYN_GEN_RET_CAP
                set_integer(EP[:vSynGenRetCap][k])
            end
            if k in SYN_GEN_NEW_CAP
                set_integer(EP[:vSynGenNewCap][k])
            end
        end
    end #END unit commitment configuration

    ###Constraints###
    @constraints(
        EP,
        begin
            #Power Balance
            [k in SYN_GEN_COMMIT, t = 1:T],
            EP[:vP2F][k, t] == EP[:vSynGen][k, t] * dfSynGen[!, :etaP2F_MWh_p_tonne][k]
        end
    )

    ### Capacitated limits on unit commitment decision variables (Constraints #1-3)
    @constraints(
        EP,
        begin
            [k in SYN_GEN_COMMIT, t = 1:T],
            EP[:vSynGenCOMMIT][k, t] <=
            EP[:eSynGenTotalCap][k] / dfSynGen[!, :Cap_Size_tonne_p_hr][k]
            [k in SYN_GEN_COMMIT, t = 1:T],
            EP[:vSynGenStart][k, t] <=
            EP[:eSynGenTotalCap][k] / dfSynGen[!, :Cap_Size_tonne_p_hr][k]
            [k in SYN_GEN_COMMIT, t = 1:T],
            EP[:vSynGenShut][k, t] <=
            EP[:eSynGenTotalCap][k] / dfSynGen[!, :Cap_Size_tonne_p_hr][k]
        end
    )

    # Commitment state constraint linking startup and shutdown decisions (Constraint #4)
    @constraints(
        EP,
        begin
            # For Start Hours, links first time step with last time step in subperiod
            [k in SYN_GEN_COMMIT, t in START_SUBPERIODS],
            EP[:vSynGenCOMMIT][k, t] ==
            EP[:vSynGenCOMMIT][k, (t+hours_per_subperiod-1)] + EP[:vSynGenStart][k, t] -
            EP[:vSynGenShut][k, t]
            # For all other hours, links commitment state in hour t with commitment state in prior hour + sum of start up and shut down in current hour
            [k in SYN_GEN_COMMIT, t in INTERIOR_SUBPERIODS],
            EP[:vSynGenCOMMIT][k, t] ==
            EP[:vSynGenCOMMIT][k, t-1] + EP[:vSynGenStart][k, t] - EP[:vSynGenShut][k, t]
        end
    )


    ### Maximum ramp up and down between consecutive hours (Constraints #5-6)

    ## For Start Hours
    # Links last time step with first time step, ensuring position in hour 1 is within eligible ramp of final hour position
    # rampup constraints
    @constraint(
        EP,
        [k in SYN_GEN_COMMIT, t in START_SUBPERIODS],
        EP[:vSynGen][k, t] - EP[:vSynGen][k, (t+hours_per_subperiod-1)] <=
        dfSynGen[!, :Ramp_Up_Percentage][k] *
        dfSynGen[!, :Cap_Size_tonne_p_hr][k] *
        (EP[:vSynGenCOMMIT][k, t] - EP[:vSynGenStart][k, t]) +
        min(
            inputs["pSyn_Max"][k, t],
            max(dfSynGen[!, :SynGen_min_output][k], dfSynGen[!, :Ramp_Up_Percentage][k]),
        ) *
        dfSynGen[!, :Cap_Size_tonne_p_hr][k] *
        EP[:vSynGenStart][k, t] -
        dfSynGen[!, :SynGen_min_output][k] *
        dfSynGen[!, :Cap_Size_tonne_p_hr][k] *
        EP[:vSynGenShut][k, t]
    )

    # rampdown constraints
    @constraint(
        EP,
        [k in SYN_GEN_COMMIT, t in START_SUBPERIODS],
        EP[:vSynGen][k, (t+hours_per_subperiod-1)] - EP[:vSynGen][k, t] <=
        dfSynGen[!, :Ramp_Down_Percentage][k] *
        dfSynGen[!, :Cap_Size_tonne_p_hr][k] *
        (EP[:vSynGenCOMMIT][k, t] - EP[:vSynGenStart][k, t]) -
        dfSynGen[!, :SynGen_min_output][k] *
        dfSynGen[!, :Cap_Size_tonne_p_hr][k] *
        EP[:vSynGenStart][k, t] +
        min(
            inputs["pSyn_Max"][k, t],
            max(dfSynGen[!, :SynGen_min_output][k], dfSynGen[!, :Ramp_Down_Percentage][k]),
        ) *
        dfSynGen[!, :Cap_Size_tonne_p_hr][k] *
        EP[:vSynGenShut][k, t]
    )

    ## For Interior Hours
    # rampup constraints
    @constraint(
        EP,
        [k in SYN_GEN_COMMIT, t in INTERIOR_SUBPERIODS],
        EP[:vSynGen][k, t] - EP[:vSynGen][k, t-1] <=
        dfSynGen[!, :Ramp_Up_Percentage][k] *
        dfSynGen[!, :Cap_Size_tonne_p_hr][k] *
        (EP[:vSynGenCOMMIT][k, t] - EP[:vSynGenStart][k, t]) +
        min(
            inputs["pSyn_Max"][k, t],
            max(dfSynGen[!, :SynGen_min_output][k], dfSynGen[!, :Ramp_Up_Percentage][k]),
        ) *
        dfSynGen[!, :Cap_Size_tonne_p_hr][k] *
        EP[:vSynGenStart][k, t] -
        dfSynGen[!, :SynGen_min_output][k] *
        dfSynGen[!, :Cap_Size_tonne_p_hr][k] *
        EP[:vSynGenShut][k, t]
    )

    # rampdown constraints
    @constraint(
        EP,
        [k in SYN_GEN_COMMIT, t in INTERIOR_SUBPERIODS],
        EP[:vSynGen][k, t-1] - EP[:vSynGen][k, t] <=
        dfSynGen[!, :Ramp_Down_Percentage][k] *
        dfSynGen[!, :Cap_Size_tonne_p_hr][k] *
        (EP[:vSynGenCOMMIT][k, t] - EP[:vSynGenStart][k, t]) -
        dfSynGen[!, :SynGen_min_output][k] *
        dfSynGen[!, :Cap_Size_tonne_p_hr][k] *
        EP[:vSynGenStart][k, t] +
        min(
            inputs["pSyn_Max"][k, t],
            max(dfSynGen[!, :SynGen_min_output][k], dfSynGen[!, :Ramp_Down_Percentage][k]),
        ) *
        dfSynGen[!, :Cap_Size_tonne_p_hr][k] *
        EP[:vSynGenShut][k, t]
    )

    @constraints(
        EP,
        begin
            # Minimum stable generated per technology "k" at hour "t" > = Min stable output level
            [k in SYN_GEN_COMMIT, t = 1:T],
            EP[:vSynGen][k, t] >=
            dfSynGen[!, :Cap_Size_tonne_p_hr][k] *
            dfSynGen[!, :SynGen_min_output][k] *
            EP[:vSynGenCOMMIT][k, t]
            # Maximum power generated per technology "k" at hour "t" < Max power
            [k in SYN_GEN_COMMIT, t = 1:T],
            EP[:vSynGen][k, t] <=
            dfSynGen[!, :Cap_Size_tonne_p_hr][k] *
            EP[:vSynGenCOMMIT][k, t] *
            inputs["pSyn_Max"][k, t]
        end
    )


    ### Minimum up and down times (Constraints #9-10)
    for y in SYN_GEN_COMMIT

        ## up time
        Up_Time = Int(floor(dfSynGen[!, :Up_Time][y]))
        Up_Time_HOURS = [] # Set of hours in the summation term of the maximum up time constraint for the first subperiod of each representative period
        for s in START_SUBPERIODS
            Up_Time_HOURS = union(Up_Time_HOURS, (s+1):(s+Up_Time-1))
        end

        @constraints(
            EP,
            begin
                # cUpTimeInterior: Constraint looks back over last n hours, where n = dfSynGen[!,:Up_Time][y]
                [t in setdiff(INTERIOR_SUBPERIODS, Up_Time_HOURS)],
                EP[:vSynGenCOMMIT][y, t] >=
                sum(EP[:vSynGenStart][y, e] for e = (t-dfSynGen[!, :Up_Time][y]):t)

                # cUpTimeWrap: If n is greater than the number of subperiods left in the period, constraint wraps around to first hour of time series
                # cUpTimeWrap constraint equivalant to: sum(EP[:vSynGenStart][y,e] for e=(t-((t%hours_per_subperiod)-1):t))+sum(EP[:vSynGenStart][y,e] for e=(hours_per_subperiod_max-(dfSynGen[!,:Up_Time][y]-(t%hours_per_subperiod))):hours_per_subperiod_max)
                [t in Up_Time_HOURS],
                EP[:vSynGenCOMMIT][y, t] >=
                sum(EP[:vSynGenStart][y, e] for e in (t-((t%hours_per_subperiod)-1):t)) +
                sum(
                    EP[:vSynGenStart][y, e] for e =
                        ((t+hours_per_subperiod-(t%hours_per_subperiod))-(dfSynGen[
                            !,
                            :Up_Time,
                        ][y]-(t%hours_per_subperiod))):(t+hours_per_subperiod-(t%hours_per_subperiod))
                )

                # cUpTimeStart:
                # NOTE: Expression t+hours_per_subperiod-(t%hours_per_subperiod) is equivalant to "hours_per_subperiod_max"
                [t in START_SUBPERIODS],
                EP[:vSynGenCOMMIT][y, t] >=
                EP[:vSynGenStart][y, t] + sum(
                    EP[:vSynGenStart][y, e] for e =
                        ((t+hours_per_subperiod-1)-(dfSynGen[!, :Up_Time][y]-1)):(t+hours_per_subperiod-1)
                )
            end
        )

        ## down time
        Down_Time = Int(floor(dfSynGen[!, :Down_Time][y]))
        Down_Time_HOURS = [] # Set of hours in the summation term of the maximum down time constraint for the first subperiod of each representative period
        for s in START_SUBPERIODS
            Down_Time_HOURS = union(Down_Time_HOURS, (s+1):(s+Down_Time-1))
        end

        # Constraint looks back over last n hours, where n = dfSynGen[!,:Down_Time][y]
        # TODO: Replace LHS of constraints in this block with eNumPlantsOffline[y,t]
        @constraints(
            EP,
            begin
                # cDownTimeInterior: Constraint looks back over last n hours, where n = inputs["pDMS_Time"][y]
                [t in setdiff(INTERIOR_SUBPERIODS, Down_Time_HOURS)],
                EP[:eSynGenTotalCap][y] / dfSynGen[!, :Cap_Size_tonne_p_hr][y] -
                EP[:vSynGenCOMMIT][y, t] >=
                sum(EP[:vSynGenShut][y, e] for e = (t-dfSynGen[!, :Down_Time][y]):t)

                # cDownTimeWrap: If n is greater than the number of subperiods left in the period, constraint wraps around to first hour of time series
                # cDownTimeWrap constraint equivalant to: EP[:eSynGenTotalCap][y]/dfSynGen[!,:Cap_Size_tonne_p_hr][y]-EP[:vSynGenCOMMIT][y,t] >= sum(EP[:vSynGenShut][y,e] for e=(t-((t%hours_per_subperiod)-1):t))+sum(EP[:vSynGenShut][y,e] for e=(hours_per_subperiod_max-(dfSynGen[!,:Down_Time][y]-(t%hours_per_subperiod))):hours_per_subperiod_max)
                [t in Down_Time_HOURS],
                EP[:eSynGenTotalCap][y] / dfSynGen[!, :Cap_Size_tonne_p_hr][y] -
                EP[:vSynGenCOMMIT][y, t] >=
                sum(EP[:vSynGenShut][y, e] for e in (t-((t%hours_per_subperiod)-1):t)) +
                sum(
                    EP[:vSynGenShut][y, e] for e =
                        ((t+hours_per_subperiod-(t%hours_per_subperiod))-(dfSynGen[
                            !,
                            :Down_Time,
                        ][y]-(t%hours_per_subperiod))):(t+hours_per_subperiod-(t%hours_per_subperiod))
                )

                # cDownTimeStart:
                # NOTE: Expression t+hours_per_subperiod-(t%hours_per_subperiod) is equivalant to "hours_per_subperiod_max"
                [t in START_SUBPERIODS],
                EP[:eSynGenTotalCap][y] / dfSynGen[!, :Cap_Size_tonne_p_hr][y] -
                EP[:vSynGenCOMMIT][y, t] >=
                EP[:vSynGenShut][y, t] + sum(
                    EP[:vSynGenShut][y, e] for e =
                        ((t+hours_per_subperiod-1)-(dfSynGen[!, :Down_Time][y]-1)):(t+hours_per_subperiod-1)
                )
            end
        )
    end

    return EP

end

function syn_fuels_pipeline(EP::Model, inputs::Dict, setup::Dict)

    println("Synthesis Fuels Pipeline Module")

    T = inputs["T"] # Model operating time steps
    Z = inputs["Z"]  # Model demand zones - assumed to be same for H2 and electricity

    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
    START_SUBPERIODS = inputs["START_SUBPERIODS"]
    hours_per_subperiod = inputs["hours_per_subperiod"]

    Syn_P = inputs["Syn_P"] # Number of Hydrogen Pipelines
    Syn_Pipe_Map = inputs["Syn_Pipe_Map"]

    ### Variables ###
    @variable(EP, vSynNPipe[p = 1:Syn_P] >= 0) # Number of Pipes
    @variable(EP, vSynPipeLevel[p = 1:Syn_P, t = 1:T] >= 0) # Storage in the pipe
    @variable(EP, vSynPipeFlow_pos[p = 1:Syn_P, t = 1:T, d = [1, -1]] >= 0) # positive pipeflow
    @variable(EP, vSynPipeFlow_neg[p = 1:Syn_P, t = 1:T, d = [1, -1]] >= 0) # negative pipeflow


    ### Expressions ###
    # Calculate the number of new pipes
    @expression(
        EP,
        eSynNPipeNew[p = 1:Syn_P],
        vSynNPipe[p] - inputs["pSyn_Pipe_No_Curr"][p]
    )

    # Calculate net flow at each pipe-zone interfrace
    @expression(
        EP,
        eSynPipeFlow_net[p = 1:Syn_P, t = 1:T, d = [-1, 1]],
        vSynPipeFlow_pos[p, t, d] - vSynPipeFlow_neg[p, t, d]
    )

    ## Objective Function Expressions ##
    # Capital cost of pipelines
    # DEV NOTE: To add fixed cost of existing + new pipelines
    #  ParameterScale = 1 --> objective function is in million $
    #  ParameterScale = 0 --> objective function is in $
    if setup["ParameterScale"] == 1
        @expression(
            EP,
            eCSynPipe,
            sum(
                eSynNPipeNew[p] * inputs["pCAPEX_Syn_Pipe"][p] / (ModelScalingFactor)^2 for
                p = 1:Syn_P
            )
        )
    else
        @expression(
            EP,
            eCSynPipe,
            sum(eSynNPipeNew[p] * inputs["pCAPEX_Syn_Pipe"][p] for p = 1:Syn_P)
        )
    end

    EP[:eObj] += eCSynPipe

    # Capital cost of booster compressors located along each pipeline - more booster compressors needed for longer pipelines than shorter pipelines
    # YS Formula doesn't make sense to me
    #  ParameterScale = 1 --> objective function is in million $
    #  ParameterScale = 0 --> objective function is in $
    if setup["ParameterScale"] == 1
        @expression(
            EP,
            eCSynCompPipe,
            sum(eSynNPipeNew[p] * inputs["pCAPEX_Comp_Syn_Pipe"][p] for p = 1:Syn_P) /
            ModelScalingFactor^2
        )
    else
        @expression(
            EP,
            eCSynCompPipe,
            sum(eSynNPipeNew[p] * inputs["pCAPEX_Comp_Syn_Pipe"][p] for p = 1:Syn_P)
        )
    end

    EP[:eObj] += eCSynCompPipe

    ## End Objective Function Expressions ##

    ## Balance Expressions ##
    # H2 Power Consumption balance

    if setup["ParameterScale"] == 1 # IF ParameterScale = 1, power system operation/capacity modeled in GW rather than MW
        @expression(
            EP,
            ePowerBalanceSynPipeCompression[t = 1:T, z = 1:Z],
            sum(
                vSynPipeFlow_neg[
                    p,
                    t,
                    Syn_Pipe_Map[
                        (Syn_Pipe_Map[!, :Zone].==z).&(Syn_Pipe_Map[!, :pipe_no].==p),
                        :,
                    ][
                        !,
                        :d,
                    ][1],
                ] * inputs["pComp_MWh_per_tonne_Pipe"][p] for
                p in Syn_Pipe_Map[Syn_Pipe_Map[!, :Zone].==z, :][!, :pipe_no]
            ) / ModelScalingFactor
        )
    else # IF ParameterScale = 0, power system operation/capacity modeled in MW so no scaling of H2 related power consumption
        @expression(
            EP,
            ePowerBalanceSynPipeCompression[t = 1:T, z = 1:Z],
            sum(
                vSynPipeFlow_neg[
                    p,
                    t,
                    Syn_Pipe_Map[
                        (Syn_Pipe_Map[!, :Zone].==z).&(Syn_Pipe_Map[!, :pipe_no].==p),
                        :,
                    ][
                        !,
                        :d,
                    ][1],
                ] * inputs["pComp_MWh_per_tonne_Pipe"][p] for
                p in Syn_Pipe_Map[Syn_Pipe_Map[!, :Zone].==z, :][!, :pipe_no]
            )
        )
    end

    EP[:ePowerBalance] += -ePowerBalanceSynPipeCompression


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
        eSynPipeZoneDemand[t = 1:T, z = 1:Z],
        sum(
            eSynPipeFlow_net[
                p,
                t,
                Syn_Pipe_Map[
                    (Syn_Pipe_Map[!, :Zone].==z).&(Syn_Pipe_Map[!, :pipe_no].==p),
                    :,
                ][
                    !,
                    :d,
                ][1],
            ] for p in Syn_Pipe_Map[Syn_Pipe_Map[!, :Zone].==z, :][!, :pipe_no]
        )
    )

    EP[:eSynBalance] += eSynPipeZoneDemand

    ## End Balance Expressions ##
    ### End Expressions ###

    ### Constraints ###

    # Constraints
    if setup["SynPipeInteger"] == 1
        for p = 1:Syn_P
            set_integer.(vSynNPipe[p])
        end
    end

    # Modeling expansion of the pipleline network
    if setup["SynNetworkExpansion"] == 1
        # If network expansion allowed Total no. of Pipes >= Existing no. of Pipe
        @constraints(EP, begin
            [p in 1:Syn_P], EP[:eSynNPipeNew][p] >= 0
        end)
    else
        # If network expansion is not alllowed Total no. of Pipes == Existing no. of Pipe
        @constraints(EP, begin
            [p in 1:Syn_P], EP[:eSynNPipeNew][p] == 0
        end)
    end

    # Constraint maximum pipe flow
    @constraints(
        EP,
        begin
            [p in 1:Syn_P, t = 1:T, d in [-1, 1]],
            EP[:eSynPipeFlow_net][p, t, d] <=
            EP[:vSynNPipe][p] * inputs["pSyn_Pipe_Max_Flow"][p]
            [p in 1:Syn_P, t = 1:T, d in [-1, 1]],
            -EP[:eSynPipeFlow_net][p, t, d] <=
            EP[:vSynNPipe][p] * inputs["pSyn_Pipe_Max_Flow"][p]
        end
    )

    # Constrain positive and negative pipe flows
    @constraints(
        EP,
        begin
            [p in 1:Syn_P, t = 1:T, d in [-1, 1]],
            vSynNPipe[p] * inputs["pSyn_Pipe_Max_Flow"][p] >= vSynPipeFlow_pos[p, t, d]
            [p in 1:Syn_P, t = 1:T, d in [-1, 1]],
            vSynNPipe[p] * inputs["pSyn_Pipe_Max_Flow"][p] >= vSynPipeFlow_neg[p, t, d]
        end
    )

    # Minimum and maximum pipe level constraint
    @constraints(
        EP,
        begin
            [p in 1:Syn_P, t = 1:T],
            vSynPipeLevel[p, t] >= inputs["pSyn_Pipe_Min_Cap"][p] * vSynNPipe[p]
            [p in 1:Syn_P, t = 1:T],
            inputs["pSyn_Pipe_Max_Cap"][p] * vSynNPipe[p] >= vSynPipeLevel[p, t]
        end
    )

    # Pipeline storage level change
    @constraints(
        EP,
        begin
            [p in 1:Syn_P, t in START_SUBPERIODS],
            vSynPipeLevel[p, t] ==
            vSynPipeLevel[p, t+hours_per_subperiod-1] - eSynPipeFlow_net[p, t, -1] -
            eSynPipeFlow_net[p, t, 1]
        end
    )

    @constraints(
        EP,
        begin
            [p in 1:Syn_P, t in INTERIOR_SUBPERIODS],
            vSynPipeLevel[p, t] ==
            vSynPipeLevel[p, t-1] - eSynPipeFlow_net[p, t, -1] - eSynPipeFlow_net[p, t, 1]
        end
    )

    @constraints(EP, begin
        [p in 1:Syn_P], vSynNPipe[p] <= inputs["pSyn_Pipe_No_Max"][p]
    end)

    return EP

end


## Q. for Guannan - 
# 2. Issue with H2PipeCap usage and units is it on a per mile basis or cumulative basis?

function h2_pipeline(EP::Model, inputs::Dict, setup::Dict)

    println("Hydrogen Pipeline Module")

    T = inputs["T"] # Model operating time steps
    Z = inputs["Z"]  # Model demand zones - assumed to be same for H2 and electricity

    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
    START_SUBPERIODS = inputs["START_SUBPERIODS"]
    hours_per_subperiod = inputs["hours_per_subperiod"]

    H2_P = inputs["H2_P"] # Number of Hydrogen Pipelines
    H2_Pipe_Map = inputs["H2_Pipe_Map"]

    ### Variables ###
    @variable(EP, vH2NPipe[p = 1:H2_P] >= 0) # Number of Pipes
    @variable(EP, vH2PipeLevel[p = 1:H2_P, t = 1:T] >= 0) # Storage in the pipe
    @variable(EP, vH2PipeFlow_pos[p = 1:H2_P, t = 1:T, d = [1, -1]] >= 0) # positive pipeflow
    @variable(EP, vH2PipeFlow_neg[p = 1:H2_P, t = 1:T, d = [1, -1]] >= 0) # negative pipeflow


    ### Expressions ###
    # Calculate the number of new pipes
    @expression(EP, eH2NPipeNew[p = 1:H2_P], vH2NPipe[p] - inputs["pH2_Pipe_No_Curr"][p])

    # Calculate net flow at each pipe-zone interfrace
    @expression(
        EP,
        eH2PipeFlow_net[p = 1:H2_P, t = 1:T, d = [-1, 1]],
        vH2PipeFlow_pos[p, t, d] - vH2PipeFlow_neg[p, t, d]
    )

    ## Objective Function Expressions ##
    # Capital cost of pipelines 
    # DEV NOTE: To add fixed cost of existing + new pipelines
    #  ParameterScale = 1 --> objective function is in million $
    #  ParameterScale = 0 --> objective function is in $
    if setup["ParameterScale"] == 1
        @expression(
            EP,
            eCH2Pipe,
            sum(
                eH2NPipeNew[p] * inputs["pCAPEX_H2_Pipe"][p] / (ModelScalingFactor)^2 for
                p = 1:H2_P
            )
        )
    else
        @expression(
            EP,
            eCH2Pipe,
            sum(eH2NPipeNew[p] * inputs["pCAPEX_H2_Pipe"][p] for p = 1:H2_P)
        )
    end

    EP[:eObj] += eCH2Pipe

    # Capital cost of booster compressors located along each pipeline - more booster compressors needed for longer pipelines than shorter pipelines
    # YS Formula doesn't make sense to me
    #  ParameterScale = 1 --> objective function is in million $
    #  ParameterScale = 0 --> objective function is in $
    if setup["ParameterScale"] == 1
        @expression(
            EP,
            eCH2CompPipe,
            sum(eH2NPipeNew[p] * inputs["pCAPEX_Comp_H2_Pipe"][p] for p = 1:H2_P) / ModelScalingFactor^2
        )
    else
        @expression(
            EP,
            eCH2CompPipe,
            sum(eH2NPipeNew[p] * inputs["pCAPEX_Comp_H2_Pipe"][p] for p = 1:H2_P)
        )
    end

    EP[:eObj] += eCH2CompPipe

    ## End Objective Function Expressions ##

    ## Balance Expressions ##
    # H2 Power Consumption balance

    if setup["ParameterScale"] == 1 # IF ParameterScale = 1, power system operation/capacity modeled in GW rather than MW 
        @expression(
            EP,
            ePowerBalanceH2PipeCompression[t = 1:T, z = 1:Z],
            sum(
                vH2PipeFlow_neg[
                    p, t, H2_Pipe_Map[(H2_Pipe_Map[!, :Zone].==z).&(H2_Pipe_Map[!, :pipe_no].==p), :,][!,:d][1]
                ] * inputs["pComp_MWh_per_tonne_Pipe"][p] for p in H2_Pipe_Map[H2_Pipe_Map[!, :Zone].==z, :][!, :pipe_no]
            ) / ModelScalingFactor
        )
    else # IF ParameterScale = 0, power system operation/capacity modeled in MW so no scaling of H2 related power consumption
        @expression(
            EP,
            ePowerBalanceH2PipeCompression[t = 1:T, z = 1:Z],
            sum(
                vH2PipeFlow_neg[
                    p, t, H2_Pipe_Map[(H2_Pipe_Map[!, :Zone].==z).&(H2_Pipe_Map[!, :pipe_no].==p), :,][!,:d][1]
                ] * inputs["pComp_MWh_per_tonne_Pipe"][p] for p in H2_Pipe_Map[H2_Pipe_Map[!, :Zone].==z, :][!, :pipe_no]
            )
        )
    end

    EP[:ePowerBalance] += -ePowerBalanceH2PipeCompression


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
        ePipeZoneDemand[t = 1:T, z = 1:Z],
        sum(
            eH2PipeFlow_net[p, t, H2_Pipe_Map[(H2_Pipe_Map[!, :Zone].==z).&(H2_Pipe_Map[!, :pipe_no].==p), :][!,:d][1]] 
            for p in H2_Pipe_Map[H2_Pipe_Map[!, :Zone].==z, :][!, :pipe_no]
        )
    )

    EP[:eH2Balance] += ePipeZoneDemand

    ## End Balance Expressions ##
    ### End Expressions ###

    ### Constraints ###

    # Constraints
    if setup["H2PipeInteger"] == 1
        for p = 1:H2_P
            set_integer.(vH2NPipe[p])
        end
    end

    # Modeling expansion of the pipleline network
    if setup["H2NetworkExpansion"] == 1
        # If network expansion allowed Total no. of Pipes >= Existing no. of Pipe 
        @constraints(EP, begin
            [p in 1:H2_P], EP[:eH2NPipeNew][p] >= 0
        end)
    else
        # If network expansion is not alllowed Total no. of Pipes == Existing no. of Pipe 
        @constraints(EP, begin
            [p in 1:H2_P], EP[:eH2NPipeNew][p] == 0
        end)
    end

    # Constraint maximum pipe flow
    @constraints(
        EP,
        begin
            [p in 1:H2_P, t = 1:T, d in [-1, 1]],
            EP[:eH2PipeFlow_net][p, t, d] <=
            EP[:vH2NPipe][p] * inputs["pH2_Pipe_Max_Flow"][p]
            [p in 1:H2_P, t = 1:T, d in [-1, 1]],
            -EP[:eH2PipeFlow_net][p, t, d] <=
            EP[:vH2NPipe][p] * inputs["pH2_Pipe_Max_Flow"][p]
        end
    )

    # Constrain positive and negative pipe flows
    @constraints(
        EP,
        begin
            [p in 1:H2_P, t = 1:T, d in [-1, 1]],
            vH2NPipe[p] * inputs["pH2_Pipe_Max_Flow"][p] >= vH2PipeFlow_pos[p, t, d]
            [p in 1:H2_P, t = 1:T, d in [-1, 1]],
            vH2NPipe[p] * inputs["pH2_Pipe_Max_Flow"][p] >= vH2PipeFlow_neg[p, t, d]
        end
    )

    # Minimum and maximum pipe level constraint
    @constraints(
        EP,
        begin
            [p in 1:H2_P, t = 1:T],
            vH2PipeLevel[p, t] >= inputs["pH2_Pipe_Min_Cap"][p] * vH2NPipe[p]
            [p in 1:H2_P, t = 1:T],
            inputs["pH2_Pipe_Max_Cap"][p] * vH2NPipe[p] >= vH2PipeLevel[p, t]
        end
    )

    # Pipeline storage level change
    @constraints(
        EP,
        begin
            [p in 1:H2_P, t in START_SUBPERIODS],
            vH2PipeLevel[p, t] ==
            vH2PipeLevel[p, t+hours_per_subperiod-1] - eH2PipeFlow_net[p, t, -1] -
            eH2PipeFlow_net[p, t, 1]
        end
    )

    @constraints(
        EP,
        begin
            [p in 1:H2_P, t in INTERIOR_SUBPERIODS],
            vH2PipeLevel[p, t] ==
            vH2PipeLevel[p, t-1] - eH2PipeFlow_net[p, t, -1] - eH2PipeFlow_net[p, t, 1]
        end
    )

    @constraints(EP, begin
        [p in 1:H2_P], vH2NPipe[p] <= inputs["pH2_Pipe_No_Max"][p]
    end)

    return EP
end # end H2Pipeline module

@doc raw"""
    h2_production_piecewise_electro(EP::Model, inputs::Dict, setup::Dict)
"""
function h2_production_piecewise_electro(EP::Model, inputs::Dict, setup::Dict)

    print_and_log("H2 Production (Unit Commitment with Piecewise efficiency) Module")
    
    # Rename H2Gen dataframe
    dfH2Gen = inputs["dfH2Gen"]
    H2GenCommit = setup["H2GenCommit"]

    T = inputs["T"]     # Number of time steps (hours)
    Z = inputs["Z"]     # Number of zones
    H = inputs["H"]        #NUmber of hydrogen generation units 

    H2_GAS_COMMIT = inputs["H2_GEN_COMMIT"] #This is needed only for H2 balance

    if setup["ParameterScale"] ==1 
        model_scaling = ModelScalingFactor
    else
        model_scaling = 1
    end

    if setup["ModelH2Liquid"]==1
        H2_LIQ_COMMIT = inputs["H2_LIQ_COMMIT"]
        H2_EVAP_COMMIT = inputs["H2_EVAP_COMMIT"]
        H2_GEN_COMMIT = union(H2_LIQ_COMMIT, H2_GAS_COMMIT, H2_EVAP_COMMIT) #liquefiers are treated at generators, all the same expressions & contraints apply, except for H2 balance
    else
        H2_GEN_COMMIT = H2_GAS_COMMIT
    end
    H2_GEN_NEW_CAP = inputs["H2_GEN_NEW_CAP"] 
    H2_GEN_RET_CAP = inputs["H2_GEN_RET_CAP"] 

    H2_ELECTROLYZER_PW = inputs["H2_GEN_COMMIT_PW"]
    # Find all H2_GEN_COMMIT resources not in H2_GEN_COMMIT_PW
    H2_GEN_COMMIT_CONST = setdiff(H2_GEN_COMMIT, H2_GEN_COMMIT_PW)
    
    #Define start subperiods and interior subperiods
    START_SUBPERIODS = inputs["START_SUBPERIODS"]
    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
    hours_per_subperiod = inputs["hours_per_subperiod"] #total number of hours per subperiod

    # Resource properties
    cap_size = dfH2Gen[!,:Cap_Size_tonne_p_hr]::Vector{Float64}
    ramp_up_percentage = dfH2Gen[!,:Ramp_Up_Percentage]::Vector{Float64}
    ramp_down_percentage = dfH2Gen[!,:Ramp_Down_Percentage]::Vector{Float64}
    max_output = inputs["pH2_Max"]::Matrix{Float64}
    min_output = dfH2Gen[!,:H2Gen_min_output]::Vector{Float64}
    if "H2ElectroEff" in keys(inputs)
        H2ElectroEff = inputs["H2ElectroEff"]::Dict{Int64, Vector{Vector{Float64}}}
    end

    ###Variables###

    # commitment state variable
    @variable(EP, vH2GenCOMMIT[k in H2_GEN_COMMIT, t=1:T] >= 0)
    # Start up variable
    @variable(EP, vH2GenStart[k in H2_GEN_COMMIT, t=1:T] >= 0)
    # Shutdown Variable
    @variable(EP, vH2GenShut[k in H2_GEN_COMMIT, t=1:T] >= 0)

    ###Expressions###

    #Objective function expressions
    # Startup costs of "generation" for resource "y" during hour "t"
    #  ParameterScale = 1 --> objective function is in million $
    #  ParameterScale = 0 --> objective function is in $
    @expression(EP, eH2GenCStart[k in H2_GEN_COMMIT, t=1:T],(inputs["omega"][t]*inputs["C_H2_Start"][k]*vH2GenStart[k,t]/model_scaling^2))

    # Julia is fastest when summing over one row one column at a time
    @expression(EP, eTotalH2GenCStartT[t=1:T], sum(eH2GenCStart[k,t] for k in H2_GEN_COMMIT))
    @expression(EP, eTotalH2GenCStart, sum(eTotalH2GenCStartT[t] for t=1:T))

    add_to_expression!(EP[:eObj], eTotalH2GenCStartT)

    #H2 Balance expressions
    @expression(EP, eH2GenCommit[t=1:T, z=1:Z],
        sum(EP[:vH2Gen][k,t] for k in intersect(H2_GAS_COMMIT, dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID]))
    )

    add_to_expression!(EP[:eH2Balance], eH2GenCommit)

    if setup["ModelH2Liquid"]==1
        #H2 LIQUID Balance expressions
        @expression(EP, eH2LiqCommit[t=1:T, z=1:Z],
        sum(EP[:vH2Gen][k,t] for k in intersect(H2_LIQ_COMMIT, dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID])))
        
        # Add Liquid H2 to liquid balance, AND REMOVE it from the gas balance
        add_to_expression!(EP[:eH2Balance], -eH2LiqCommit)
        add_to_expression!(EP[:eH2LiqBalance], eH2LiqCommit)

        #H2 EVAPORATION Balance expressions
        if !isempty(H2_EVAP_COMMIT)
            @expression(EP, eH2EvapCommit[t=1:T, z=1:Z],
            sum(EP[:vH2Gen][k,t] for k in intersect(H2_EVAP_COMMIT, dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID])))
        
            # Add evaporated H2 to gas balance, AND REMOVE it from the liquid balance
            add_to_expression!(EP[:eH2Balance], eH2EvapCommit)
            add_to_expression!(EP[:eH2LiqBalance], -eH2EvapCommit)
        end
    end

    #Power Consumption for H2 Generation
    # IF ParameterScale = 1, power system operation/capacity modeled in GW rather than MW 
    # IF ParameterScale = 0, power system operation/capacity modeled in MW so no scaling of H2 related power consumption
    @expression(EP, ePowerBalanceH2GenCommit[t=1:T, z=1:Z],
        sum(EP[:vP2G][k,t]/model_scaling for k in intersect(H2_GEN_COMMIT, dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID]))
    ) 

    add_to_expression!(EP[:ePowerBalance], -ePowerBalanceH2GenCommit)

    ##For CO2 Polcy constraint right hand side development - power consumption by zone and each time step
    add_to_expression!(EP[:eH2NetpowerConsumptionByZone], ePowerBalanceH2GenCommit)

    ### Constraints ###
    ## Declaration of integer/binary variables
    if H2GenCommit == 1 # Integer UC constraints
        for k in H2_GEN_COMMIT
            set_integer.(vH2GenCOMMIT[k,:])
            set_integer.(vH2GenStart[k,:])
            set_integer.(vH2GenShut[k,:])
            if k in H2_GEN_RET_CAP
                set_integer(EP[:vH2GenRetCap][k])
            end
            if k in H2_GEN_NEW_CAP 
                set_integer(EP[:vH2GenNewCap][k])
            end
        end
    end #END unit commitment configuration

    ###Constraints###
    @constraints(EP, begin
        # Power Balance for constant-efficiency Electrolyzers
        [k in H2_GEN_COMMIT_CONST, t = 1:T], EP[:vP2G][k,t] == EP[:vH2Gen][k,t] * dfH2Gen[!,:etaP2G_MWh_p_tonne][k]
    end)

    # Power Balance for piecewise-efficiency Electrolyzers
    # for k in H2_GEN_COMMIT_PW
    #     output_frac_data = H2ElectroEff[k][1]
    #     power_frac_data = H2ElectroEff[k][2]
    #     for t = 1:T
    #         @constraint(EP,
    #             EP[:vH2Gen][k,t] == piecewise_linear
    #         )

    # end


    ### Capacitated limits on unit commitment decision variables (Constraints #1-3)
    @constraints(EP, begin
        [k in H2_GEN_COMMIT, t=1:T], EP[:vH2GenCOMMIT][k,t] <= EP[:eH2GenTotalCap][k]/cap_size[k]
        [k in H2_GEN_COMMIT, t=1:T], EP[:vH2GenStart][k,t] <= EP[:eH2GenTotalCap][k]/cap_size[k]
        [k in H2_GEN_COMMIT, t=1:T], EP[:vH2GenShut][k,t] <= EP[:eH2GenTotalCap][k]/cap_size[k]
    end)

    # Commitment state constraint linking startup and shutdown decisions (Constraint #4)
    @constraints(EP, begin
        # For Start Hours, links first time step with last time step in subperiod
        [k in H2_GEN_COMMIT, t in START_SUBPERIODS], EP[:vH2GenCOMMIT][k,t] == EP[:vH2GenCOMMIT][k,(t+hours_per_subperiod-1)] + EP[:vH2GenStart][k,t] - EP[:vH2GenShut][k,t]
        # For all other hours, links commitment state in hour t with commitment state in prior hour + sum of start up and shut down in current hour
        [k in H2_GEN_COMMIT, t in INTERIOR_SUBPERIODS], EP[:vH2GenCOMMIT][k,t] == EP[:vH2GenCOMMIT][k,t-1] + EP[:vH2GenStart][k,t] - EP[:vH2GenShut][k,t]
    end)


    ### Maximum ramp up and down between consecutive hours (Constraints #5-6)

    ## For Start Hours
    # Links last time step with first time step, ensuring position in hour 1 is within eligible ramp of final hour position
    # rampup constraints
    @constraint(EP,[k in H2_GEN_COMMIT, t in START_SUBPERIODS],
        + EP[:vH2Gen][k,t]
        - EP[:vH2Gen][k,(t+hours_per_subperiod-1)] 
        <= 
        + ramp_up_percentage[k] * cap_size[k] * (EP[:vH2GenCOMMIT][k,t]-EP[:vH2GenStart][k,t])
        + min(max_output[k,t], max(min_output[k],ramp_up_percentage[k])) * cap_size[k] * EP[:vH2GenStart][k,t]
        - min_output[k] * cap_size[k] * EP[:vH2GenShut][k,t]
    )

    # rampdown constraints
    @constraint(EP,[k in H2_GEN_COMMIT, t in START_SUBPERIODS],
        + EP[:vH2Gen][k,(t+hours_per_subperiod-1)] 
        - EP[:vH2Gen][k,t] 
        <= 
        + ramp_down_percentage[k] * cap_size[k] * (EP[:vH2GenCOMMIT][k,t] - EP[:vH2GenStart][k,t])
        - min_output[k] * cap_size[k] * EP[:vH2GenStart][k,t]
        + min(max_output[k,t], max(min_output[k],ramp_down_percentage[k])) * cap_size[k] * EP[:vH2GenShut][k,t]
    )

    ## For Interior Hours
    # rampup constraints
    @constraint(EP,[k in H2_GEN_COMMIT, t in INTERIOR_SUBPERIODS],
        + EP[:vH2Gen][k,t]
        - EP[:vH2Gen][k,t-1] 
        <= 
        + ramp_up_percentage[k] * cap_size[k] * (EP[:vH2GenCOMMIT][k,t] - EP[:vH2GenStart][k,t])
        + min(max_output[k,t], max(min_output[k],ramp_up_percentage[k])) * cap_size[k] * EP[:vH2GenStart][k,t]
        - min_output[k] * cap_size[k] * EP[:vH2GenShut][k,t])

    # rampdown constraints
    @constraint(EP,[k in H2_GEN_COMMIT, t in INTERIOR_SUBPERIODS],
        + EP[:vH2Gen][k,t-1] 
        - EP[:vH2Gen][k,t] 
        <= 
        + ramp_down_percentage[k] * cap_size[k] * (EP[:vH2GenCOMMIT][k,t] - EP[:vH2GenStart][k,t])
        - min_output[k] * cap_size[k] * EP[:vH2GenStart][k,t]
        + min(max_output[k,t], max(min_output[k],ramp_down_percentage[k])) * cap_size[k] * EP[:vH2GenShut][k,t])

    @constraints(EP, begin
        # Minimum stable generated per technology "k" at hour "t" > = Min stable output level
        [k in H2_GEN_COMMIT, t=1:T], EP[:vH2Gen][k,t] >= cap_size[k] *min_output[k]* EP[:vH2GenCOMMIT][k,t]
        # Maximum power generated per technology "k" at hour "t" < Max power
        [k in H2_GEN_COMMIT, t=1:T], EP[:vH2Gen][k,t] <= cap_size[k] * EP[:vH2GenCOMMIT][k,t] * max_output[k,t]
    end)


    ### Minimum up and down times (Constraints #9-10)
    for y in H2_GEN_COMMIT

        ## up time
        Up_Time = Int(floor(dfH2Gen[!,:Up_Time][y]))
        Up_Time_HOURS = [] # Set of hours in the summation term of the maximum up time constraint for the first subperiod of each representative period
        for s in START_SUBPERIODS
            Up_Time_HOURS = union(Up_Time_HOURS, (s+1):(s+Up_Time-1))
        end

        @constraints(EP, begin
            # cUpTimeInterior: Constraint looks back over last n hours, where n = dfH2Gen[!,:Up_Time][y]
            [t in setdiff(INTERIOR_SUBPERIODS,Up_Time_HOURS)], EP[:vH2GenCOMMIT][y,t] >= sum(EP[:vH2GenStart][y,e] for e=(t-dfH2Gen[!,:Up_Time][y]):t)

            # cUpTimeWrap: If n is greater than the number of subperiods left in the period, constraint wraps around to first hour of time series
            # cUpTimeWrap constraint equivalant to: sum(EP[:vH2GenStart][y,e] for e=(t-((t%hours_per_subperiod)-1):t))+sum(EP[:vH2GenStart][y,e] for e=(hours_per_subperiod_max-(dfH2Gen[!,:Up_Time][y]-(t%hours_per_subperiod))):hours_per_subperiod_max)
            [t in Up_Time_HOURS], EP[:vH2GenCOMMIT][y,t] >= sum(EP[:vH2GenStart][y,e] for e=(t-((t%hours_per_subperiod)-1):t))+sum(EP[:vH2GenStart][y,e] for e=((t+hours_per_subperiod-(t%hours_per_subperiod))-(dfH2Gen[!,:Up_Time][y]-(t%hours_per_subperiod))):(t+hours_per_subperiod-(t%hours_per_subperiod)))

            # cUpTimeStart:
            # NOTE: Expression t+hours_per_subperiod-(t%hours_per_subperiod) is equivalant to "hours_per_subperiod_max"
            [t in START_SUBPERIODS], EP[:vH2GenCOMMIT][y,t] >= EP[:vH2GenStart][y,t]+sum(EP[:vH2GenStart][y,e] for e=((t+hours_per_subperiod-1)-(dfH2Gen[!,:Up_Time][y]-1)):(t+hours_per_subperiod-1))
        end)

        ## down time
        Down_Time = Int(floor(dfH2Gen[!,:Down_Time][y]))
        Down_Time_HOURS = [] # Set of hours in the summation term of the maximum down time constraint for the first subperiod of each representative period
        for s in START_SUBPERIODS
            Down_Time_HOURS = union(Down_Time_HOURS, (s+1):(s+Down_Time-1))
        end

        # Constraint looks back over last n hours, where n = dfH2Gen[!,:Down_Time][y]
        # TODO: Replace LHS of constraints in this block with eNumPlantsOffline[y,t]
        @constraints(EP, begin
            # cDownTimeInterior: Constraint looks back over last n hours, where n = inputs["pDMS_Time"][y]
            [t in setdiff(INTERIOR_SUBPERIODS,Down_Time_HOURS)], EP[:eH2GenTotalCap][y]/cap_size[y]-EP[:vH2GenCOMMIT][y,t] >= sum(EP[:vH2GenShut][y,e] for e=(t-dfH2Gen[!,:Down_Time][y]):t)

            # cDownTimeWrap: If n is greater than the number of subperiods left in the period, constraint wraps around to first hour of time series
            # cDownTimeWrap constraint equivalant to: EP[:eH2GenTotalCap][y]/cap_size[y]-EP[:vH2GenCOMMIT][y,t] >= sum(EP[:vH2GenShut][y,e] for e=(t-((t%hours_per_subperiod)-1):t))+sum(EP[:vH2GenShut][y,e] for e=(hours_per_subperiod_max-(dfH2Gen[!,:Down_Time][y]-(t%hours_per_subperiod))):hours_per_subperiod_max)
            [t in Down_Time_HOURS], EP[:eH2GenTotalCap][y]/cap_size[y]-EP[:vH2GenCOMMIT][y,t] >= sum(EP[:vH2GenShut][y,e] for e=(t-((t%hours_per_subperiod)-1):t))+sum(EP[:vH2GenShut][y,e] for e=((t+hours_per_subperiod-(t%hours_per_subperiod))-(dfH2Gen[!,:Down_Time][y]-(t%hours_per_subperiod))):(t+hours_per_subperiod-(t%hours_per_subperiod)))

            # cDownTimeStart:
            # NOTE: Expression t+hours_per_subperiod-(t%hours_per_subperiod) is equivalant to "hours_per_subperiod_max"
            [t in START_SUBPERIODS], EP[:eH2GenTotalCap][y]/cap_size[y]-EP[:vH2GenCOMMIT][y,t]  >= EP[:vH2GenShut][y,t]+sum(EP[:vH2GenShut][y,e] for e=((t+hours_per_subperiod-1)-(dfH2Gen[!,:Down_Time][y]-1)):(t+hours_per_subperiod-1))
        end)
    end

    return EP

end

function electro_power_given_output()
    return 0
end
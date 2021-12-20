function h2_long_duration_storage(EP::Model, inputs::Dict)

    println("Hydrogen Long Duration Storage Module")

    Z = inputs["Z"]     # Number of zones
    K_stor = inputs["K_stor"] # Number of storage locations
	
    dfPeriodMap = inputs["Period_Map"]

    N = inputs["NPeriods"] # Number of modeled periods
    MODELED_PERIODS_INDEX = 1:N

    MODELED_HOURS_INDEX = 1:inputs["hours_per_subperiod"]
    
    REP_PERIOD = inputs["REP_PERIOD"]     # Number of representative periods
	REP_PERIODS_INDEX = MODELED_PERIODS_INDEX[dfPeriodMap[!,:Rep_Period] .== MODELED_PERIODS_INDEX]
    

    # State of charge of storage at beginning of each modeled period n
    @variable(EP, vH2SOCw[k = 1:K_stor, z = 1:Z, n in MODELED_PERIODS_INDEX] >= 0)
    # Build up in storage inventory over each representative period w
    # Build up inventory can be positive or negative
    @variable(EP, vH2dSOC[k = 1:K_stor, z = 1:Z, w = 1:REP_PERIOD])
    # State of charge of storage at each time point t
    @variable(EP, vH2SOCt[k = 1:K_stor, z = 1:Z, n in MODELED_PERIODS_INDEX, h in MODELED_HOURS_INDEX] >= 0)

    # Storage cahnge between period n and n+1 is equal to change during this period
    # Link first period to last period
    @constraints(
        EP,
        begin
            [k = 1:K_stor, z = 1:Z, n in MODELED_PERIODS_INDEX[1:(end-1)]],
            vH2SOCw[k, z, n+1] ==
            vH2SOCw[k, z, n] + vH2dSOC[k, z, dfPeriodMap[!, :RepPeriod_index][n]]
            [k = 1:K_stor, z = 1:Z, n = MODELED_PERIODS_INDEX[end]],
            vH2SOCw[k, z, 1] ==
            vH2SOCw[k, z, n] + vH2dSOC[k, z, dfPeriodMap[!, :RepPeriod_index][n]]
        end
    )
    # Storage at beginning of each modeled period cannot exceed installed energy capacity
    @constraints(
        EP,
        [k = 1:K_stor, z = 1:Z, n in MODELED_PERIODS_INDEX],
        if (dfPeriodMap[!, :RepPeriod][n] == n)
            vH2SOCw[k, z, n] == vH2StorEnergy[k, z, inputs["hours_per_subperiod"]*(n-1)+inputs["hours_per_subperiod"]] - vH2dSOC[k, z, n]
        else
            vH2SOCw[k, z, n] <= vH2StorCap[k, z]
        end
    )

    # Storage balance between time point t and t+1 during each representative week
    @constraints(
        EP,
        [k = 1:K_stor, z = 1:Z, n in MODELED_PERIODS_INDEX, h in MODELED_HOURS_INDEX],
        if h == 1
            vH2SOCt[k, z, n, h] == vH2SOCw[k, z, n]
        else
            t = inputs["hours_per_subperiod"] * (n - 1) + h
            vH2SOCt[k, z, n, h] ==
            vH2SOCt[k, z, n, h-1] + vH2StorEnergy[k, z, t] - vH2StorEnergy[k, z, t-1]
        end
    )
    return EP
end

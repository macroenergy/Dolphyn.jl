function h2_long_duration_truck(EP::Model, inputs::Dict)

    println("Hydrogen Long Duration Truck Module")

    Z = inputs["Z"] # Number of zone locations
    H2_TRUCK_TYPES = inputs["H2_TRUCK_TYPES"]
    dfPeriodMap = inputs["Period_Map"]

    N = inputs["NPeriods"] # Number of modeled periods
    MODELED_PERIODS_INDEX = 1:N

    MODELED_HOURS_INDEX = 1:inputs["hours_per_subperiod"]

    REP_PERIOD = inputs["REP_PERIOD"] # Number of representative periods
    REP_PERIODS_INDEX =
        MODELED_PERIODS_INDEX[dfPeriodMap[!, :Rep_Period].==MODELED_PERIODS_INDEX]

    ### Variables ###
    # State of charge of truck at beginning of each modeled period n
    @variable(
        EP,
        0 >= vH2TruckSOCw[z = 1:Z, j in H2_TRUCK_TYPES, n in MODELED_HOURS_INDEX] >= 0
    )

    # Build up in truck inventory over each representative period w
    # Build up inventory is fixed zero
    @variable(EP, 0 >= vH2TruckdSOC[z = 1:Z, j in H2_TRUCK_TYPES, w = 1:REP_PERIOD] >= 0)

    @constraints(
        EP,
        begin
            # State of charge of truck at beginning of each modeled period cannot exceed installed energy capacity
            [z = 1:Z, j in H2_TRUCK_TYPES, n in MODELED_HOURS_INDEX],
            vH2TruckSOCw[z, j, n] <= vH2NTruck[j]

            # State of charge of truck balance
            [z = 1:Z, j in H2_TRUCK_TYPES, n = N],
                vH2TruckSOCw[z, j, 1] ==
                vH2TruckSOCw[z, j, n] +
                vH2TruckdSOC[z, j, dfPeriodMap[!, :RepPeriod_index][n]]
            [z = 1:Z, j in H2_TRUCK_TYPES, n = 1:N-1],
                vH2TruckSOCw[z, j, n+1] ==
                vH2TruckSOCw[z, j, n] +
                vH2TruckdSOC[z, j, dfPeriodMap[!, :RepPeriod_index][n]]
        end
    )

    return EP
end

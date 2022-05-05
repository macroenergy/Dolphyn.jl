function co2_non_served_energy(EP::Model, inputs::Dict, setup::Dict)

    println("CO2 Non-served Module")

    T = inputs["T"]     # Number of time steps
    Z = inputs["Z"]     # Number of zones
    CO2_SEG = inputs["CO2_SEG"] # Number of load curtailment segments

    ### Variables ###

    # Non-served energy/curtailed demand in the segment "s" at hour "t" in zone "z"
    @variable(EP, vCO2NSE[s = 1:CO2_SEG, t = 1:T, z = 1:Z] >= 0)

    ### Expressions ###

    ## Objective Function Expressions ##

    # Cost of non-served energy/curtailed demand at hour "t" in zone "z"
    @expression(
        EP,
        eCO2CNSE[s = 1:CO2_SEG, t = 1:T, z = 1:Z],
        (inputs["omega"][t] * inputs["pC_CO2_D_Curtail"][s] * vCO2NSE[s, t, z])
    )

    # Sum individual demand segment contributions to non-served energy costs to get total non-served energy costs
    # Julia is fastest when summing over one row one column at a time
    @expression(
        EP,
        eTotalCO2CNSETS[t = 1:T, z = 1:Z],
        sum(eCO2CNSE[s, t, z] for s = 1:CO2_SEG)
    )
    @expression(EP, eTotalCO2CNSET[t = 1:T], sum(eTotalCO2CNSETS[t, z] for z = 1:Z))

    #  ParameterScale = 1 --> objective function is in million $ . In power system case we only scale by 1000 because variables are also scaled. But here we dont scale variables.
    #  ParameterScale = 0 --> objective function is in $
    if setup["ParameterScale"] == 1
        @expression(
            EP,
            eTotalCO2CNSE,
            sum(eTotalCO2CNSET[t] / (ModelScalingFactor)^2 for t = 1:T)
        )
    else
        @expression(EP, eTotalCO2CNSE, sum(eTotalCO2CNSET[t] for t = 1:T))
    end


    # Add total cost contribution of non-served energy/curtailed demand to the objective function
    EP[:eObj] += eTotalCO2CNSE

    ## Carbon Balance Expressions ##
    @expression(EP, eCO2BalanceNse[t = 1:T, z = 1:Z], sum(vCO2NSE[s, t, z] for s = 1:CO2_SEG))

    # Add non-served energy/curtailed demand contribution to carbon balance expression
    EP[:eCO2Balance] += eCO2BalanceNse

    ### Constratints ###

    # Demand curtailed in each segment of curtailable demands cannot exceed maximum allowable share of demand
    @constraint(
        EP,
        cCO2NSEPerSeg[s = 1:CO2_SEG, t = 1:T, z = 1:Z],
        vCO2NSE[s, t, z] <= inputs["pMax_CO2_D_Curtail"][s] * inputs["CO2_D"][t, z]
    )

    # Total demand curtailed in each time step (hourly) cannot exceed total demand
    @constraint(
        EP,
        cMaxCO2NSE[t = 1:T, z = 1:Z],
        sum(vCO2NSE[s, t, z] for s = 1:CO2_SEG) <= inputs["CO2_D"][t, z]
    )

    return EP
end
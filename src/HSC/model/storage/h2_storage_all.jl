function h2_storage_all(EP::Model, inputs::Dict)
    # Setup variables, constraints, and expressions common to all hydrogen storage resources
    println("Hydrogen Storage Core Resources Module")

    T = inputs["T"] # Number of time steps (hours) 
    Z = inputs["Z"] # Number of zones
    K_stor = inputs["K_stor"] # Number of storage locations

    H2_STO_NEW_CAP = inputs["H2_STO_NEW_CAP"]
	H2_STO_RET_CAP = inputs["H2_STO_RET_CAP"]

    H2_STO_NEW_RATE = inputs["H2_STO_NEW_RATE"]
    H2_STO_RET_RATE = inputs["H2_STO_RET_RATE"]
    
    START_SUBPERIODS = inputs["START_SUBPERIODS"]
    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]

    ### Variables ###
	# H2 new storage capacity for resource 'k' on zone 'z'
	@variable(EP, vH2StorNewCap[k = 1:K_stor, z = 1:Z] >= 0)

	# H2 retired storage capacity for resource 'k' on zone 'z'
	@variable(EP, vH2StorRetCap[k = 1:K_stor, z = 1:Z] >= 0)

    # H2 end storage capacity for resource 'k' on zone 'z'
    @variable(EP, vH2StorCap[k = 1:K_stor, z = 1:Z] >= 0)

    # H2 new storage compression capacity for resource 'k' on zone 'z'
    @variable(EP, vH2StorNewRate[k = 1:K_stor, z = 1:Z] >= 0)

    # H2 retired storage compression capacity for resource 'k' on zone 'z'
    @variable(EP, vH2StorRetRate[k = 1:K_stor, z = 1:Z] >= 0)
     
    # H2 storage compression capacity for resource 'k' on zone 'z'
    @variable(EP, vH2StorRate[k = 1:K_stor, z = 1:Z] >= 0)

    # H2 storage discharge for resource 'k' at hour 't' on zone 'z' 
    @variable(EP, vH2StorDis[k = 1:K_stor, z = 1:Z, t = 1:T] >= 0)

    # H2 storage charge for resource 'k' at hour 't' on zone 'z'
    @variable(EP, vH2StorCha[k = 1:K_stor, z = 1:Z, t = 1:T] >= 0)

    # H2 storage level for resource 'k' at hour 't' on zone 'z'
    @variable(EP, vH2StorVolume[k = 1:K_stor, z = 1:Z, t = 1:T] >= 0)

    ### Expressions ###
    ## Objective Function Expressions ##
    @expression(
        EP,
        CAPEX_Stor,
        sum(
            inputs["H2Stor_discount_factor"][k, z] * vH2StorNewCap[k, z] * inputs["H2StorUnitCapex"][k] for
            k = 1:K_stor, z = 1:Z
        )
    )
    EP[:eObj] += EP[:CAPEX_Stor]

    @expression(
        EP,
        CAPEX_Compression_Stor,
        sum(
            inputs["discount_factor_H2Compression"] *
            vH2StorRate[k, z] *
            inputs["H2StorCompressionUnitCapex"][k] for k = 1:K_stor, z = 1:Z
        )
    )
    EP[:eObj] += EP[:CAPEX_Compression_Stor]
    ## End Objective Function Expressions ##

    ## Balance Expressions ##
    # H2 Power Consumption balance
    @expression(
        EP,
        eH2StorCompressionPowerConsumption[t = 1:T, z = 1:Z],
        sum(vH2StorCha[k, z, t] * inputs["H2StorCompressionEnergy"][k] for k = 1:K_stor)
    )
    EP[:ePowerBalance] += eH2StorCompressionPowerConsumption

    # H2 balance
    @expression(
        EP,
        eH2Stor[t = 1:T, z = 1:Z],
        sum(vH2StorDis[k, z, t] for k = 1:K_stor) -
        sum(vH2StorCha[k, z, t] for k = 1:K_stor)
    )
    EP[:eH2Balance] += eH2Stor
    ## End Balance Expressions ##
    ### End Expressions ###

    ### Constraints ###
    @constraints(
        EP,
        [k = 1:K_stor, z = 1:Z],
        begin
            if k in intersect(H2_STO_NEW_CAP, H2_STO_RET_CAP)
                vH2StorCap[k,z] = Existing_Stor_cap_from_dataframe[k,z] + vH2StorNewCap[k,z] - vH2StorRetCap[k,z]
            elseif k in setdiff(H2_STO_NEW_CAP, H2_STO_RET_CAP)
                vH2StorCap[k,z] = Existing_Stor_cap_from_dataframe[k,z] + vH2StorNewCap[k,z]
            elseif k in setdiff(H2_STO_RET_CAP, H2_STO_NEW_CAP)
                vH2StorCap[k,z] = Existing_Stor_cap_from_dataframe[k,z] - vH2StorRetCap[k,z]
            else
                vH2StorCap[k,z] = Existing_Stor_cap_from_dataframe[k,z]
            end
        end
    )
    
    @constraints(
        EP,
        [k = 1:K_stor, z = 1:Z],
        begin
            if k in intersect(H2_STO_NEW_RATE, H2_STO_RET_RATE)
                vH2StorRate[k,z] = Existing_Stor_rate_from_dataframe[k,z] + vH2StorNewRATE[k,z] - vH2StorRetRATE[k,z]
            elseif k in setdiff(H2_STO_NEW_RATE, H2_STO_RET_RATE)
                vH2StorRate[k,z] = Existing_Stor_rate_from_dataframe[k,z] + vH2StorNewRATE[k,z]
            elseif k in setdiff(H2_STO_RET_RATE, H2_STO_NEW_RATE)
                vH2StorRate[k,z] = Existing_Stor_rate_from_dataframe[k,z] - vH2StorRetRATE[k,z]
            else
                vH2StorRate[k,z] = Existing_Stor_rate_from_dataframe[k,z]
            end
        end
    )

    # If no H2 storage is available, H2 storage capacity and level are fixed zero
    @constraints(EP, [k = 1:K_stor, z = 1:Z], if inputs["H2StorCap_avai"][k, z] == 0
        vH2StorCap[k, z] == 0
        vH2StorRate[k, z] == 0
    end)

    # H2 storage charge and discharge can not exceed injection and withdraw capacity
    @constraints(
        EP,
        begin
            [k = 1:K_stor, z = 1:Z, t = 1:T], vH2StorCha[k, z, t] <= vH2StorRate[k, z]
            [k = 1:K_stor, z = 1:Z, t = 1:T], vH2StorCha[k, z, t] <= inputs["InjectionRate"][k, z]
            [k = 1:K_stor, z = 1:Z, t = 1:T],
            vH2StorDis[k, z, t] <= inputs["WithdrawalRate"][k, z]
        end
    )

    # H2 storage volume and capacity bounds
    @constraints(
        EP,
        begin
            [k = 1:K_stor, z = 1:Z, t = 1:T],
            inputs["H2Stor_rho_min"][k, z] * vH2StorCap[k, z] <= vH2StorVolume[k, z, t]
            [k = 1:K_stor, z = 1:Z, t = 1:T], vH2StorVolume[k, z, t] <= vH2StorCap[k, z]
            [k = 1:K_stor, z = 1:Z, t = 1:T],
            inputs["H2StorCap_min"][k, z] * inputs["H2StorCap_avai"][k, z] <= vH2StorCap[k, z]
            [k = 1:K_stor, z = 1:Z, t = 1:T],
            vH2StorCap[k, z] <= inputs["H2StorCap_max"][k, z] * inputs["H2StorCap_avai"][k, z]
        end
    )

    # H2 storage volume balance 
    @constraints(
        EP,
        begin
            [k = 1:K_stor, z = 1:Z, t in INTERIOR_SUBPERIODS],
            vH2StorVolume[k, z, t] ==
            (1 - inputs["H2Storboiloffphour"][k, z]) * vH2StorVolume[k, z, t-1] +
            vH2StorCha[k, z, t] * inputs["H2Storeta"][k, z] - vH2StorDis[k, z, t] / inputs["H2Storeta"][k, z]
            [k = 1:K_stor, z = 1:Z, t in START_SUBPERIODS],
            vH2StorVolume[k, z, t] ==
            (1 - inputs["H2Storboiloffphour"][k, z]) * vH2StorVolume[k, z, t+inputs["hours_per_subperiod"]-1] -
            vH2dSOC[k, z, w] + vH2StorCha[k, z, t] * inputs["H2Storeta"][k, z] -
            vH2StorDis[k, z, t] / inputs["H2Storeta"][k, z]
        end
    )
    ### End Constraints ###
    return EP
end
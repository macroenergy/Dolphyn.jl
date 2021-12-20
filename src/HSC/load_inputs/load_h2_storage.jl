function load_h2_storage(setup::Dict, path::AbstractString, inputs_storage::Dict)
	# Read in H2 truck related inputs
	h2_storage_in = DataFrame(CSV.File(joinpath(path, "H2_storage.csv"), header = true))

	# Store DataFrame of generators/resources input data for use in model
	inputs_storage["dfH2torage"] = h2_storage_in

    Z_total = inputs_H2["Z_total"]
    K_stor_total = inputs_H2["K_stor_total"]
	discount_rate = 0.054
	
    # Dharik - note - Guannan, this creation of new parameters is not necessary - please see how storage data is used in GenX
    # Dharik - you can simply call the relevant parameter from the dataframe dfH2Storage?
    
	# Store DatFrame of generators/resources input data for local use
    H2StorData = h2_storage_in

    H2Storeta = zeros(K_stor_total, Z_total)
    H2Stor_rho_min = zeros(K_stor_total, Z_total)
    H2StorUnitCapex = zeros(K_stor_total, Z_total)
    H2StorCap_min = zeros(K_stor_total, Z_total)
    H2StorCap_max = zeros(K_stor_total, Z_total)
    H2StorCap_avai = zeros(K_stor_total, Z_total)
    H2Storlifetime = zeros(K_stor_total, Z_total)
    H2Storboiloffphour = zeros(K_stor_total, Z_total)
    H2Storlossf = zeros(K_stor_total, Z_total)
    InjectionRate = zeros(K_stor_total, Z_total)
    WithdrawalRate = zeros(K_stor_total, Z_total)

    storage_set = unique(H2StorData[!, :Storage_Type])
    zone_set_unique = unique(H2StorData[!, :Zone])
    for s = 1:size(storage_set)[1]
        # for z in 1:size(zone_set_unique)[1]
        H2Storeta[s, :] =
            H2StorData[(H2StorData[!, :Storage_Type].==storage_set[s]), :etaStor]
        H2Stor_rho_min[s, :] =
            H2StorData[(H2StorData[!, :Storage_Type].==storage_set[s]), :rhoH2Stor_min]
        H2StorUnitCapex[s, :] = H2StorData[
            (H2StorData[!, :Storage_Type].==storage_set[s]),
            :H2StorUnitCapex_per_tonne,
        ]
        H2StorCap_min[s, :] = H2StorData[
            (H2StorData[!, :Storage_Type].==storage_set[s]),
            :H2StorCap_min_tonne,
        ]
        H2StorCap_max[s, :] = H2StorData[
            (H2StorData[!, :Storage_Type].==storage_set[s]),
            :H2StorCap_max_tonne,
        ]
        H2StorCap_avai[s, :] =
            H2StorData[(H2StorData[!, :Storage_Type].==storage_set[s]), :H2StorCap_avai]
        H2Storlifetime[s, :] =
            H2StorData[(H2StorData[!, :Storage_Type].==storage_set[s]), :lifetime]
        H2Storboiloffphour[s, :] =
            H2StorData[(H2StorData[!, :Storage_Type].==storage_set[s]), :boiloff_perhour]
		H2Storlossf[s, :] =
            H2StorData[(H2StorData[!, :Storage_Type].==storage_set[s]), :lossfStor]
        InjectionRate[s, :] = H2StorData[
            (H2StorData[!, :Storage_Type].==storage_set[s]),
            :InjectionRate_tonne_per_hour,
        ]
        WithdrawalRate[s, :] = H2StorData[
            (H2StorData[!, :Storage_Type].==storage_set[s]),
            :WithdrawalRate_tonne_per_hour,
        ]
    end
    inputs_storage["H2Storeta"] = H2Storeta[K_stor_set, :]
    inputs_storage["H2Stor_rho_min"] = H2Stor_rho_min[K_stor_set, :]
    inputs_storage["H2StorUnitCapex"] = H2StorUnitCapex[K_stor_set, :]
    inputs_storage["H2StorCap_min"] = H2StorCap_min[K_stor_set, :]
    inputs_storage["H2StorCap_max"] = H2StorCap_max[K_stor_set, :]
    inputs_storage["H2StorCap_avai"] = H2StorCap_avai[K_stor_set, :]
    inputs_storage["H2Storlifetime"] = H2Storlifetime[K_stor_set, :]
    inputs_storage["H2Storboiloffphour"] = H2Storboiloffphour[K_stor_set, :]
    inputs_storage["H2Storlossf"] = H2Storlossf[K_stor_set, :]
    inputs_storage["InjectionRate"] = InjectionRate[K_stor_set, :]
    inputs_storage["WithdrawalRate"] = WithdrawalRate[K_stor_set, :]

    life = inputs_storage["H2Storlifetime"]
    inputs_storage["H2Stor_discount_factor"] = discount_rate ./ (float(1) .- (1 + discount_rate) .^ (-life))

    # H2StorRate = ones(K_stor,Z) * 100 # tonne-H2
    #     etaStor = (ones(K_stor_total,Z_total) .* H2StorData[!,:etaStor])[K_stor_set,Z_set] #
    #     rhoH2Stor_min = (ones(K_stor_total,Z_total) .* H2StorData[!,:rhoH2Stor_min
    # ])[K_stor_set,Z_set] #
    #     H2StorUnitCapex = (ones(K_stor_total) .* H2StorData[!,:H2StorUnitCapex
    # ])[K_stor_set,:] # $/tonne-H2
    #

    if setup["conversion_module"] == 1
        H2StorCompressionEnergy = (ones(K_stor_total).*[0, 0, 0, 0])[K_stor_set, :] # MWh/tonne
        H2StorCompressionUnitCapex = (ones(K_stor_total).*[0, 0, 0, 0])[K_stor_set, :] # $/(tonne-H2/hour)
    else
        H2StorCompressionEnergy =
            (ones(K_stor_total).*[0.5, 2, 10000, 10000])[K_stor_set, :] # MWh/tonne
        H2StorCompressionUnitCapex =
            (ones(K_stor_total).*[10000, 500000, 10000000, 10000000])[K_stor_set, :] # $/(tonne-H2/hour)
    end

    inputs_storage["H2StorCompressionEnergy"] = H2StorCompressionEnergy
    inputs_storage["H2StorCompressionUnitCapex"] = H2StorCompressionUnitCapex


    return inputs_storage

end
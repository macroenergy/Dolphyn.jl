function load_co2_storage(setup::Dict, path::AbstractString, sep::AbstractString, inputs_stor_co2::Dict)

	#Read in CO2 Storage related inputs
    co2_storage_in = DataFrame(CSV.File(string(path,sep,"CSC_storage.csv"), header=true), copycols=true)

	
    # Add Resource IDs after reading to prevent user errors
	co2_storage_in[!,:R_ID] = 1:size(collect(skipmissing(co2_storage_in[!,1])),1)

    # Store DataFrame of storage input data for use in model
	inputs_stor_co2["dfCO2Stor"] = co2_storage_in

    # Index of CO2 Storage - can be either commit, no_commit production technologies, demand side, G2P, or storage resources
	inputs_stor_co2["CO2_STOR_ALL"] = co2_storage_in[!,:R_ID]

	# Name of CO2 Storage
	inputs_stor_co2["CO2_STORAGE_NAME"] = collect(skipmissing(co2_storage_in[!,:CO2_Storage]))
	
	# Resource identifiers by zone (just zones in resource order + resource and zone concatenated)
	co2_storage_zones = collect(skipmissing(co2_storage_in[!,:Zone]))
	inputs_stor_co2["CO2_S_ZONES"] = co2_storage_zones
	inputs_stor_co2["CO2_STORAGE_ZONES"] = inputs_stor_co2["CO2_STORAGE_NAME"] .* "_z" .* string.(co2_storage_zones)

	# Defining whether CO2 storage is modeled as long-duration (inter-period carbon transfer allowed) or short-duration storage (inter-period carbon transfer disallowed)
	inputs_stor_co2["CO2_STOR_LONG_DURATION"] = co2_storage_in[(co2_storage_in.LDS.==1),:R_ID]
	inputs_stor_co2["CO2_STOR_SHORT_DURATION"] = co2_storage_in[(co2_storage_in.LDS.==0),:R_ID]

	# Set of all storage resources eligible for new carbon capacity
	inputs_stor_co2["NEW_CAP_CO2_CARBON"] = intersect(co2_storage_in[co2_storage_in.New_Build.==1,:R_ID], co2_storage_in[co2_storage_in.Max_Carbon_Cap_tonne.!=0,:R_ID], inputs_stor_co2["CO2_STOR_ALL"])

	# Set of asymmetric charge/discharge storage resources eligible for new charge capacity, which for CO2 storage refers to compression power requirements
	inputs_stor_co2["NEW_CAP_CO2_CHARGE"] = intersect(co2_storage_in[co2_storage_in.New_Build.==1,:R_ID], co2_storage_in[co2_storage_in.Max_Charge_Cap_tonne_p_hr.!=0,:R_ID], inputs_stor_co2["CO2_STOR_ALL"])

	println("CSC_storage.csv Successfully Read!")

    return inputs_stor_co2

end


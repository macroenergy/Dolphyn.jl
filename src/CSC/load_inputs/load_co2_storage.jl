

@doc raw"""
	load_co2_storage(setup::Dict, path::AbstractString, sep::AbstractString, inputs_co2_storage::Dict)

Function for reading input parameters related to CO2 storage resources in the carbon supply chain.
"""
function load_co2_storage(setup::Dict, path::AbstractString, sep::AbstractString, inputs_co2_storage::Dict)

	#Read in CO2 capture related inputs
    co2_storage = DataFrame(CSV.File(string(path,sep,"CSC_storage.csv"), header=true), copycols=true)

    # Add Resource IDs after reading to prevent user errors
	co2_storage[!,:R_ID] = 1:size(collect(skipmissing(co2_storage[!,1])),1)

    # Store DataFrame of capture units/resources input data for use in model
	inputs_co2_storage["dfCO2Storage"] = co2_storage

    # Index of CO2 resources - can be either commit, no_commit capture technologies, demand side, G2P, or storage resources
	inputs_co2_storage["CO2_STOR_ALL"] = size(collect(skipmissing(co2_storage[!,:R_ID])),1)

	# Name of CO2 capture resources
	inputs_co2_storage["CO2_STORAGE_NAME"] = collect(skipmissing(co2_storage[!,:CO2_Storage][1:inputs_co2_storage["CO2_STOR_ALL"]]))
	
	# Set of CO2 resources not eligible for unit committment
	inputs_co2_storage["CO2_STORAGE"] = co2_storage[!,:R_ID]

	println("CSC_storage.csv Successfully Read!")

    return inputs_co2_storage

end


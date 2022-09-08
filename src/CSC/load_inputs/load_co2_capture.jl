function load_co2_capture(setup::Dict, path::AbstractString, sep::AbstractString, inputs_capture::Dict)

	#Read in CO2 capture related inputs
    co2_capture = DataFrame(CSV.File(string(path,sep,"CSC_capture.csv"), header=true), copycols=true)

    # Add Resource IDs after reading to prevent user errors
	co2_capture[!,:R_ID] = 1:size(collect(skipmissing(co2_capture[!,1])),1)

    # Store DataFrame of capture units/resources input data for use in model
	inputs_capture["dfCO2Capture"] = co2_capture

    # Index of CO2 resources - can be either commit, no_commit capture technologies, demand side, G2P, or storage resources
	inputs_capture["CO2_RES_ALL"] = size(collect(skipmissing(co2_capture[!,:R_ID])),1)

	# Name of CO2 capture resources
	inputs_capture["CO2_RESOURCES_NAME"] = collect(skipmissing(co2_capture[!,:CO2_Resource][1:inputs_capture["CO2_RES_ALL"]]))
	
	# Resource identifiers by zone (just zones in resource order + resource and zone concatenated)
	co2_zones = collect(skipmissing(co2_capture[!,:Zone][1:inputs_capture["CO2_RES_ALL"]]))
	inputs_capture["CO2_R_ZONES"] = co2_zones
	inputs_capture["CO2_RESOURCE_ZONES"] = inputs_capture["CO2_RESOURCES_NAME"] .* "_z" .* string.(co2_zones)

	# Set of CO2 capture resources
	# Set of CO2 resources eligible for unit committment - either continuous or discrete capacity -set by setup["CO2captureCommit"]
	inputs_capture["CO2_CAPTURE_UC"] = co2_capture[co2_capture.CO2_CAPTURE_TYPE.==1 ,:R_ID]

	# Set of CO2 resources not eligible for unit committment
	inputs_capture["CO2_CAPTURE_NON_UC"] = co2_capture[co2_capture.CO2_CAPTURE_TYPE.==2 ,:R_ID]

    #Set of all CO2 capture Units - can be either commit or new commit
    inputs_capture["CO2_CAPTURE"] = union(inputs_capture["CO2_CAPTURE_UC"],inputs_capture["CO2_CAPTURE_NON_UC"])

    # Set of all resources eligible for new capacity - includes both storage and capture
	# DEV NOTE: Should we allow investment in flexible demand capacity later on?
	inputs_capture["CO2_CAPTURE_NEW_CAP"] = intersect(co2_capture[co2_capture.New_Build.==1 ,:R_ID], co2_capture[co2_capture.Max_Cap_tonne_p_hr.!=0,:R_ID]) 

	println("CSC_capture.csv Successfully Read!")

    return inputs_capture

end


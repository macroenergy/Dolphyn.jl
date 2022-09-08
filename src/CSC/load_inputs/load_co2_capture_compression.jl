function load_co2_capture_compression(setup::Dict, path::AbstractString, sep::AbstractString, inputs_co2_capture_comp::Dict)

	#Read in CO2 capture related inputs
    co2_capture_comp = DataFrame(CSV.File(string(path,sep,"CSC_capture_compression.csv"), header=true), copycols=true)

    # Add Resource IDs after reading to prevent user errors
	co2_capture_comp[!,:R_ID] = 1:size(collect(skipmissing(co2_capture_comp[!,1])),1)

    # Store DataFrame of capture units/resources input data for use in model
	inputs_co2_capture_comp["dfCO2CaptureComp"] = co2_capture_comp

    # Index of CO2 resources
	inputs_co2_capture_comp["CO2_CAPTURE_COMP_ALL"] = size(collect(skipmissing(co2_capture_comp[!,:R_ID])),1)

	# Name of CO2 capture resources
	inputs_co2_capture_comp["CO2_CAPTURE_COMP_NAME"] = collect(skipmissing(co2_capture_comp[!,:CO2_Capture_Compression][1:inputs_co2_capture_comp["CO2_CAPTURE_COMP_ALL"]]))
	
	# Resource identifiers by zone (just zones in resource order + resource and zone concatenated)
	co2_zones = collect(skipmissing(co2_capture_comp[!,:Zone][1:inputs_co2_capture_comp["CO2_CAPTURE_COMP_ALL"]]))
	inputs_co2_capture_comp["CO2_C_C_ZONES"] = co2_zones
	inputs_co2_capture_comp["CO2_CAPTURE_COMP_ZONES"] = inputs_co2_capture_comp["CO2_CAPTURE_COMP_NAME"] .* "_z" .* string.(co2_zones)

	# Set of CO2 resources not eligible for unit committment
	inputs_co2_capture_comp["CO2_CAPTURE_COMP"] = co2_capture_comp[!,:R_ID]

	println("CSC_capture_compression.csv Successfully Read!")

    return inputs_co2_capture_comp

end




@doc raw"""
	load_co2_capture_DAC(setup::Dict, path::AbstractString, sep::AbstractString, inputs_capture::Dict)

Function for reading input parameters related to DAC resources in the carbon supply chain.
"""
function load_co2_capture_DAC(setup::Dict, path::AbstractString, sep::AbstractString, inputs_capture::Dict)

	#Read in CO2 capture related inputs
    co2_dac = DataFrame(CSV.File(string(path,sep,"CSC_capture.csv"), header=true), copycols=true)

    # Add Resource IDs after reading to prevent user errors
	co2_dac[!,:R_ID] = 1:size(collect(skipmissing(co2_dac[!,1])),1)

    # Store DataFrame of capture units/resources input data for use in model
	inputs_capture["dfDAC"] = co2_dac

    # Index of DAC resources - can be either commit, no_commit capture technologies, demand side, G2P, or storage resources
	inputs_capture["DAC_RES_ALL"] = size(collect(skipmissing(co2_dac[!,:R_ID])),1)

	# Name of DAC resources
	inputs_capture["DAC_RESOURCES_NAME"] = collect(skipmissing(co2_dac[!,:CO2_Resource][1:inputs_capture["DAC_RES_ALL"]]))

	# Set of DAC resources
	inputs_capture["CO2_CAPTURE_DAC"] = co2_dac[!,:R_ID]

	println("CSC_capture.csv Successfully Read!")

    return inputs_capture

end


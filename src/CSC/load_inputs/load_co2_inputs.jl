


@doc raw"""
	load_co2_inputs(inputs::Dict,setup::Dict,path::AbstractString)

Loads various data inputs from multiple input .csv files in path directory and stores variables in a Dict (dictionary) object for use in model() function

inputs:
inputs - dict object containing input data
setup - dict object containing setup parameters
path - string path to working directory

returns: Dict (dictionary) object containing all data inputs of carbon supply chain.
"""
function load_co2_inputs(inputs::Dict,setup::Dict,path::AbstractString)

	## Use appropriate directory separator depending on Mac or Windows config
	if Sys.isunix()
		sep = "/"
    elseif Sys.iswindows()
		sep = "\U005c"
    else
        sep = "/"
	end

	data_directory = chop(replace(path, pwd() => ""), head = 1, tail = 0)

	## Read input files
	println("Reading CO2 Input CSV Files")
	## Declare Dict (dictionary) object used to store parameters
    inputs = load_co2_capture_DAC(setup, path, sep, inputs)
    inputs = load_co2_capture_DAC_variability(setup, path, sep, inputs)
	inputs = load_co2_storage(setup, path, sep, inputs)
	inputs = load_co2_capture_compression(setup, path, sep, inputs)
	inputs = load_co2_pipeline_data(setup, path, sep, inputs)
	
	println("CSC Input CSV Files Successfully Read In From $path$sep")

	return inputs
end

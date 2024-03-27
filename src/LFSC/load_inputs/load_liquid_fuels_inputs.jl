

@doc raw"""
	load_liquid_fuels_inputs(inputs::Dict,setup::Dict,path::AbstractString)

Loads various data inputs from multiple input .csv files in path directory and stores variables in a Dict (dictionary) object for use in model() function

inputs:
setup - dict object containing setup parameters
path - string path to working directory

returns: Dict (dictionary) object containing all data inputs of the liquid fuels supply chain.
"""
function load_liquid_fuels_inputs(inputs::Dict,setup::Dict,path::AbstractString)

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
	println("Reading Syn Fuel Input CSV Files")
    inputs = load_syn_fuels_resources(setup, path, sep, inputs)
	inputs = load_liquid_fuel_demand(setup, path, sep, inputs)

	return inputs
end

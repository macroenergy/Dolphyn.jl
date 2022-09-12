"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
Copyright (C) 2021,  Massachusetts Institute of Technology
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt.  Users uncompressing this from an archive may not have
received this license file.  If not, see <http://www.gnu.org/licenses/>.
"""

@doc raw"""
	load_h2_inputs(inputs::Dict,setup::Dict,path::AbstractString)

Loads various data inputs from multiple input .csv files in path directory and stores variables in a Dict (dictionary) object for use in model() function

inputs:
inputs - dict object containing input data
setup - dict object containing setup parameters
path - string path to working directory

returns: Dict (dictionary) object containing all data inputs of hydrogen sector.
"""
function load_h2_inputs(inputs::Dict,setup::Dict,path::AbstractString)

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
	println("Reading H2 Input CSV Files")
	## Declare Dict (dictionary) object used to store parameters
    inputs = load_h2_gen(setup, path, sep, inputs)
    inputs = load_h2_demand(setup, path, sep, inputs)
    inputs = load_h2_generators_variability(setup, path, sep, inputs)

	# Read input data about power network topology, operating and expansion attributes

	if setup["ModelH2Pipelines"] == 1
	    if isfile(string(path,sep,"HSC_pipelines.csv")) 		
			inputs  = load_h2_pipeline_data(setup, path, sep, inputs)
		else
			inputs["H2_P"] = 0
		end
	end
	

	# Read input data about hydrogen transport truck types
	if isfile(string(path,sep,"HSC_trucks.csv"))
		inputs = load_h2_truck(path, sep, inputs)
		setup["ModelH2Trucks"] =1
	else
		setup["ModelH2Trucks"] = 0
	end
	


	# Read input data about G2P Resources
	if isfile(string(path,sep,"HSC_g2p.csv"))
		# Create flag for other parts of the code
		setup["ModelH2G2P"] = 1
		inputs = load_h2_g2p(setup,path, sep, inputs)
		inputs = load_h2_g2p_variability(setup, path, sep, inputs)
	else
		setup["ModelH2G2P"] = 0
	end
	
	# If emissions flag is on, read in emissions related inputs
	if setup["H2CO2Cap"]>=1
		inputs = load_co2_cap_hsc(setup, path, sep, inputs)
	end

	#Check whether or not there is LDS for trucks and H2 storage
	if !haskey(inputs, "Period_Map") && 
		(setup["OperationWrapping"]==1 && (setup["ModelH2Trucks"] == 1 || !isempty(inputs["H2_STOR_LONG_DURATION"])) && (isfile(data_directory*"/Period_map.csv") || isfile(joinpath(data_directory,string(joinpath(setup["TimeDomainReductionFolder"],"Period_map.csv")))))) # Use Time Domain Reduced data for GenX)
		inputs = load_period_map(setup, path, sep, inputs)
	end
	println("HSC Input CSV Files Successfully Read In From $path$sep")

	return inputs
end

"""
DOLPHYN: Decision Optimization for Low-carbon for Power and Hydrogen Networks
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
	load_inputs(setup::Dict,path::AbstractString)

Loads various data inputs from multiple input .csv files in path directory and stores variables in a Dict (dictionary) object for use in model() function

inputs:
setup - dict object containing setup parameters
path - string path to working directory

returns: Dict (dictionary) object containing all data inputs
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
    if isfile(string(path,sep,"H2_Pipelines.csv")) 
		# Creating flag for other parts of the code
		setup["ModelH2Pipelines"] = 1
		inputs  = load_h2_pipeline_data(setup, path, sep, inputs)
	else
		inputs["H2_P"] = 0
	end

	println("H2 Input CSV Files Successfully Read In From $path$sep")

	return inputs
end
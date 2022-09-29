"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
Copyright (C) 2021, Massachusetts Institute of Technology and Peking University
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt. Users uncompressing this from an archive may not have
received this license file. If not, see <http://www.gnu.org/licenses/>.
"""

@doc raw"""
	load_h2_inputs(path::AbstractString, setup::Dict, inputs::Dict)

Loads various data inputs from multiple input .csv files in path directory and stores variables in a Dict (dictionary) object for use in model() function

inputs:
path - string path to working directory
setup - dict object containing setup parameters
inputs - dict object containing input data

returns: Dict (dictionary) object containing all data inputs
"""
function load_h2_inputs(path::AbstractString, setup::Dict, inputs::Dict)

	## Read input files
	println("Reading H2 Input CSV Files")
	## Declare Dict (dictionary) object used to store parameters
    inputs = load_h2_gen(path, setup, inputs)
    inputs = load_h2_demand(path, setup, inputs)
    inputs = load_h2_generators_variability(path, setup, inputs)

	# Read input data about power network topology, operating and expansion attributes

	if setup["ModelH2Pipelines"] == 1
		inputs  = load_h2_pipeline_data(path, setup, inputs)
	else
		inputs["H2_P"] = 0
	end

	# Read input data about hydrogen transport truck types
	if setup["ModelH2Trucks"] == 1
		inputs = load_h2_truck(path, setup, inputs)
	end

	# Read input data about G2P Resources
	if setup["ModelH2G2P"] == 1
		inputs = load_h2_g2p(path, setup, inputs)
		inputs = load_h2_g2p_variability(path, setup, inputs)
	end

	# If emissions flag is on, read in emissions related inputs
	if setup["H2CO2Cap"] >= 1
		inputs = load_co2_cap_hsc(path, setup, inputs)
	end

	#Check whether or not there is LDS for trucks and H2 storage
	if !haskey(inputs, "Period_Map") &&
		(setup["OperationWrapping"]==1 && (setup["ModelH2Trucks"] == 1 || !isempty(inputs["H2_STOR_LONG_DURATION"])) && (isfile(data_directory*"/Period_map.csv") || isfile(joinpath(data_directory,string(joinpath(setup["TimeDomainReductionFolder"],"Period_map.csv")))))) # Use Time Domain Reduced data for GenX)
		inputs = load_period_map(setup, path, sep, inputs)
	end

	println("HSC Input CSV Files Successfully Read In From $path")

	return inputs
end

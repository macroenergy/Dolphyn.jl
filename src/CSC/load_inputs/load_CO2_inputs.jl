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
	load_co2_inputs(path::AbstractString, setup::Dict, inputs::Dict)

Loads various data inputs from multiple input .csv files in path directory and stores variables in a Dict (dictionary) object for use in model() function

inputs:
path - string path to working directory
setup - dict object containing setup parameters
inputs - dict object containing inputs data

returns: Dict (dictionary) object containing all data inputs
"""

function load_co2_inputs(path::AbstractString, setup::Dict, inputs::Dict)

	## Use appropriate directory separator depending on Mac or Windows config
	if Sys.isunix()
		sep = "/"
    elseif Sys.iswindows()
		sep = "\U005c"
    else
        sep = "/"
	end

	## Read input files
	println("Reading CO2 Input CSV Files")
	## Declare Dict (dictionary) object used to store parameters
    inputs = load_co2_capture(path, setup, inputs)
	inputs = load_co2_demand(path, setup, inputs)
    inputs = load_co2_capture_variability(path, setup, inputs)
	inputs = load_co2_storage(path, setup, inputs)

	# If including price offset from negative emssions, read in emissions related inputs
	if setup["CO2CostOffset"] == 1
		inputs = load_co2_price_csc(path, setup, inputs)
	end

	
	##############################################################################################################################
	####################################### ADD IN FUTURE WHEN MODELING CO2 PIPELINE #############################################
	##############################################################################################################################

	# Read input data about power network topology, operating and expansion attributes
    #if isfile(string(path,"CSC_Pipelines.csv")) 
		# Creating flag for other parts of the code
		#setup["ModelCO2Pipelines"] = 1
		#inputs  = load_co2_pipeline_data(setup, path,  inputs)
	#else
		#inputs["CO2_P"] = 0
	#end

	##############################################################################################################################
	############################################## WHAT DOES THIS MEAN ###########################################################
	##############################################################################################################################

	#Check whether or not there is LDS for trucks and co2 storage
	#if !haskey(inputs, "Period_Map") && 
		#(setup["OperationWrapping"]==1 && (setup["ModelH2Trucks"] == 1 || !isempty(inputs["H2_STOR_LONG_DURATION"])) && (isfile(data_directory*"/Period_map.csv") || isfile(joinpath(data_directory,string(joinpath(setup["TimeDomainReductionFolder"],"Period_map.csv")))))) # Use Time Domain Reduced data for GenX)
		#inputs = load_period_map(setup, path,  inputs)
	#end
	println("CSC Input CSV Files Successfully Read In From $path")

	return inputs
end

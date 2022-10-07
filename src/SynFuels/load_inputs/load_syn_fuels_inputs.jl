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
	load_inputs(setup::Dict,path::AbstractString)

Loads various data inputs from multiple input .csv files in path directory and stores variables in a Dict (dictionary) object for use in model() function

inputs:
setup - dict object containing setup parameters
path - string path to working directory

returns: Dict (dictionary) object containing all data inputs
"""

function load_syn_fuels_inputs(inputs::Dict,setup::Dict,path::AbstractString)

	## Read input files
	println("Reading Syn Fuel Input CSV Files")
    inputs = load_syn_fuels_gen(setup, path, inputs)
	inputs = load_syn_fuels_generators_variability(setup, path, inputs)
    inputs = load_syn_fuels_demand(setup, path, inputs)

    if setup["ModelSynPipelines"] == 1
        inputs = load_syn_fuels_pipeline(setup, path, inputs)
    else
        inputs["Syn_P"] = 0
    end

    if setup["ModelSynTrucks"] == 1
        inputs = load_syn_fuels_truck(setup, path, inputs)
    end

    if setup["SynCO2Cap"] >= 1
		inputs = load_co2_cap_syn(setup, path, inputs)
	end

    println("Synthesis Fuels Input CSV Files Successfully Read In From $path")

	return inputs
end

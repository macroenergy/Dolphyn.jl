"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
Copyright (C) 2022,  Massachusetts Institute of Technology
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
function load_inputs(setup::Dict, path::AbstractString)

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
    print_and_log("Reading Input CSV Files")
    ## Declare Dict (dictionary) object used to store parameters
    inputs = Dict()

    # Store zonal information in inputs from setup
    if !haskey(setup, "Zones") || isempty(setup["Zones"])
        inputs["Zones"] = enumerate_zones(setup, path)
    else
        inputs["Zones"] = setup["Zones"]
    end
    inputs["Z"] = length(inputs["Zones"])

    ## Load inputs for modeling the power supply chain
    if setup["ModelPower"] == 1
        inputs = load_power_inputs(inputs, setup, path)
    end

    ## Load inputs for modeling the hydrogen supply chain
    if setup["ModelH2"] == 1
        inputs = load_h2_inputs(inputs, setup, path)
    end

    return inputs
end

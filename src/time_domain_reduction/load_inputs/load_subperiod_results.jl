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
    load_subperiod_results(inputs::Dict,setup::Dict,path::AbstractString)

Loads various data inputs from multiple input .csv files in path directory and stores variables in a Dict (dictionary) object for use in model() function

inputs:
inputs - dict object containing input data
setup - dict object containing setup parameters
path - string path to working directory

returns: Dict (dictionary) object containing all data inputs of hydrogen sector.
"""
function load_subperiod_results(inputs::Dict,setup::Dict,path::AbstractString)

    ## Use appropriate directory separator depending on Mac or Windows config
    if Sys.isunix()
        sep = "/"
    elseif Sys.iswindows()
        sep = "\U005c"
    else
        sep = "/"
    end

    print_and_log("Reading Subperiod Results CSV Files")

    STOR_ALL = inputs["STOR_ALL"]
    
    inputs = load_subperiod_power_gen(setup, path, inputs)

    if !isempty(STOR_ALL)
        inputs = load_subperiod_power_charge(setup, path, inputs)
    end

    if setup["ModelH2"] == 1
        H2_STOR_ALL = inputs["H2_STOR_ALL"]
    
        inputs = load_subperiod_h2_gen(setup, path, sep, inputs)

        if !isempty(H2_STOR_ALL)
            inputs = load_subperiod_h2_charge(setup, path, sep, inputs)
        end
    end

    print_and_log("Subperiod Results CSV Files Successfully Read In From $path$sep")

    return inputs
end

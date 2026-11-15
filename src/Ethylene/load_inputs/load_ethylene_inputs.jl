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
	
Loads various data inputs from multiple input .csv files in path directory and stores variables in a Dict (dictionary) object for use in model() function

inputs:
setup - dict object containing setup parameters
path - string path to working directory

returns: Dict (dictionary) object containing all data inputs of the ethylene supply chain.
"""
function load_ethylene_inputs(inputs::Dict,setup::Dict,path::AbstractString)

	## Use appropriate directory separator depending on Mac or Windows config
	if Sys.isunix()
		sep = "/"
    elseif Sys.iswindows()
		sep = "\U005c"
    else
        sep = "/"
	end

	data_directory = chop(replace(path, pwd() => ""), head = 1, tail = 0)

    # Select zones which will be included. This currently only works for the non-GenX sectors
    # select_zones!(inputs, setup, path)
    # println("HSC Sector using zones: ", inputs["Zones"])

    ## Read input files
    print_and_log("Reading Ethylene Input CSV Files")
    ## Declare Dict (dictionary) object used to store parameters
    
    inputs = load_ethylene_demand(setup, path, sep, inputs)
    inputs = load_conventional_ethylene_prices(setup, path, sep, inputs)
    # inputs = load_ethylene_resources(setup, path, sep, inputs)

    if setup["ModelEthyleneProduction"] == 1 
        inputs = load_ethylene_resources(setup, path, sep, inputs)
        inputs = load_ethylene_plants(setup, path, sep, inputs)
        if setup["ModelEthyleneRetrofitting"] == 1          
          inputs = load_ethylene_existing_capacities(setup, path, sep, inputs)   
          inputs = load_ethylene_retrofits(setup, path, sep, inputs)       

        end        
        inputs = load_LPG_prices(setup, path, sep, inputs)
        # inputs = load_ethane_prices(setup, path, sep, inputs)
    end

   


    
    print_and_log("Ethylene Input CSV Files Successfully Read In From $path$sep")

    return inputs

end

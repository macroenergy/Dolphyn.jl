
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
	
Function for reading input parameters related to ethylene production resources.
"""
function load_ethylene_retrofits(setup::Dict, path::AbstractString, sep::AbstractString, inputs::Dict)

# Read ethylene crackers data

	ethylene_retrofit_in = DataFrame(CSV.File(string(path,sep,"Ethylene_Retrofits.csv"), header=true), copycols=true)

    # Add plants IDs after reading to prevent user errors
	ethylene_retrofit_in[!,:R_ID] = 1:size(collect(skipmissing(ethylene_retrofit_in[!,1])),1)

    # Store DataFrame of generators/resources input data for use in model
	inputs["dfEthylene_retrofit"] = ethylene_retrofit_in

    # Index of Ethylene resources - can be either commit, no_commit 
	inputs["Ethylene_retrofit_ALL"] = size(collect(skipmissing(ethylene_retrofit_in[!,:R_ID])),1)

	# Name of Ethylene existing plants
	inputs["Ethylene_retrofit_NAME"] = collect(skipmissing(ethylene_retrofit_in[!,:Ethylene_Company][1:inputs["Ethylene_retrofit_ALL"]]))
	
	println(" -- Ethylene_Retrofits.csv Successfully Read!")

    return inputs


end

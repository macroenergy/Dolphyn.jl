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

################################################################################
## function output
##
## description: Writes results to multiple .csv output files in path directory
##
## returns: n/a
################################################################################
@doc raw"""
	write_outputs(EP::Model, path::AbstractString, setup::Dict, inputs::Dict)

Function for the entry-point for writing the different output files. From here, onward several other functions are called, each for writing specific output files, like costs, capacities, etc.
"""
function write_CSC_outputs(EP::Model, path::AbstractString, inputs::Dict, setup::Dict)

    # Create directory if it does not exist
    if !isdir(path)
        mkdir(path)
    end

    write_co2_capacity(EP, path, inputs, setup)
    write_co2_capture(EP, path, inputs, setup)
    write_co2_costs(EP, path, inputs, setup)
    write_co2_balance(EP, path, inputs, setup)
    write_co2_emissions(EP, path, inputs, setup)

    #write_co2_storage(path, sep, inputs, setup, EP)
    write_co2_storage_capacity(EP, path, inputs, setup)
    #write_co2_storage_costs(path, sep, inputs, setup, EP)

    ## Print confirmation
    println("Wrote CSC outputs to $path")

end # END output()

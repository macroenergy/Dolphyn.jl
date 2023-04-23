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
	write_outputs(EP::Model, path::AbstractString, setup::Dict, inputs::Dict)

Function (entry-point) for reporting the different output files. From here, onward several other functions are called, each for writing specific output files, like costs, capacities, etc.
"""
function write_outputs(EP::Model, path::AbstractString, setup::Dict, inputs::Dict)

	## Use appropriate directory separator depending on Mac or Windows config
	if Sys.isunix()
		sep = "/"
    elseif Sys.iswindows()
		sep = "\U005c"
    else
        sep = "/"
	end

    if !haskey(setup, "OverwriteResults") || setup["OverwriteResults"] == 1
        # Overwrite existing results if dir exists
        # This is the default behaviour when there is no flag, to avoid breaking existing code
        if !(isdir(path))
		    mkdir(path)
	    end
    else
        # Find closest unused ouput directory name and create it
        path = choose_output_dir(path)
        mkdir(path)
    end

	# https://jump.dev/MathOptInterface.jl/v0.9.10/apireference/#MathOptInterface.TerminationStatusCode
	status = termination_status(EP)

	## Check if solved sucessfully - time out is included
	if status != MOI.OPTIMAL && status != MOI.LOCALLY_SOLVED
		if status != MOI.TIME_LIMIT # Model failed to solve, so record solver status and exit
			write_status(path, sep, inputs, setup, EP)
			return
			# Model reached timelimit but failed to find a feasible solution
	#### Aaron Schwartz - Not sure if the below condition is valid anymore. We should revisit ####
		elseif isnan(objective_value(EP))==true
			# Model failed to solve, so record solver status and exit
			write_status(path, sep, inputs, setup, EP)
			return
		end
	end

	write_status(path, sep, inputs, setup, EP)

    ## Write power outputs
    if setup["ModelPower"] == 1
        power_path = path * sep * "Power"
        write_power_outputs(EP, power_path, setup, inputs)
    end

    ## Write hydrogen outputs
    if setup["ModelH2"] == 1
        hydrogen_path = path * sep * "Hydrogen"
        write_HSC_outputs(EP, hydrogen_path, setup, inputs)
    end
end
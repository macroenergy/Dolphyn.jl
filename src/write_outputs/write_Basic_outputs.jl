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
    write_basic_outputs(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)

Write basic outputs like model solving status and time weights used in the model.
"""
function write_basic_outputs(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)

    if !haskey(setup, "OverwriteResults") || setup["OverwriteResults"] == 1
        # Overwrite existing results if dir exists
        # This is the default behaviour when there is no flag, to avoid breaking existing code
        if !isdir(path)
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
			write_status(path, setup, inputs, EP)
			return
		elseif isnan(objective_value(EP))==true
			# Model failed to solve, so record solver status and exit
			write_status(path, setup, inputs, EP)
			return
		end
	end

	write_status(path, setup, inputs, EP)

    elapsed_time_time_weights = @elapsed write_time_weights(path, setup, inputs)
	println("Time elapsed for writing time weights is")
	println(elapsed_time_time_weights)

    println("Wrote basic outputs to $path")
end
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
    load_basic_inputs(inputs::Dict, setup::Dict, path::AbstractString)

Load basic inputs for the macro energy system. The external fuels data, time weights used in the time domain reduction method.
"""
function load_basic_inputs(inputs::Dict, setup::Dict, path::AbstractString)
    
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
    println("Reading Basic Input CSV Files")
    ## Read fuel cost data, including time-varying fuel costs
	inputs = load_fuels_data(setup, path, sep, inputs)

    ## Read in mapping of modeled periods to representative periods
	if setup["OperationWrapping"]==1 && (isfile(data_directory*"/Period_map.csv") || isfile(joinpath(data_directory,string(joinpath(setup["TimeDomainReductionFolder"],"Period_map.csv"))))) # Use Time Domain Reduced data for GenX)
		inputs = load_period_map(setup, path, sep, inputs)
	end

    return inputs
end
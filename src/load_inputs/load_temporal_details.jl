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
	load_temporal_details(setup::Dict, inputs::Dict, path::AbstractString)

"""
function load_temporal_details(setup::Dict, inputs::Dict, path::AbstractString)

    println("Loading Temporal Details")

    # Number of time steps (periods)
	inputs["T"] = setup["TotalLength"]

	T = inputs["T"]
	# Weights associated with operational sub-period in the model - sum of weight = length of time scale
    inputs["omega"] = zeros(Float64, T)
	# Number of periods initialized
	inputs["REP_PERIOD"] = 1
	# Number of sub-periods within each period
	inputs["H"] = 1

	if setup["OperationWrapping"] == 0
		# Total number of subtime periods
		inputs["REP_PERIOD"] = 1
		# Simple scaling factor for number of subperiods
		inputs["omega"][:] .= 1
	elseif setup["OperationWrapping"] == 1
		weights = DataFrame(CSV.File(joinpath(path, "weights.csv")))
		# Weights for each period - assumed same weights for each sub-period within a period
		inputs["Weights"] = collect(skipmissing(weights[!,:Sub_Weights])) # Weights each period

		# Total number of periods and subperiods
		inputs["REP_PERIOD"] = convert(Int16, collect(skipmissing(weights[!,:Rep_Periods]))[1])
		inputs["H"] = convert(Int64, collect(skipmissing(weights[!,:Timesteps_per_Rep_Period]))[1])

		# Creating sub-period weights from weekly weights
		for w in 1:inputs["REP_PERIOD"]
			for h in 1:inputs["H"]
				t = inputs["H"]*(w-1)+h
				inputs["omega"][t] = inputs["Weights"][w]/inputs["H"]
			end
		end

		## Read in mapping of modeled periods to representative periods
		if isfile(joinpath(path, "Period_map.csv")) # Use Time Domain Reduced data for GenX)
			inputs["Period_Map"] = DataFrame(CSV.File(joinpath(path, "Period_map.csv"), header=true), copycols=true)
			println("Period_map.csv Successfully Read!")
		end
	end

	# Create time set steps indicies
	inputs["hours_per_subperiod"] = div.(T,inputs["REP_PERIOD"]) # total number of hours per subperiod
	hours_per_subperiod = inputs["hours_per_subperiod"] # set value for internal use

	# set of indexes for all time periods that start a subperiod (e.g. sample day/week)
	inputs["START_SUBPERIODS"] = 1:hours_per_subperiod:T
	# set of indexes for all time periods that do not start a subperiod
	inputs["INTERIOR_SUBPERIODS"] = setdiff(1:T,inputs["START_SUBPERIODS"])
    
	println("$T Timesteps Modelled: 1-$T")

	return inputs
end
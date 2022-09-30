"""
GenX: An Configurable Capacity Expansion Model
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
	load_load_data(path::AbstractString, setup::Dict, inputs::Dict)

Function for reading input parameters related to electricity load (demand)
"""
function load_load_data(path::AbstractString, setup::Dict, inputs::Dict)

	# Load related inputs
	data_directory = joinpath(path, setup["TimeDomainReductionFolder"])
	if setup["TimeDomainReduction"] == 1  && isfile(joinpath(data_directory,"Load_data.csv")) && isfile(joinpath(data_directory,"Generators_variability.csv")) && isfile(joinpath(data_directory,"Fuels_data.csv")) # Use Time Domain Reduced data for GenX
		load_in = DataFrame(CSV.File(joinpath(data_directory, "Load_data.csv"), header=true), copycols=true)
	else # Run without Time Domain Reduction OR Getting original input data for Time Domain Reduction
		load_in = DataFrame(CSV.File(joinpath(path, "Load_data.csv"), header=true), copycols=true)
	end

	# Number of demand curtailment/lost load segments
	inputs["SEG"] = size(collect(skipmissing(load_in[!,:Demand_Segment])),1)

	## Set indices for internal use
	T = inputs["T"]   # Total number of time steps (hours)
	Zones = inputs["Zones"] # List of modeled zones

	# Demand in MW for each zone
	if setup["ParameterScale"] == 1  # Parameter scaling turned on
		# Max value of non-served energy
		inputs["Voll"] = collect(skipmissing(load_in[!,:Voll])) / ModelScalingFactor # convert from $/MWh $ million/GWh (assuming objective is divided by 1000)
		# Demand in MW
		inputs["pD"] = transpose(Matrix(load_in[1:T, ["Load_MW_z$z" for z in Zones]]))/ModelScalingFactor  # convert to GW
	else # No scaling
		# Max value of non-served energy
		inputs["Voll"] = collect(skipmissing(load_in[!,:Voll]))
		# Demand in MW
		inputs["pD"] = transpose(Matrix(load_in[1:T, ["Load_MW_z$z" for z in Zones]])) #form a matrix with columns as the different zonal load MW values and rows as the hours
	end

	# Cost of non-served energy/demand curtailment (for each segment)
	SEG = inputs["SEG"]  # Number of demand segments
	inputs["pC_D_Curtail"] = zeros(SEG)
	inputs["pMax_D_Curtail"] = zeros(SEG)
	for s in 1:SEG
		# Cost of each segment reported as a fraction of value of non-served energy - scaled implicitly
		inputs["pC_D_Curtail"][s] = collect(skipmissing(load_in[!,:Cost_of_Demand_Curtailment_per_MW]))[s]*inputs["Voll"][1]
		# Maximum hourly demand curtailable as % of the max demand (for each segment)
		inputs["pMax_D_Curtail"][s] = collect(skipmissing(load_in[!,:Max_Demand_Curtailment]))[s]
	end

	println("Load_data.csv Successfully Read!")

	return inputs
end

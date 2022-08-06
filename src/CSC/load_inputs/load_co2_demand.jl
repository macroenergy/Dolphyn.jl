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
	load_co2_demand(path::AbstractString, setup::Dict, inputs::Dict)


"""
function load_co2_demand(path::AbstractString, setup::Dict, inputs::Dict)
    
	# Set indices for internal use
	T = inputs["T"]   # Number of time steps (hours)
	Zones = inputs["Zones"] # List of modeled zones

	if setup["TimeDomainReduction"] == 1
		CO2_load_in = DataFrame(CSV.File(joinpath(path, "CSC_load_data.csv"), header=true), copycols=true)
	else # Run without Time Domain Reduction OR Getting original input data for Time Domain Reduction
		CO2_load_in = DataFrame(CSV.File(joinpath(path, "CSC_load_data.csv"), header=true), copycols=true)
	end

    # Number of demand curtailment/lost load segments
	inputs["CO2_SEG"] = size(collect(skipmissing(CO2_load_in[!,:Demand_Segment])),1)
	
	# Max value of non-served energy in $/(tonne)
	inputs["CO2_Voll"] = collect(skipmissing(CO2_load_in[!,:Voll]))
	# Demand in Tonnes per hour
	inputs["CO2_D"] =Matrix(CO2_load_in[1:T, ["Load_CO2_tonne_per_hr_z$z" for z in Zones]]) #form a matrix with columns as the different zonal load CO2 demand values and rows as the hours
    
	# Cost of non-served energy/demand curtailment (for each segment)
	CO2_SEG = inputs["CO2_SEG"]  # Number of demand segments
	inputs["pC_CO2_D_Curtail"] = zeros(CO2_SEG)
	inputs["pMax_CO2_D_Curtail"] = zeros(CO2_SEG)
	for s in 1:CO2_SEG
		# Cost of each segment reported as a fraction of value of non-served energy - scaled implicitly
		inputs["pC_CO2_D_Curtail"][s] = collect(skipmissing(CO2_load_in[!,:Cost_of_Demand_Curtailment_per_Tonne]))[s]*inputs["CO2_Voll"][1]
		# Maximum hourly demand curtailable as % of the max demand (for each segment)
		inputs["pMax_CO2_D_Curtail"][s] = collect(skipmissing(CO2_load_in[!,:Max_Demand_Curtailment]))[s]
	end

	println("CSC_load_data.csv Successfully Read!")

    return inputs

end

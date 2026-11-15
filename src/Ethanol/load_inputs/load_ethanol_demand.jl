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
	
Function for reading input parameters related to Ethanol demand and emissions of each zone Ethanol
"""
function load_ethanol_demand(setup::Dict, path::AbstractString, sep::AbstractString, inputs::Dict)
    
	data_directory_Ethanol = joinpath(path, setup["TimeDomainReductionFolder"])

	if setup["TimeDomainReduction"] == 1  && isfile(joinpath(data_directory_Ethanol,"Ethanol_Demand.csv")) # Use Time Domain Reduced data for GenX
		Ethanol_Demand_in = DataFrame(CSV.File(string(joinpath(data_directory_Ethanol,"Ethanol_Demand.csv")), header=true), copycols=true)
	else # Run without Time Domain Reduction OR Getting original input data for Time Domain Reduction
		Ethanol_Demand_in = DataFrame(CSV.File(string(path,sep,"Ethanol_Demand.csv"), header=true), copycols=true)
	end


    # Demand in tonnes per hour for each zone
	#println(names(load_in))
	start_Ethanol = findall(s -> s == "Load_tonneperhr_z1", names(Ethanol_Demand_in))[1] #gets the start_Ethanol column number of all the columns, with header "Load_tonneperhr_z1"
	
	# Demand in Tonnes per hour
	inputs["Ethanol_Demand"] =Matrix(Ethanol_Demand_in[1:inputs["T"],start_Ethanol:start_Ethanol-1+inputs["Z"]]) #form a matrix with columns as the different zonal load Ethanol demand values and rows as the hours
    
	inputs["ethanol_co2_per_tonne"] = Ethanol_Demand_in[!, "ethanol_co2_per_tonne"][1]
	
	println(" -- Ethanol_Demand.csv Successfully Read!")

	
    return inputs

end


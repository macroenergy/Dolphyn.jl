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


"""
function load_syn_fuels_demand(path::AbstractString, inputs::Dict, setup::Dict)
    
	if setup["TimeDomainReduction"] == 1
		Syn_fuels_demand_in = DataFrame(CSV.File(joinpath(path, "Syn_fuels_demand.csv"), header=true), copycols=true)
	else # Run without Time Domain Reduction OR Getting original input data for Time Domain Reduction
		Syn_fuels_demand_in = DataFrame(CSV.File(joinpath(path, "Syn_fuels_demand.csv"), header=true), copycols=true)
	end

    # Demand in MMBTU per hour for each zone
	#println(names(load_in))
	start = findall(s -> s == "Load_mmbtu_z1", names(Syn_fuels_demand_in))[1] #gets the starting column number of all the columns, with header "Load_H2_z1"
	
	# Demand in Tonnes per hour
	inputs["Syn_fuels_D"] =Matrix(Syn_fuels_demand_in[1:inputs["T"],start:start-1+inputs["Z"]]) #form a matrix with columns as the different zonal load H2 demand values and rows as the hours
    
    inputs["Conventional_fuel_co2_per_mmbtu"] = Syn_fuels_demand_in[!, "Conventional_fuel_co2_per_mmbtu"][1]
    inputs["Conventional_fuel_price_per_mmbtu"] = Syn_fuels_demand_in[!, "Conventional_fuel_price_per_mmbtu"][1]
    inputs["Syn_fuel_co2_per_mmbtu"] = Syn_fuels_demand_in[!, "Syn_fuel_co2_per_mmbtu"][1]

	println("Syn_Fuels_demand.csv Successfully Read!")

    return inputs

end


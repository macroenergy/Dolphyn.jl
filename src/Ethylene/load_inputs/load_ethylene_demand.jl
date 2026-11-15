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
	
Function for reading input parameters related to ethylene demand and emissions of each zone ethylene
"""
function load_ethylene_demand(setup::Dict, path::AbstractString, sep::AbstractString, inputs::Dict)
    
	data_directory_ethylene = joinpath(path, setup["TimeDomainReductionFolder"])

	if setup["TimeDomainReduction"] == 1  && isfile(joinpath(data_directory_ethylene,"Ethylene_Demand.csv")) # Use Time Domain Reduced data for GenX
		Ethylene_Demand_in = DataFrame(CSV.File(string(joinpath(data_directory_ethylene,"Ethylene_Demand.csv")), header=true), copycols=true)
	else # Run without Time Domain Reduction OR Getting original input data for Time Domain Reduction
		Ethylene_Demand_in = DataFrame(CSV.File(string(path,sep,"Ethylene_Demand.csv"), header=true), copycols=true)
	end


    # Demand in tonnes per hour for each zone
	#println(names(load_in))
	start_ethylene = findall(s -> s == "Load_tonneperhr_z1", names(Ethylene_Demand_in))[1] #gets the start_ethylene column number of all the columns, with header "Load_tonneperhr_z1"
	
	# Demand in Tonnes per hour
	inputs["Ethylene_Demand"] =Matrix(Ethylene_Demand_in[1:inputs["T"],start_ethylene:start_ethylene-1+inputs["Z"]]) #form a matrix with columns as the different zonal load Ethylene demand values and rows as the hours
    
	inputs["Consumption_ethylene_co2_per_tonneethylene"] = Ethylene_Demand_in[!, "Consumption_ethylene_co2_per_tonneethylene"][1]
	inputs["ConventionalSC_ethylene_co2_per_tonneethylene"] = Ethylene_Demand_in[!, "ConventionalSC_ethylene_co2_per_tonneethylene"][1]
    inputs["ODHE_ethylene_co2_per_tonneethylene"] = Ethylene_Demand_in[!, "ODHE_ethylene_co2_per_tonneethylene"][1]
	inputs["ElectrifiedSC_ethylene_co2_per_tonneethylene"] = Ethylene_Demand_in[!, "ElectrifiedSC_ethylene_co2_per_tonneethylene"][1]
	inputs["ElectrifiedReactor_ethylene_co2_per_tonneethylene"] = Ethylene_Demand_in[!, "ElectrifiedReactor_ethylene_co2_per_tonneethylene"][1]
	# inputs["CO2_emissions_Combustion_per_tethylene"] = Ethylene_Demand_in[!, "CO2_emissions_Combustion_per_tethylene"][1]
	# inputs["Fractional_combustion"] = Ethylene_Demand_in[!, "Fractional_combustion"][1]


	println(" -- Ethylene_Demand.csv Successfully Read!")

	
    return inputs

end


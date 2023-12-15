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

function load_bio_ethanol_demand(setup::Dict, path::AbstractString, sep::AbstractString, inputs::Dict)
    
	data_directory_ethanol = joinpath(path, setup["TimeDomainReductionFolder"])
	if setup["TimeDomainReduction"] == 1  && isfile(joinpath(data_directory_ethanol,"Load_data.csv")) && isfile(joinpath(data_directory_ethanol,"Generators_variability.csv")) && isfile(joinpath(data_directory_ethanol,"Fuels_data.csv")) && isfile(joinpath(data_directory_ethanol,"HSC_load_data.csv")) && isfile(joinpath(data_directory_ethanol,"HSC_generators_variability.csv")) && isfile(joinpath(data_directory_ethanol,"Bio_Fuels_Ethanol_Demand.csv")) # Use Time Domain Reduced data for GenX
		Bio_Fuels_Ethanol_Demand_in = DataFrame(CSV.File(string(joinpath(data_directory_ethanol,"Bio_Fuels_Ethanol_Demand.csv")), header=true), copycols=true)
	else # Run without Time Domain Reduction OR Getting original input data for Time Domain Reduction
		Bio_Fuels_Ethanol_Demand_in = DataFrame(CSV.File(string(path,sep,"Bio_Fuels_Ethanol_Demand.csv"), header=true), copycols=true)
	end

    # Demand in tonnes per hour for each zone
	#println(names(load_in))
	start_ethanol = findall(s -> s == "Load_mmbtu_z1", names(Bio_Fuels_Ethanol_Demand_in))[1] #gets the start_ethanoling column number of all the columns, with header "Load_H2_z1"
	
	# Demand in Tonnes per hour
	inputs["Bio_Fuels_Ethanol_D"] = Matrix(Bio_Fuels_Ethanol_Demand_in[1:inputs["T"],start_ethanol:start_ethanol-1+inputs["Z"]]) #form a matrix with columns as the different zonal load H2 demand values and rows as the hours
    
    #inputs["Conventional_ethanol_co2_per_mmbtu"] = Bio_Fuels_Ethanol_Demand_in[!, "Conventional_ethanol_co2_per_mmbtu"][1]
    #inputs["Conventional_ethanol_price_per_mmbtu"] = Bio_Fuels_Ethanol_Demand_in[!, "Conventional_ethanol_price_per_mmbtu"][1]
    inputs["Bio_ethanol_co2_per_mmbtu"] = Bio_Fuels_Ethanol_Demand_in[!, "Bio_ethanol_co2_per_mmbtu"][1]

	println("Bio_Fuels_Ethanol_Demand.csv Successfully Read!")

    return inputs

end


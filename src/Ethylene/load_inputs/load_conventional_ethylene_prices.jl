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
	load_conventional_ng_prices(setup::Dict, path::AbstractString, sep::AbstractString, inputs_bio_supply::Dict)

Function for reading input parameters related to conventional ng regional and hourly prices.
"""
function load_conventional_ethylene_prices(setup::Dict, path::AbstractString, sep::AbstractString, inputs::Dict)

	data_directory_ng = joinpath(path, setup["TimeDomainReductionFolder"])
	if setup["TimeDomainReduction"] == 1  && isfile(joinpath(data_directory_ng,"Ethylene_Prices.csv")) # Use Time Domain Reduced data for MACRO
		Ethylene_Prices = DataFrame(CSV.File(string(joinpath(data_directory_ng,"Ethylene_Prices.csv")), header=true), copycols=true)
	else # Run without Time Domain Reduction OR Getting original input data for Time Domain Reduction
		Ethylene_Prices = DataFrame(CSV.File(string(path,sep,"Ethylene_Prices.csv"), header=true), copycols=true)
	end

    # Price in $ per MMBtu for each zone and each time period
	#println(names(load_in))
	start_ethylene = findall(s -> s == "Price_tonne_z1", names(Ethylene_Prices))[1] #gets the start column number of all the columns, with header "Price_mmbtu_z1"
	
	# Price in $ per MMBtu
	inputs["Ethylene_Prices"] =Matrix(Ethylene_Prices[1:inputs["T"],start_ethylene:start_ethylene-1+inputs["Z"]]) #form a matrix with columns as the different zonal NG price values and rows as the hours

	println(" -- Ethylene_Prices.csv Successfully Read!")

    return inputs

end


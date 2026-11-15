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
	write_syn_ng_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for writing the diferent capacities for synthetic gas resources.
"""
function write_ethylene_production_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	# Capacity decisions
	dfEthylene = inputs["dfEthylene"]
	
	cap_Ethylene_prod_ethane_input = zeros(size(inputs["Ethylene_RESOURCES_NAME"]))
	for i in 1:inputs["Ethylene_RES_ALL"]
		cap_Ethylene_prod_ethane_input[i] = value(EP[:vCapacity_Ethylene_per_type_GF][i])
	end

	cap_Ethylene_prod = zeros(size(inputs["Ethylene_RESOURCES_NAME"]))
	AnnualEthylene = zeros(size(1:inputs["Ethylene_RES_ALL"]))
	MaxethaneConsumption = zeros(size(1:inputs["Ethylene_RES_ALL"]))
	AnnualethaneConsumption = zeros(size(1:inputs["Ethylene_RES_ALL"]))
	CapFactor = zeros(size(1:inputs["Ethylene_RES_ALL"]))
	

	for i in 1:inputs["Ethylene_RES_ALL"]
		cap_Ethylene_prod[i] = value(EP[:vCapacity_Ethylene_per_type_GF][i]) * dfEthylene[!,:tonne_ethane_p_tonne_ethylene][i]
		AnnualEthylene[i] = sum(inputs["omega"].* (value.(EP[:vEthylene_Prod_GF])[i,:]))
		MaxethaneConsumption[i] = value.(EP[:vCapacity_Ethylene_per_type_GF])[i] * 8760
		AnnualethaneConsumption[i] = sum(inputs["omega"].* (value.(EP[:vEthylene_ethanein_GF])[i,:]))
		
		if MaxethaneConsumption[i] == 0
			CapFactor[i] = 0
		else
			CapFactor[i] = AnnualethaneConsumption[i]/MaxethaneConsumption[i]
		end

	end

	dfCap = DataFrame(
		Resource = inputs["Ethylene_RESOURCES_NAME"], 
		Zone = dfEthylene[!,:Zone],        
		Capacity_tonne_ethane_per_h = cap_Ethylene_prod_ethane_input[:],
		Capacity_Ethylene_tonne_per_h = cap_Ethylene_prod[:],
		Annual_Ethylene_Production = AnnualEthylene[:],
		Max_Annual_ethane_Consumption = MaxethaneConsumption[:],
		Annual_ethane_Consumption = AnnualethaneConsumption[:],
		CapacityFactor = CapFactor[:]
	)


	total = DataFrame(
			Resource = "Total", Zone = "n/a",
			Capacity_tonne_ethane_per_h = sum(dfCap[!,:Capacity_tonne_ethane_per_h]),
			Capacity_Ethylene_tonne_per_h = sum(dfCap[!,:Capacity_Ethylene_tonne_per_h]),
			Annual_Ethylene_Production = sum(dfCap[!,:Annual_Ethylene_Production]),
			Max_Annual_ethane_Consumption = sum(dfCap[!,:Max_Annual_ethane_Consumption]),
			Annual_ethane_Consumption = sum(dfCap[!,:Annual_ethane_Consumption]),
			CapacityFactor = "-"
		)

	dfCap = vcat(dfCap, total)
	CSV.write(string(path,sep,"Ethylene_capacity.csv"), dfCap)
	return dfCap
end

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
	write_synfuel_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for writing the diferent capacities for synthetic fuels resources.
"""
function write_synfuel_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	# Capacity decisions
	dfSynFuels = inputs["dfSynFuels"]
	H = inputs["SYN_FUELS_RES_ALL"]
	
	capsynfuelplant = zeros(size(inputs["SYN_FUELS_RESOURCES_NAME"]))
	for i in 1:inputs["SYN_FUELS_RES_ALL"]
		if setup["ParameterScale"] ==1
			capsynfuelplant[i] = value(EP[:vCapacity_Syn_Fuel_per_type][i])*ModelScalingFactor
		else
			capsynfuelplant[i] = value(EP[:vCapacity_Syn_Fuel_per_type][i])
		end
	end

	capsyndiesel = zeros(size(inputs["SYN_FUELS_RESOURCES_NAME"]))
	capsynjetfuel = zeros(size(inputs["SYN_FUELS_RESOURCES_NAME"]))
	capsyngasoline = zeros(size(inputs["SYN_FUELS_RESOURCES_NAME"]))
	AnnualSynDiesel = zeros(size(1:inputs["SYN_FUELS_RES_ALL"]))
	AnnualSynJetfuel = zeros(size(1:inputs["SYN_FUELS_RES_ALL"]))
	AnnualSynGasoline = zeros(size(1:inputs["SYN_FUELS_RES_ALL"]))
	MaxCO2Consumption = zeros(size(1:inputs["SYN_FUELS_RES_ALL"]))
	AnnualCO2Consumption = zeros(size(1:inputs["SYN_FUELS_RES_ALL"]))
	CapFactor = zeros(size(1:inputs["SYN_FUELS_RES_ALL"]))
	

	for i in 1:inputs["SYN_FUELS_RES_ALL"]
		capsyndiesel[i] = value(EP[:vCapacity_Syn_Fuel_per_type][i]) * dfSynFuels[!,:mmbtu_sf_diesel_p_tonne_co2][i]
		capsynjetfuel[i] = value(EP[:vCapacity_Syn_Fuel_per_type][i]) * dfSynFuels[!,:mmbtu_sf_jetfuel_p_tonne_co2][i]
		capsyngasoline[i] = value(EP[:vCapacity_Syn_Fuel_per_type][i]) * dfSynFuels[!,:mmbtu_sf_gasoline_p_tonne_co2][i]
		AnnualSynDiesel[i] = sum(inputs["omega"].* (value.(EP[:vSFProd_Diesel])[i,:]))
		AnnualSynJetfuel[i] = sum(inputs["omega"].* (value.(EP[:vSFProd_Jetfuel])[i,:]))
		AnnualSynGasoline[i] = sum(inputs["omega"].* (value.(EP[:vSFProd_Gasoline])[i,:]))
		MaxCO2Consumption[i] = value.(EP[:vCapacity_Syn_Fuel_per_type])[i] * 8760
		AnnualCO2Consumption[i] = sum(inputs["omega"].* (value.(EP[:vSFCO2in])[i,:]))
		
		if MaxCO2Consumption[i] == 0
			CapFactor[i] = 0
		else
			CapFactor[i] = AnnualCO2Consumption[i]/MaxCO2Consumption[i]
		end

	end



	dfCap = DataFrame(
		Resource = inputs["SYN_FUELS_RESOURCES_NAME"], 
		Zone = dfSynFuels[!,:Zone],
		#StartCap = dfSynFuels[!,:Existing_Cap_tonne_p_hr],
		#RetCap = retcapsynfuelplant[:],
		Capacity_tonne_CO2_per_h = capsynfuelplant[:],
		#EndCap = value.(EP[:eH2GenTotalCap]),
		Capacity_Diesel_MMBtu_per_h = capsyndiesel[:],
		Capacity_Synjetfuel_MMBtu_per_h = capsynjetfuel[:],
		Capacity_Syngasoline_MMBtu_per_h = capsyngasoline[:],
		Annual_Syndiesel_Production = AnnualSynDiesel[:],
		Annual_Synjetfuel_Production = AnnualSynJetfuel[:],
		Annual_Syngasoline_Production = AnnualSynGasoline[:],
		Max_Annual_CO2_Consumption = MaxCO2Consumption[:],
		Annual_CO2_Consumption = AnnualCO2Consumption[:],
		CapacityFactor = CapFactor[:]
	)

	if setup["ParameterScale"] ==1
		dfCap.Capacity_tonne_CO2_per_h = dfCap.Capacity_tonne_CO2_per_h * ModelScalingFactor
		dfCap.Capacity_Diesel_MMBtu_per_h = dfCap.Capacity_Diesel_MMBtu_per_h * ModelScalingFactor
		dfCap.Capacity_Synjetfuel_MMBtu_per_h = dfCap.Capacity_Synjetfuel_MMBtu_per_h * ModelScalingFactor
		dfCap.Capacity_Syngasoline_MMBtu_per_h = dfCap.Capacity_Syngasoline_MMBtu_per_h * ModelScalingFactor
		
		dfCap.Annual_Syndiesel_Production = dfCap.Annual_Syndiesel_Production * ModelScalingFactor
		dfCap.Annual_Synjetfuel_Production = dfCap.Annual_Synjetfuel_Production * ModelScalingFactor
		dfCap.Annual_Syngasoline_Production = dfCap.Annual_Syngasoline_Production * ModelScalingFactor

		dfCap.Max_Annual_CO2_Consumption = dfCap.Max_Annual_CO2_Consumption * ModelScalingFactor
		dfCap.Annual_CO2_Consumption = dfCap.Annual_CO2_Consumption * ModelScalingFactor
	end


	total = DataFrame(
			Resource = "Total", Zone = "n/a",
			#StartCap = sum(dfCap[!,:StartCap]),
			#RetCap = sum(dfCap[!,:RetCap]),
			Capacity_tonne_CO2_per_h = sum(dfCap[!,:Capacity_tonne_CO2_per_h]),
			#, EndCap = sum(dfCap[!,:EndCap])),
			Capacity_Diesel_MMBtu_per_h = sum(dfCap[!,:Capacity_Diesel_MMBtu_per_h]),
			Capacity_Synjetfuel_MMBtu_per_h = sum(dfCap[!,:Capacity_Synjetfuel_MMBtu_per_h]),
			Capacity_Syngasoline_MMBtu_per_h = sum(dfCap[!,:Capacity_Syngasoline_MMBtu_per_h]),

			Annual_Syndiesel_Production = sum(dfCap[!,:Annual_Syndiesel_Production]),
			Annual_Synjetfuel_Production = sum(dfCap[!,:Annual_Synjetfuel_Production]),
			Annual_Syngasoline_Production = sum(dfCap[!,:Annual_Syngasoline_Production]),

			Max_Annual_CO2_Consumption = sum(dfCap[!,:Max_Annual_CO2_Consumption]),
			Annual_CO2_Consumption = sum(dfCap[!,:Annual_CO2_Consumption]),
			CapacityFactor = "-"
		)

	dfCap = vcat(dfCap, total)
	CSV.write(string(path,sep,"SynFuel_capacity.csv"), dfCap)
	return dfCap
end

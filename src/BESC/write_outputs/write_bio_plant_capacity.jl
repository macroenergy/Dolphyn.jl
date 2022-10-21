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
	write_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for writing the diferent capacities for the different capture technologies (starting capacities or, existing capacities, retired capacities, and new-built capacities).
"""
function write_bio_plant_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	# Capacity_tonne_biomass_per_h decisions
	dfbiorefinery = inputs["dfbiorefinery"]
	H = inputs["BIO_RES_ALL"]
	capbiorefinery = zeros(size(inputs["BIO_RESOURCES_NAME"]))
	capbioelectricity = zeros(size(inputs["BIO_RESOURCES_NAME"]))
	capbioh2 = zeros(size(inputs["BIO_RESOURCES_NAME"]))

	for i in 1:inputs["BIO_RES_ALL"]
		capbiorefinery[i] = value(EP[:vCapacity_BIO_per_type][i])
		capbioelectricity[i] = 0
		capbioh2[i] = 0
	end

	for i in inputs["BIO_E"]
		capbioelectricity[i] = value(EP[:vCapacity_BIO_per_type][i]) * dfbiorefinery[!,:BioElectricity_yield_MWh_per_tonne][i]
	end

	for i in inputs["BIO_H2"]
		capbioh2[i] = value(EP[:vCapacity_BIO_per_type][i]) * dfbiorefinery[!,:BioH2_yield_tonne_per_tonne][i]
	end

	AnnualElectricity = zeros(size(1:inputs["BIO_RES_ALL"]))
	for i in 1:H
		AnnualElectricity[i] = sum(inputs["omega"].* (value.(EP[:eBioelectricity_produced_per_plant_per_time])[i,:]))
	end

	AnnualH2 = zeros(size(1:inputs["BIO_RES_ALL"]))
	for i in 1:H
		AnnualH2[i] = sum(inputs["omega"].* (value.(EP[:eBiohydrogen_produced_per_plant_per_time])[i,:]))
	end
	
	MaxGen = zeros(size(1:inputs["BIO_RES_ALL"]))
	for i in 1:H
		MaxGen[i] = value.(EP[:vCapacity_BIO_per_type])[i] * 8760
	end

	AnnualGen = zeros(size(1:inputs["BIO_RES_ALL"]))
	for i in 1:H
		AnnualGen[i] = sum(inputs["omega"].* (value.(EP[:vBiomass_consumed_per_plant_per_time])[i,:]))
	end

	CapFactor = zeros(size(1:inputs["BIO_RES_ALL"]))
	for i in 1:H
		if MaxGen[i] == 0
			CapFactor[i] = 0
		else
			CapFactor[i] = AnnualGen[i]/MaxGen[i]
		end
	end

	dfCap = DataFrame(
		Resource = inputs["BIO_RESOURCES_NAME"], Zone = dfbiorefinery[!,:Zone],
		Capacity_tonne_biomass_per_h = capbiorefinery[:],
		Capacity_tonne_MWh_per_h = capbioelectricity[:],
		Capacity_tonne_h2_per_h = capbioh2[:],
		Annual_Electricity_Production = AnnualElectricity[:],
		Annual_H2_Production = AnnualH2[:],
		Max_Annual_Biomass_Consumption = MaxGen[:],
		Annual_Biomass_Consumption = AnnualGen[:],
		CapacityFactor = CapFactor[:]
	)

	if setup["ParameterScale"] ==1
		dfCap.Capacity_tonne_biomass_per_h = dfCap.Capacity_tonne_biomass_per_h * ModelScalingFactor
		dfCap.Capacity_tonne_MWh_per_h = dfCap.Capacity_tonne_MWh_per_h * ModelScalingFactor
		dfCap.Capacity_tonne_h2_per_h = dfCap.Capacity_tonne_h2_per_h * ModelScalingFactor
		dfCap.Annual_Electricity_Production = dfCap.Annual_Electricity_Production * ModelScalingFactor
		dfCap.Annual_H2_Production = dfCap.Annual_H2_Production * ModelScalingFactor
		dfCap.Max_Annual_Biomass_Consumption = dfCap.Max_Annual_Biomass_Consumption * ModelScalingFactor
		dfCap.Annual_Biomass_Consumption = dfCap.Annual_Biomass_Consumption * ModelScalingFactor
	end

	total = DataFrame(
			Resource = "Total", Zone = "n/a",
			Capacity_tonne_biomass_per_h = sum(dfCap[!,:Capacity_tonne_biomass_per_h]),
			Capacity_tonne_MWh_per_h = sum(dfCap[!,:Capacity_tonne_MWh_per_h]),
			Capacity_tonne_h2_per_h = sum(dfCap[!,:Capacity_tonne_h2_per_h]),
			Annual_Electricity_Production = sum(dfCap[!,:Annual_Electricity_Production]),
			Annual_H2_Production = sum(dfCap[!,:Annual_H2_Production]),
			Max_Annual_Biomass_Consumption = sum(dfCap[!,:Max_Annual_Biomass_Consumption]), Annual_Biomass_Consumption = sum(dfCap[!,:Annual_Biomass_Consumption]),
			CapacityFactor = "-"
		)

	dfCap = vcat(dfCap, total)
	CSV.write(string(path,sep,"BESC_biorefinery_capacity.csv"), dfCap)

	return dfCap
end
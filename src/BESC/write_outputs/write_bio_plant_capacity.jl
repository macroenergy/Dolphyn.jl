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
	write_bio_plant_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for writing the diferent capacities for biorefinery resources.
"""
function write_bio_plant_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	# Capacity_tonne_biomass_per_h decisions
	dfbioenergy = inputs["dfbioenergy"]
	H = inputs["BIO_RES_ALL"]
	capbioenergy = zeros(size(inputs["BIO_RESOURCES_NAME"]))
	capbioelectricity = zeros(size(inputs["BIO_RESOURCES_NAME"]))
	capbioH2 = zeros(size(inputs["BIO_RESOURCES_NAME"]))
	capbiodiesel = zeros(size(inputs["BIO_RESOURCES_NAME"]))
	capbiojetfuel = zeros(size(inputs["BIO_RESOURCES_NAME"]))
	capbiogasoline = zeros(size(inputs["BIO_RESOURCES_NAME"]))
	capbio_NG = zeros(size(inputs["BIO_RESOURCES_NAME"]))

	for i in 1:inputs["BIO_RES_ALL"]
		capbioenergy[i] = value(EP[:vCapacity_BIO_per_type][i])
	end

	for i in inputs["BIO_ELEC"]
		capbioelectricity[i] = value(EP[:vCapacity_BIO_per_type][i]) * dfbioenergy[!,:BioElectricity_yield_MWh_per_tonne][i]
	end

	for i in inputs["BIO_H2"]
		capbioH2[i] = value(EP[:vCapacity_BIO_per_type][i]) * dfbioenergy[!,:BioH2_yield_tonne_per_tonne][i]
	end

	for i in inputs["BIO_DIESEL"]
		capbiodiesel[i] = value(EP[:vCapacity_BIO_per_type][i]) * dfbioenergy[!,:BioDiesel_yield_MMBtu_per_tonne][i]
	end

	for i in inputs["BIO_JETFUEL"]
		capbiojetfuel[i] = value(EP[:vCapacity_BIO_per_type][i]) * dfbioenergy[!,:BioJetfuel_yield_MMBtu_per_tonne][i]
	end

	for i in inputs["BIO_GASOLINE"]
		capbiogasoline[i] = value(EP[:vCapacity_BIO_per_type][i]) * dfbioenergy[!,:BioGasoline_yield_MMBtu_per_tonne][i]
	end


	for i in inputs["BIO_NG"]
		capbio_NG[i] = value(EP[:vCapacity_BIO_per_type][i]) * dfbioenergy[!,:Bio_NG_yield_MMBtu_per_tonne][i]
	end

	AnnualElectricity = zeros(size(1:inputs["BIO_RES_ALL"]))
	AnnualH2 = zeros(size(1:inputs["BIO_RES_ALL"]))
	AnnualBioDiesel = zeros(size(1:inputs["BIO_RES_ALL"]))
	AnnualBioJetfuel = zeros(size(1:inputs["BIO_RES_ALL"]))
	AnnualBioGasoline = zeros(size(1:inputs["BIO_RES_ALL"]))
	AnnualBioNG = zeros(size(1:inputs["BIO_RES_ALL"]))
	MaxBiomassConsumption = zeros(size(1:inputs["BIO_RES_ALL"]))
	AnnualBiomassConsumption = zeros(size(1:inputs["BIO_RES_ALL"]))
	CapFactor = zeros(size(1:inputs["BIO_RES_ALL"]))
	AnnualCO2Emission = zeros(size(1:inputs["BIO_RES_ALL"]))

	for i in 1:H
		AnnualElectricity[i] = sum(inputs["omega"].* (value.(EP[:eBioelectricity_produced_per_plant_per_time])[i,:]))
		AnnualH2[i] = sum(inputs["omega"].* (value.(EP[:eBiohydrogen_produced_per_plant_per_time])[i,:]))
		AnnualBioDiesel[i] = sum(inputs["omega"].* (value.(EP[:eBiodiesel_produced_per_plant_per_time])[i,:]))
		AnnualBioJetfuel[i] = sum(inputs["omega"].* (value.(EP[:eBiojetfuel_produced_per_plant_per_time])[i,:]))
		AnnualBioGasoline[i] = sum(inputs["omega"].* (value.(EP[:eBiogasoline_produced_per_plant_per_time])[i,:]))
		AnnualBioNG[i] = sum(inputs["omega"].* (value.(EP[:eBio_NG_produced_per_plant_per_time])[i,:]))
		MaxBiomassConsumption[i] = value.(EP[:vCapacity_BIO_per_type])[i] * 8760
		AnnualBiomassConsumption[i] = sum(inputs["omega"].* (value.(EP[:vBiomass_consumed_per_plant_per_time])[i,:]))
		AnnualCO2Emission[i] = sum(inputs["omega"].* (value.(EP[:eBiorefinery_CO2_emissions_per_plant_per_time])[i,:] - value.(EP[:eBiomass_CO2_captured_per_plant_per_time])[i,:]))

		if MaxBiomassConsumption[i] == 0
			CapFactor[i] = 0
		else
			CapFactor[i] = AnnualBiomassConsumption[i]/MaxBiomassConsumption[i]
		end
		
	end



	dfCap = DataFrame(
		Resource = inputs["BIO_RESOURCES_NAME"], Zone = dfbioenergy[!,:Zone],
		Capacity_tonne_biomass_per_h = capbioenergy[:],
		Capacity_Bioelectricity_MWh_per_h = capbioelectricity[:],
		Capacity_BioH2_tonne_per_h = capbioH2[:],
		Capacity_Biodiesel_MMBtu_per_h = capbiodiesel[:],
		Capacity_Biojetfuel_MMBtu_per_h = capbiojetfuel[:],
		Capacity_Biogasoline_MMBtu_per_h = capbiogasoline[:],
		Capacity_Bio_NG_MMBtu_per_h = capbio_NG[:],
		Annual_Electricity_Production = AnnualElectricity[:],
		Annual_H2_Production = AnnualH2[:],
		Annual_Biodiesel_Production = AnnualBioDiesel[:],
		Annual_Biojetfuel_Production = AnnualBioJetfuel[:],
		Annual_Biogasoline_Production = AnnualBioGasoline[:],
		Annual_Bio_NG_Production = AnnualBioNG[:],
		Max_Annual_Biomass_Consumption = MaxBiomassConsumption[:],
		Annual_Biomass_Consumption = AnnualBiomassConsumption[:],
		CapacityFactor = CapFactor[:],
		Annual_CO2_Emission = AnnualCO2Emission[:]
	)

	total = DataFrame(
			Resource = "Total", Zone = "n/a",
			Capacity_tonne_biomass_per_h = sum(dfCap[!,:Capacity_tonne_biomass_per_h]),
			Capacity_Bioelectricity_MWh_per_h = sum(dfCap[!,:Capacity_Bioelectricity_MWh_per_h]),
			Capacity_BioH2_tonne_per_h = sum(dfCap[!,:Capacity_BioH2_tonne_per_h]),
			Capacity_Biodiesel_MMBtu_per_h = sum(dfCap[!,:Capacity_Biodiesel_MMBtu_per_h]),
			Capacity_Biojetfuel_MMBtu_per_h = sum(dfCap[!,:Capacity_Biojetfuel_MMBtu_per_h]),
			Capacity_Biogasoline_MMBtu_per_h = sum(dfCap[!,:Capacity_Biogasoline_MMBtu_per_h]),
			Capacity_Bio_NG_MMBtu_per_h = sum(dfCap[!,:Capacity_Bio_NG_MMBtu_per_h]),
			Annual_Electricity_Production = sum(dfCap[!,:Annual_Electricity_Production]),
			Annual_H2_Production = sum(dfCap[!,:Annual_H2_Production]),
			Annual_Biodiesel_Production = sum(dfCap[!,:Annual_Biodiesel_Production]),
			Annual_Biojetfuel_Production = sum(dfCap[!,:Annual_Biojetfuel_Production]),
			Annual_Biogasoline_Production = sum(dfCap[!,:Annual_Biogasoline_Production]),
			Annual_Bio_NG_Production = sum(dfCap[!,:Annual_Bio_NG_Production]),
			Max_Annual_Biomass_Consumption = sum(dfCap[!,:Max_Annual_Biomass_Consumption]), 
			Annual_Biomass_Consumption = sum(dfCap[!,:Annual_Biomass_Consumption]),
			CapacityFactor = "-",
			Annual_CO2_Emission = sum(dfCap[!,:Annual_CO2_Emission]),
		)

	dfCap = vcat(dfCap, total)
	CSV.write(string(path,sep,"BESC_bioenergy_capacity.csv"), dfCap)

	return dfCap
end
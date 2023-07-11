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
	write_h2_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the capacities for the different hydrogen resources (starting capacities or, existing capacities, retired capacities, and new-built capacities).
"""
function write_h2_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	# Capacity decisions
	dfH2Gen = inputs["dfH2Gen"]
	H = inputs["H2_RES_ALL"]

	capdischarge = zeros(size(inputs["H2_RESOURCES_NAME"]))
	for i in inputs["H2_GEN_NEW_CAP"]
		if i in inputs["H2_GEN_COMMIT"]
			capdischarge[i] = value(EP[:vH2GenNewCap][i]) * dfH2Gen[!,:Cap_Size_tonne_p_hr][i]
		else
			capdischarge[i] = value(EP[:vH2GenNewCap][i])
		end
	end

	retcapdischarge = zeros(size(inputs["H2_RESOURCES_NAME"]))
	for i in inputs["H2_GEN_RET_CAP"]
		if i in inputs["H2_GEN_COMMIT"]
			retcapdischarge[i] = first(value.(EP[:vH2GenRetCap][i])) * dfH2Gen[!,:Cap_Size_tonne_p_hr][i]
		else
			retcapdischarge[i] = first(value.(EP[:vH2GenRetCap][i]))
		end
	end

	capcharge = zeros(size(inputs["H2_RESOURCES_NAME"]))
	retcapcharge = zeros(size(inputs["H2_RESOURCES_NAME"]))
	for i in inputs["H2_STOR_ALL"]
		if i in inputs["NEW_CAP_H2_STOR_CHARGE"]
			capcharge[i] = value(EP[:vH2CAPCHARGE][i])
		end
		if i in inputs["RET_CAP_H2_STOR_CHARGE"]
			retcapcharge[i] = value(EP[:vH2RETCAPCHARGE][i])
		end
	end

	capenergy = zeros(size(inputs["H2_RESOURCES_NAME"]))
	retcapenergy = zeros(size(inputs["H2_RESOURCES_NAME"]))
	for i in inputs["H2_STOR_ALL"]
		if i in inputs["NEW_CAP_H2_ENERGY"]
			capenergy[i] = value(EP[:vH2CAPENERGY][i])
		end
		if i in inputs["RET_CAP_H2_ENERGY"]
			retcapenergy[i] = value(EP[:vH2RETCAPENERGY][i])
		end
	end

	MaxGen = zeros(size(inputs["H2_RESOURCES_NAME"]))
	for i in 1:H
		MaxGen[i] = value.(EP[:eH2GenTotalCap])[i] * 8760
	end

	AnnualGen = zeros(size(inputs["H2_RESOURCES_NAME"]))
	for i in 1:H
		AnnualGen[i] = sum(inputs["omega"].* (value.(EP[:vH2Gen])[i,:]))
	end

	CapFactor = zeros(size(inputs["H2_RESOURCES_NAME"]))
	for i in 1:H
		if MaxGen[i] == 0
			CapFactor[i] = 0
		else
			CapFactor[i] = AnnualGen[i]/MaxGen[i]
		end
	end
	
	AnnualCO2Emissions = zeros(size(inputs["H2_RESOURCES_NAME"]))
	for i in 1:H
		AnnualCO2Emissions[i] = sum(inputs["omega"].* (value.(EP[:eH2EmissionsByPlant])[i,:]))
	end


	dfCap = DataFrame(
		Resource = inputs["H2_RESOURCES_NAME"], Zone = dfH2Gen[!,:Zone],
		StartCap = dfH2Gen[!,:Existing_Cap_tonne_p_hr],
		RetCap = retcapdischarge[:],
		NewCap = capdischarge[:],
		EndCap = value.(EP[:eH2GenTotalCap]),
		StartEnergyCap = dfH2Gen[!,:Existing_Energy_Cap_tonne],
		RetEnergyCap = retcapenergy[:],
		NewEnergyCap = capenergy[:],
		EndEnergyCap = dfH2Gen[!,:Existing_Energy_Cap_tonne]+capenergy[:]-retcapenergy[:],
		StartChargeCap = dfH2Gen[!,:Existing_Charge_Cap_tonne_p_hr],
		RetChargeCap = retcapcharge[:],
		NewChargeCap = capcharge[:],
		EndChargeCap = dfH2Gen[!,:Existing_Charge_Cap_tonne_p_hr]+capcharge[:]-retcapcharge[:],
		MaxAnnualGeneration = MaxGen[:],
		AnnualGeneration = AnnualGen[:],
		CapacityFactor = CapFactor[:],
		AnnualEmissions = AnnualCO2Emissions[:]
		
	)


	total = DataFrame(
		Resource = "Total", Zone = "n/a",
		StartCap = sum(dfCap[!,:StartCap]), RetCap = sum(dfCap[!,:RetCap]),
		NewCap = sum(dfCap[!,:NewCap]), EndCap = sum(dfCap[!,:EndCap]),
		StartEnergyCap = sum(dfCap[!,:StartEnergyCap]), RetEnergyCap = sum(dfCap[!,:RetEnergyCap]),
		NewEnergyCap = sum(dfCap[!,:NewEnergyCap]), EndEnergyCap = sum(dfCap[!,:EndEnergyCap]),
		StartChargeCap = sum(dfCap[!,:StartChargeCap]), RetChargeCap = sum(dfCap[!,:RetChargeCap]),
		NewChargeCap = sum(dfCap[!,:NewChargeCap]), EndChargeCap = sum(dfCap[!,:EndChargeCap]),
		MaxAnnualGeneration = sum(dfCap[!,:MaxAnnualGeneration]), AnnualGeneration = sum(dfCap[!,:AnnualGeneration]),
		AnnualEmissions = sum(dfCap[!,:AnnualEmissions]),
		CapacityFactor = "-"
	)


	dfCap = vcat(dfCap, total)
	CSV.write(string(path,sep,"HSC_generation_storage_capacity.csv"), dfCap)
	return dfCap
end

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
	write_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model))

Function for reporting the diferent capacities for the different generation technologies (starting capacities or, existing capacities, retired capacities, and new-built capacities).
"""
function write_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	# Capacity decisions
	dfGen = inputs["dfGen"]
	G = inputs["G"]

	capdischarge = zeros(size(inputs["RESOURCES"]))
	for i in inputs["NEW_CAP"]
		if i in inputs["COMMIT"]
			capdischarge[i] = value(EP[:vCAP][i])*dfGen[!,:Cap_Size][i]
		else
			capdischarge[i] = value(EP[:vCAP][i])
		end
	end

	retcapdischarge = zeros(size(inputs["RESOURCES"]))
	for i in inputs["RET_CAP"]
		if i in inputs["COMMIT"]
			retcapdischarge[i] = first(value.(EP[:vRETCAP][i]))*dfGen[!,:Cap_Size][i]
		else
			retcapdischarge[i] = first(value.(EP[:vRETCAP][i]))
		end
	end

	capcharge = zeros(size(inputs["RESOURCES"]))
	retcapcharge = zeros(size(inputs["RESOURCES"]))
	for i in inputs["STOR_ASYMMETRIC"]
		if i in inputs["NEW_CAP_CHARGE"]
			capcharge[i] = value(EP[:vCAPCHARGE][i])
		end
		if i in inputs["RET_CAP_CHARGE"]
			retcapcharge[i] = value(EP[:vRETCAPCHARGE][i])
		end
	end

	capenergy = zeros(size(inputs["RESOURCES"]))
	retcapenergy = zeros(size(inputs["RESOURCES"]))
	for i in inputs["STOR_ALL"]
		if i in inputs["NEW_CAP_ENERGY"]
			capenergy[i] = value(EP[:vCAPENERGY][i])
		end
		if i in inputs["RET_CAP_ENERGY"]
			retcapenergy[i] = value(EP[:vRETCAPENERGY][i])
		end
	end

	MaxGen = zeros(size(inputs["RESOURCES"]))
	for i in 1:G
		MaxGen[i] = value.(EP[:eTotalCap])[i] * 8760
	end

	AnnualGen = zeros(size(inputs["RESOURCES"]))
	for i in 1:G
		AnnualGen[i] = sum(inputs["omega"].* (value.(EP[:vP])[i,:]))
	end

	CapFactor = zeros(size(inputs["RESOURCES"]))
	for i in 1:G
		if MaxGen[i] == 0
			CapFactor[i] = 0
		else
			CapFactor[i] = AnnualGen[i]/MaxGen[i]
		end
	end
	
	dfCap = DataFrame(
		Resource = inputs["RESOURCES"], Zone = dfGen[!,:Zone],
		StartCap = dfGen[!,:Existing_Cap_MW],
		RetCap = retcapdischarge[:],
		NewCap = capdischarge[:],
		EndCap = value.(EP[:eTotalCap]),
		StartEnergyCap = dfGen[!,:Existing_Cap_MWh],
		RetEnergyCap = retcapenergy[:],
		NewEnergyCap = capenergy[:],
		EndEnergyCap = dfGen[!,:Existing_Cap_MWh]+capenergy[:]-retcapenergy[:],
		StartChargeCap = dfGen[!,:Existing_Charge_Cap_MW],
		RetChargeCap = retcapcharge[:],
		NewChargeCap = capcharge[:],
		EndChargeCap = dfGen[!,:Existing_Charge_Cap_MW]+capcharge[:]-retcapcharge[:],
		MaxAnnualGeneration = MaxGen[:],
		AnnualGeneration = AnnualGen[:],
		CapacityFactor = CapFactor[:]
	)
	if setup["ParameterScale"] ==1
		dfCap.StartCap = dfCap.StartCap * ModelScalingFactor
		dfCap.RetCap = dfCap.RetCap * ModelScalingFactor
		dfCap.NewCap = dfCap.NewCap * ModelScalingFactor
		dfCap.EndCap = dfCap.EndCap * ModelScalingFactor
		dfCap.StartEnergyCap = dfCap.StartEnergyCap * ModelScalingFactor
		dfCap.RetEnergyCap = dfCap.RetEnergyCap * ModelScalingFactor
		dfCap.NewEnergyCap = dfCap.NewEnergyCap * ModelScalingFactor
		dfCap.EndEnergyCap = dfCap.EndEnergyCap * ModelScalingFactor
		dfCap.StartChargeCap = dfCap.StartChargeCap * ModelScalingFactor
		dfCap.RetChargeCap = dfCap.RetChargeCap * ModelScalingFactor
		dfCap.NewChargeCap = dfCap.NewChargeCap * ModelScalingFactor
		dfCap.EndChargeCap = dfCap.EndChargeCap * ModelScalingFactor
		dfCap.MaxAnnualGeneration = dfCap.MaxAnnualGeneration * ModelScalingFactor
		dfCap.AnnualGeneration = dfCap.AnnualGeneration * ModelScalingFactor
	end

	total = DataFrame(
		Resource = "Total", Zone = "n/a",
		StartCap = sum(dfCap[!,:StartCap]), RetCap = sum(dfCap[!,:RetCap]),
		NewCap = sum(dfCap[!,:NewCap]), EndCap = sum(dfCap[!,:EndCap]),
		StartEnergyCap = sum(dfCap[!,:StartEnergyCap]), RetEnergyCap = sum(dfCap[!,:RetEnergyCap]),
		NewEnergyCap = sum(dfCap[!,:NewEnergyCap]), EndEnergyCap = sum(dfCap[!,:EndEnergyCap]),
		StartChargeCap = sum(dfCap[!,:StartChargeCap]), RetChargeCap = sum(dfCap[!,:RetChargeCap]),
		NewChargeCap = sum(dfCap[!,:NewChargeCap]), EndChargeCap = sum(dfCap[!,:EndChargeCap]),
		MaxAnnualGeneration = sum(dfCap[!,:MaxAnnualGeneration]), AnnualGeneration = sum(dfCap[!,:AnnualGeneration]),
		CapacityFactor = "-"
	)

	#If H2G2P modeled, write new output capacity file with H2G2P capacity combined
	if setup["ModelH2"] == 1 && setup["ModelH2G2P"] == 1
		# Capacity decisions
		dfH2G2P = inputs["dfH2G2P"]
		H = inputs["H2_G2P_ALL"]
	
		capdischarge_H2G2P = zeros(size(inputs["H2_G2P_NAME"]))
		for i in inputs["H2_G2P_NEW_CAP"]
			if i in inputs["H2_G2P_COMMIT"]
				capdischarge_H2G2P[i] = value(EP[:vH2G2PNewCap][i]) * dfH2G2P[!,:Cap_Size_MW][i]
			else
				capdischarge_H2G2P[i] = value(EP[:vH2G2PNewCap][i])
			end
		end
	
		retcapdischarge_H2G2P = zeros(size(inputs["H2_G2P_NAME"]))
		for i in inputs["H2_G2P_RET_CAP"]
			if i in inputs["H2_G2P_COMMIT"]
				retcapdischarge_H2G2P[i] = first(value.(EP[:vH2G2PRetCap][i])) * dfH2G2P[!,:Cap_Size_MW][i]
			else
				retcapdischarge_H2G2P[i] = first(value.(EP[:vH2G2PRetCap][i]))
			end
		end
	
		startenergycap_H2G2P = zeros(size(1:inputs["H2_G2P_ALL"]))
	
		retenergycap_H2G2P = zeros(size(1:inputs["H2_G2P_ALL"]))

		newenergycap_H2G2P = zeros(size(1:inputs["H2_G2P_ALL"]))
	
		endenergycap_H2G2P = zeros(size(1:inputs["H2_G2P_ALL"]))
	
		startchargecap_H2G2P = zeros(size(1:inputs["H2_G2P_ALL"]))
	
		retchargecap_H2G2P = zeros(size(1:inputs["H2_G2P_ALL"]))

		newchargecap_H2G2P = zeros(size(1:inputs["H2_G2P_ALL"]))

		endchargecap_H2G2P = zeros(size(1:inputs["H2_G2P_ALL"]))
	
		MaxGen_H2G2P = zeros(size(1:inputs["H2_G2P_ALL"]))
		for i in 1:H
			MaxGen_H2G2P[i] = value.(EP[:eH2G2PTotalCap])[i] * 8760
		end
	
		AnnualGen_H2G2P = zeros(size(1:inputs["H2_G2P_ALL"]))
		for i in 1:H
			AnnualGen_H2G2P[i] = sum(inputs["omega"].* (value.(EP[:vPG2P])[i,:]))
		end
	
		CapFactor_H2G2P = zeros(size(1:inputs["H2_G2P_ALL"]))
		for i in 1:H
			if MaxGen_H2G2P[i] == 0
				CapFactor_H2G2P[i] = 0
			else
				CapFactor_H2G2P[i] = AnnualGen_H2G2P[i]/MaxGen_H2G2P[i]
			end
		end
	
		dfCap_H2G2P = DataFrame(
			Resource = inputs["H2_G2P_NAME"], Zone = dfH2G2P[!,:Zone],
			StartCap = dfH2G2P[!,:Existing_Cap_MW],
			RetCap = retcapdischarge_H2G2P[:],
			NewCap = capdischarge_H2G2P[:],
			EndCap = value.(EP[:eH2G2PTotalCap]),
			StartEnergyCap = startenergycap_H2G2P[:],
			RetEnergyCap = retenergycap_H2G2P[:],
			NewEnergyCap = newenergycap_H2G2P[:],
			EndEnergyCap = endenergycap_H2G2P[:],
			StartChargeCap = startchargecap_H2G2P[:],
			RetChargeCap = retchargecap_H2G2P[:],
			NewChargeCap = newchargecap_H2G2P[:],
			EndChargeCap = endchargecap_H2G2P[:],
			MaxAnnualGeneration = MaxGen_H2G2P[:],
			AnnualGeneration = AnnualGen_H2G2P[:],
			CapacityFactor = CapFactor_H2G2P[:]
		)
	
	
		total_w_H2G2P = DataFrame(
				Resource = "Total", Zone = "n/a",
				StartCap = sum(dfCap[!,:StartCap]) + sum(dfCap_H2G2P[!,:StartCap]), RetCap = sum(dfCap[!,:RetCap]) + sum(dfCap_H2G2P[!,:RetCap]),
				NewCap = sum(dfCap[!,:NewCap]) + sum(dfCap_H2G2P[!,:NewCap]), EndCap = sum(dfCap[!,:EndCap]) + sum(dfCap_H2G2P[!,:EndCap]),
				StartEnergyCap = sum(dfCap[!,:StartEnergyCap]) + sum(dfCap_H2G2P[!,:StartEnergyCap]), RetEnergyCap = sum(dfCap[!,:RetEnergyCap]) + sum(dfCap_H2G2P[!,:RetEnergyCap]),
				NewEnergyCap = sum(dfCap[!,:NewEnergyCap]) + sum(dfCap_H2G2P[!,:NewEnergyCap]),EndEnergyCap = sum(dfCap[!,:EndEnergyCap]) + sum(dfCap_H2G2P[!,:EndEnergyCap]),
				StartChargeCap = sum(dfCap[!,:StartChargeCap]) + sum(dfCap_H2G2P[!,:StartChargeCap]), RetChargeCap = sum(dfCap[!,:RetChargeCap]) + sum(dfCap_H2G2P[!,:RetChargeCap]),
				NewChargeCap = sum(dfCap[!,:NewChargeCap]) + sum(dfCap_H2G2P[!,:NewChargeCap]),EndChargeCap = sum(dfCap[!,:EndChargeCap]) + sum(dfCap_H2G2P[!,:EndChargeCap]),
				MaxAnnualGeneration = sum(dfCap[!,:MaxAnnualGeneration]) + sum(dfCap_H2G2P[!,:MaxAnnualGeneration]), AnnualGeneration = sum(dfCap[!,:AnnualGeneration]) + sum(dfCap_H2G2P[!,:AnnualGeneration]),
				CapacityFactor = "-"
			)

		dfCap_Total_w_H2G2P = vcat(dfCap, dfCap_H2G2P, total_w_H2G2P)
		CSV.write(string(path,sep,"capacity_w_H2G2P.csv"), dfCap_Total_w_H2G2P)

	end

	if setup["ModelBIO"] == 1 && setup["BIO_Electricity_On"] == 1
		dfbiorefinery = inputs["dfbiorefinery"]
		B = inputs["BIO_RES_ALL"]

		newcap_BioE = zeros(size(inputs["BIO_RESOURCES_NAME"]))
		for i in inputs["BIO_E"]
			newcap_BioE[i] = value(EP[:vCapacity_BIO_per_type][i]) * dfbiorefinery[!,:BioElectricity_yield_MWh_per_tonne][i]
		end

		startcap_BioE = zeros(size(inputs["BIO_RESOURCES_NAME"]))

		retcap_BioE = zeros(size(inputs["BIO_RESOURCES_NAME"]))

		startenergycap_BioE = zeros(size(inputs["BIO_RESOURCES_NAME"]))

		retenergycap_BioE = zeros(size(inputs["BIO_RESOURCES_NAME"]))

		newenergycap_BioE = zeros(size(inputs["BIO_RESOURCES_NAME"]))

		endenergycap_BioE = zeros(size(inputs["BIO_RESOURCES_NAME"]))

		startchargecap_BioE = zeros(size(inputs["BIO_RESOURCES_NAME"]))

		retchargecap_BioE = zeros(size(inputs["BIO_RESOURCES_NAME"]))

		newchargecap_BioE = zeros(size(inputs["BIO_RESOURCES_NAME"]))

		endchargecap_BioE = zeros(size(inputs["BIO_RESOURCES_NAME"]))

		AnnualGen_BioE = zeros(size(1:inputs["BIO_RES_ALL"]))
		for i in 1:B
			AnnualGen_BioE[i] = sum(inputs["omega"].* (value.(EP[:eBioelectricity_produced_per_plant_per_time])[i,:]))
		end
	
		MaxGen_BioE = zeros(size(1:inputs["BIO_RES_ALL"]))
		for i in 1:B
			MaxGen_BioE[i] = value.(EP[:vCapacity_BIO_per_type])[i] * dfbiorefinery[!,:BioElectricity_yield_MWh_per_tonne][i] * 8760
		end

		CapFactor_BioE = zeros(size(1:inputs["BIO_RES_ALL"]))
		for i in 1:B
			if MaxGen_BioE[i] == 0
				CapFactor_BioE[i] = 0
			else
				CapFactor_BioE[i] = AnnualGen_BioE[i]/MaxGen_BioE[i]
			end
		end
	
		dfBioE_Cap = DataFrame(
			Resource = inputs["BIO_RESOURCES_NAME"], Zone = dfbiorefinery[!,:Zone],
			StartCap = startcap_BioE[:],
			RetCap = retcap_BioE[:],
			NewCap = newcap_BioE[:],
			EndCap = newcap_BioE[:],
			StartEnergyCap = startenergycap_BioE[:],
			RetEnergyCap = retenergycap_BioE[:],
			NewEnergyCap = newenergycap_BioE[:],
			EndEnergyCap = endenergycap_BioE[:],
			StartChargeCap = startchargecap_BioE[:],
			RetChargeCap = retchargecap_BioE[:],
			NewChargeCap = newchargecap_BioE[:],
			EndChargeCap = endchargecap_BioE[:],
			MaxAnnualGeneration = MaxGen_BioE[:],
			AnnualGeneration = AnnualGen_BioE[:],
			CapacityFactor = CapFactor_BioE[:]
		)
	
		if setup["ParameterScale"] ==1
			dfBioE_Cap.newcap_BioE = dfBioE_Cap.newcap_BioE * ModelScalingFactor
			dfBioE_Cap.newcap_BioE = dfBioE_Cap.newcap_BioE * ModelScalingFactor
			dfBioE_Cap.MaxGen_BioE = dfBioE_Cap.MaxGen_BioE * ModelScalingFactor
			dfBioE_Cap.AnnualGen_BioE = dfBioE_Cap.AnnualGen_BioE * ModelScalingFactor
		end
	
		total_w_BioE = DataFrame(
				Resource = "Total", Zone = "n/a",
				StartCap = sum(dfCap[!,:StartCap]) + sum(dfBioE_Cap[!,:StartCap]), RetCap = sum(dfCap[!,:RetCap]) + sum(dfBioE_Cap[!,:RetCap]),
				NewCap = sum(dfCap[!,:NewCap]) + sum(dfBioE_Cap[!,:NewCap]), EndCap = sum(dfCap[!,:EndCap]) + sum(dfBioE_Cap[!,:EndCap]),
				StartEnergyCap = sum(dfCap[!,:StartEnergyCap]) + sum(dfBioE_Cap[!,:StartEnergyCap]), RetEnergyCap = sum(dfCap[!,:RetEnergyCap]) + sum(dfBioE_Cap[!,:RetEnergyCap]),
				NewEnergyCap = sum(dfCap[!,:NewEnergyCap]) + sum(dfBioE_Cap[!,:NewEnergyCap]),EndEnergyCap = sum(dfCap[!,:EndEnergyCap]) + sum(dfBioE_Cap[!,:EndEnergyCap]),
				StartChargeCap = sum(dfCap[!,:StartChargeCap]) + sum(dfBioE_Cap[!,:StartChargeCap]), RetChargeCap = sum(dfCap[!,:RetChargeCap]) + sum(dfBioE_Cap[!,:RetChargeCap]),
				NewChargeCap = sum(dfCap[!,:NewChargeCap]) + sum(dfBioE_Cap[!,:NewChargeCap]),EndChargeCap = sum(dfCap[!,:EndChargeCap]) + sum(dfBioE_Cap[!,:EndChargeCap]),
				MaxAnnualGeneration = sum(dfCap[!,:MaxAnnualGeneration]) + sum(dfBioE_Cap[!,:MaxAnnualGeneration]), AnnualGeneration = sum(dfCap[!,:AnnualGeneration]) + sum(dfBioE_Cap[!,:AnnualGeneration]),
				CapacityFactor = "-"
			)
	
		dfCap_Total_w_BioE = vcat(dfCap, dfBioE_Cap, total_w_BioE)
		CSV.write(string(path,sep,"capacity_w_BioE.csv"), dfCap_Total_w_BioE)
	end

	if setup["ModelH2"] == 1 && setup["ModelH2G2P"] == 1 && setup["ModelBIO"] == 1 && setup["BIO_Electricity_On"] == 1
		total_w_H2G2P_BioE = DataFrame(
			Resource = "Total", Zone = "n/a",
			StartCap = sum(dfCap[!,:StartCap]) + sum(dfCap_H2G2P[!,:StartCap]) + sum(dfBioE_Cap[!,:StartCap]), RetCap = sum(dfCap[!,:RetCap]) + sum(dfCap_H2G2P[!,:RetCap]) + sum(dfBioE_Cap[!,:RetCap]),
			NewCap = sum(dfCap[!,:NewCap]) + sum(dfCap_H2G2P[!,:NewCap]) + sum(dfBioE_Cap[!,:NewCap]), EndCap = sum(dfCap[!,:EndCap]) + sum(dfCap_H2G2P[!,:EndCap]) + sum(dfBioE_Cap[!,:EndCap]),
			StartEnergyCap = sum(dfCap[!,:StartEnergyCap]) + sum(dfCap_H2G2P[!,:StartEnergyCap]) + sum(dfBioE_Cap[!,:StartEnergyCap]), RetEnergyCap = sum(dfCap[!,:RetEnergyCap]) + sum(dfCap_H2G2P[!,:RetEnergyCap]) + sum(dfBioE_Cap[!,:RetEnergyCap]),
			NewEnergyCap = sum(dfCap[!,:NewEnergyCap]) + sum(dfCap_H2G2P[!,:NewEnergyCap]) + sum(dfBioE_Cap[!,:NewEnergyCap]) ,EndEnergyCap = sum(dfCap[!,:EndEnergyCap]) + sum(dfCap_H2G2P[!,:EndEnergyCap]) + sum(dfBioE_Cap[!,:EndEnergyCap]),
			StartChargeCap = sum(dfCap[!,:StartChargeCap]) + sum(dfCap_H2G2P[!,:StartChargeCap]) + sum(dfBioE_Cap[!,:StartChargeCap]) , RetChargeCap = sum(dfCap[!,:RetChargeCap]) + sum(dfCap_H2G2P[!,:RetChargeCap]) + sum(dfBioE_Cap[!,:RetChargeCap]),
			NewChargeCap = sum(dfCap[!,:NewChargeCap]) + sum(dfCap_H2G2P[!,:NewChargeCap]) + sum(dfBioE_Cap[!,:NewChargeCap]) ,EndChargeCap = sum(dfCap[!,:EndChargeCap]) + sum(dfCap_H2G2P[!,:EndChargeCap]) + sum(dfBioE_Cap[!,:EndChargeCap]),
			MaxAnnualGeneration = sum(dfCap[!,:MaxAnnualGeneration]) + sum(dfCap_H2G2P[!,:MaxAnnualGeneration]) + sum(dfBioE_Cap[!,:MaxAnnualGeneration]) , AnnualGeneration = sum(dfCap[!,:AnnualGeneration]) + sum(dfCap_H2G2P[!,:AnnualGeneration]) + sum(dfBioE_Cap[!,:AnnualGeneration]),
			CapacityFactor = "-"
		)
		dfCap_Total_w_BioE = vcat(dfCap, dfCap_H2G2P, dfBioE_Cap, total_w_H2G2P_BioE)
		CSV.write(string(path,sep,"capacity_w_H2G2P_BioE.csv"), dfCap_Total_w_BioE)
	end

	dfCap = vcat(dfCap, total)
	CSV.write(string(path,sep,"capacity.csv"), dfCap)


	return dfCap
end

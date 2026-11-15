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
	write_co2_storage_balance_zone(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting total CO2 storage balance across different zones.
"""
function write_co2_storage_balance_zone(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	Z = inputs["Z"]     # Number of zones

<<<<<<< Updated upstream
	dfCost = DataFrame(Costs = ["Power_CCS", "H2_CCS", "DAC_Capture", "DAC_Fuel_CCS", "Biorefinery_Capture", "Synfuel_Production_Capture", "Synfuel_Production_Consumption", "CO2_Pipeline_Import", "CO2_Storage", "Total"])
=======
	dfCost = DataFrame(Costs = ["Power CCS", "H2 CCS", "DAC Capture", "DAC Fuel CCS", "Bio Elec Capture", "Bio H2 Capture", "Bio LF Capture", "Bio NG Capture", "Bio Ethanol Capture","Synfuel Plant Capture", "Synfuel Plant Consumption", "Syn NG Plant Capture", "Syn NG Plant Consumption", "NG Power CCS", "NG H2 CCS", "NG DAC CCS", "CO2 Pipeline Import", "CO2 Storage", "Ethylene Production Capture","Ethylene Usage","Total"])
>>>>>>> Stashed changes

	Power_CCS = sum(sum(inputs["omega"].* (value.(EP[:ePower_CO2_captured_per_zone_per_time])[z,:])) for z in 1:Z)

	if setup["ModelH2"] == 1
		H2_CCS = sum(sum(inputs["omega"].* (value.(EP[:eHydrogen_CO2_captured_per_zone_per_time])[z,:])) for z in 1:Z)
	else
		H2_CCS = 0
	end

	DAC_Capture =  sum(sum(inputs["omega"].* (value.(EP[:eDAC_CO2_Captured_per_zone_per_time])[z,:])) for z in 1:Z)
	DAC_Fuel_CCS = sum(sum(inputs["omega"].* (value.(EP[:eDAC_Fuel_CO2_captured_per_zone_per_time])[z,:])) for z in 1:Z)

<<<<<<< Updated upstream
	if setup["ModelBIO"] == 1
		Biorefinery_Capture = sum(sum(inputs["omega"].* (value.(EP[:eBiorefinery_CO2_captured_per_zone_per_time])[z,:])) for z in 1:Z)
	else
		Biorefinery_Capture = 0
=======
	Bio_ELEC_Capture = 0
	Bio_H2_Capture = 0
	Bio_LF_Capture = 0
	Bio_NG_Capture = 0
	Bio_Ethanol_Capture = 0

	if setup["ModelBESC"] == 1

		if setup["Bio_ELEC_On"] == 1
			Bio_ELEC_Capture = sum(sum(inputs["omega"].* (value.(EP[:eBio_ELEC_CO2_captured_per_zone_per_time])[z,:])) for z in 1:Z)
		end

		if setup["Bio_H2_On"] == 1
			Bio_H2_Capture = sum(sum(inputs["omega"].* (value.(EP[:eBio_H2_CO2_captured_per_zone_per_time])[z,:])) for z in 1:Z)
		end

		if setup["Bio_LF_On"] == 1
			Bio_LF_Capture = sum(sum(inputs["omega"].* (value.(EP[:eBio_LF_CO2_captured_per_zone_per_time])[z,:])) for z in 1:Z)
		end

		if setup["Bio_NG_On"] == 1
			Bio_NG_Capture = sum(sum(inputs["omega"].* (value.(EP[:eBio_NG_CO2_captured_per_zone_per_time])[z,:])) for z in 1:Z)
		end

		if setup["Bio_Ethanol_On"] == 1
			Bio_Ethanol_Capture = sum(sum(inputs["omega"].* (value.(EP[:eBio_Ethanol_CO2_captured_per_zone_per_time])[z,:])) for z in 1:Z)
		end

	
>>>>>>> Stashed changes
	end

	if setup["ModelLiquidFuels"] == 1
		Synfuel_Production_Capture = sum(sum(inputs["omega"].* (value.(EP[:eSyn_Fuels_CO2_Capture_Per_Zone_Per_Time])[z,:])) for z in 1:Z)
		Synfuel_Production_Consumption = - sum(sum(inputs["omega"].* (value.(EP[:eSynFuelCO2Cons_Per_Zone_Per_Time])[z,:])) for z in 1:Z)
	else
		Synfuel_Production_Capture = 0
		Synfuel_Production_Consumption = 0
	end

<<<<<<< Updated upstream
=======
	Syn_NG_Production_Capture = 0
	Syn_NG_Production_Consumption = 0
	NG_Power_CCS = 0
	NG_H2_CCS = 0
	NG_DAC_CCS = 0
 
	if setup["ModelNGSC"] == 1 
		if setup["ModelSyntheticNG"] == 1
			Syn_NG_Production_Capture = sum(sum(inputs["omega"].* (value.(EP[:eSyn_NG_CO2_Capture_Per_Zone_Per_Time])[z,:])) for z in 1:Z)
			Syn_NG_Production_Consumption = - sum(sum(inputs["omega"].* (value.(EP[:eSyn_NG_CO2_Cons_Per_Zone_Per_Time])[z,:])) for z in 1:Z)
		end

		NG_Power_CCS = sum(sum(inputs["omega"].* (value.(EP[:ePower_NG_CO2_captured_per_zone_per_time])[z,:])) for z in 1:Z)

		if setup["ModelH2"] == 1
			NG_H2_CCS = sum(sum(inputs["omega"].* (value.(EP[:eHydrogen_NG_CO2_captured_per_zone_per_time])[z,:])) for z in 1:Z)
		end

		if setup["ModelCSC"] == 1
			NG_DAC_CCS = sum(sum(inputs["omega"].* (value.(EP[:eDAC_NG_CO2_captured_per_zone_per_time])[z,:])) for z in 1:Z)
		end
	end

	Ethylene_Production_Capture = 0
	Ethylene_Usage = 0

	if setup["ModelEthyleneProduction"] == 1 && setup["ModelEthyleneRetrofitting"] == 0
		Ethylene_Production_Capture = sum(sum(inputs["omega"].* (value.(EP[:eEthylene_CO2_Capture_Per_Zone_Per_Time_GF])[z,:])) for z in 1:Z) + sum(sum(inputs["omega"].* (value.(EP[:eEthylene_CO2_Capture_Per_Zone_Per_Time_EP])[z,:])) for z in 1:Z)			
		Ethylene_Usage = -sum(sum(inputs["omega"].* (value.(EP[:eEthylene_CO2inCCS_RES])[z,:])) for z in 1:Z) - sum(sum(inputs["omega"].* (value.(EP[:eEthylene_CO2inCCS_Plant])[z,:])) for z in 1:Z)	
			
	end
	if setup["ModelEthyleneProduction"] == 1 && setup["ModelEthyleneRetrofitting"] == 1
		Ethylene_Production_Capture = sum(sum(inputs["omega"].* (value.(EP[:eEthylene_CO2_Capture_Per_Zone_Per_Time_GF])[z,:])) for z in 1:Z) + sum(sum(inputs["omega"].* (value.(EP[:eEthylene_CO2_Capture_Per_Zone_Per_Time_EP])[z,:])) for z in 1:Z)	 + sum(sum(inputs["omega"].* (value.(EP[:eEthylene_CO2_Capture_Per_Zone_Per_Time_Retrofit])[z,:])) for z in 1:Z)			
		Ethylene_Usage = -sum(sum(inputs["omega"].* (value.(EP[:eEthylene_CO2inCCS_RES])[z,:])) for z in 1:Z) - sum(sum(inputs["omega"].* (value.(EP[:eEthylene_CO2inCCS_Plant])[z,:])) for z in 1:Z)	
			
	end

	CO2_Pipeline_Import = 0

>>>>>>> Stashed changes
	if setup["ModelCO2Pipelines"] == 1
		CO2_Pipeline_Import = sum(sum(inputs["omega"].* (value.(EP[:ePipeZoneCO2Demand])[:,z])) for z in 1:Z)
	else
		CO2_Pipeline_Import = 0
	end

	CO2_Storage = - sum(sum(inputs["omega"].* (value.(EP[:eCO2_Injected_per_zone])[z,:])) for z in 1:Z)

	# Define total costs
	cTotal = Power_CCS + H2_CCS + DAC_Capture + DAC_Fuel_CCS + Biorefinery_Capture + Synfuel_Production_Capture + Synfuel_Production_Consumption + CO2_Pipeline_Import + CO2_Storage

	if setup["ParameterScale"] == 1
		Power_CCS = Power_CCS * ModelScalingFactor
		H2_CCS = H2_CCS * ModelScalingFactor
		DAC_Capture = DAC_Capture * ModelScalingFactor
		DAC_Fuel_CCS = DAC_Fuel_CCS * ModelScalingFactor
		Biorefinery_Capture = Biorefinery_Capture * ModelScalingFactor
		Synfuel_Production_Capture = Synfuel_Production_Capture * ModelScalingFactor
		Synfuel_Production_Consumption = Synfuel_Production_Consumption * ModelScalingFactor
		CO2_Pipeline_Import = CO2_Pipeline_Import * ModelScalingFactor
		CO2_Storage = CO2_Storage * ModelScalingFactor
		cTotal = cTotal * ModelScalingFactor
	end

<<<<<<< Updated upstream
	# Define total column, i.e. column 2
	dfCost[!,Symbol("Total")] = [Power_CCS, H2_CCS, DAC_Capture, DAC_Fuel_CCS, Biorefinery_Capture, Synfuel_Production_Capture, Synfuel_Production_Consumption, CO2_Pipeline_Import, CO2_Storage, cTotal]
=======
	# Define total CO2 storage balance
	cTotal = Bio_Ethanol_Capture + Power_CCS + H2_CCS + DAC_Capture + DAC_Fuel_CCS + Bio_ELEC_Capture + Bio_H2_Capture + Bio_LF_Capture + Bio_NG_Capture + Synfuel_Production_Capture + Synfuel_Production_Consumption + Syn_NG_Production_Capture + Syn_NG_Production_Consumption + NG_Power_CCS + NG_H2_CCS + NG_DAC_CCS + CO2_Pipeline_Import + CO2_Storage + Ethylene_Production_Capture + Ethylene_Usage

	# Define total column, i.e. column 2
	dfCost[!,Symbol("Total")] = [Power_CCS, H2_CCS, DAC_Capture, DAC_Fuel_CCS, Bio_ELEC_Capture, Bio_H2_Capture, Bio_LF_Capture, Bio_NG_Capture, Bio_Ethanol_Capture, Synfuel_Production_Capture, Synfuel_Production_Consumption, Syn_NG_Production_Capture, Syn_NG_Production_Consumption, NG_Power_CCS, NG_H2_CCS, NG_DAC_CCS, CO2_Pipeline_Import, CO2_Storage,Ethylene_Production_Capture, Ethylene_Usage, cTotal]
>>>>>>> Stashed changes

	################################################################################################################################
	# Computing zonal cost breakdown by cost category
	for z in 1:Z
		tempPower_CCS = 0
		tempH2_CCS = 0
		tempDAC_Capture = 0
		tempDAC_Fuel_CCS = 0
<<<<<<< Updated upstream
		tempBiorefinery_Capture = 0
=======
		tempBio_ELEC_Capture = 0
		tempBio_H2_Capture = 0
		tempBio_LF_Capture = 0
		tempBio_NG_Capture = 0
		tempBio_Ethanol_Capture = 0
>>>>>>> Stashed changes
		tempSynfuel_Production_Capture = 0
		tempEthylene_Production_Capture = 0
		tempEthylene_Usage = 0
		tempSynfuel_Production_Consumption = 0
		tempCO2_Pipeline_Import = 0
		tempCO2_Storage = 0

		tempPower_CCS = tempPower_CCS + sum(inputs["omega"].* (value.(EP[:ePower_CO2_captured_per_zone_per_time])[z,:]))

		if setup["ModelH2"] == 1
			tempH2_CCS = tempH2_CCS + sum(inputs["omega"].* (value.(EP[:eHydrogen_CO2_captured_per_zone_per_time])[z,:]))
		end

		tempDAC_Capture = tempDAC_Capture + sum(inputs["omega"].* (value.(EP[:eDAC_CO2_Captured_per_zone_per_time])[z,:]))
		tempDAC_Fuel_CCS = tempDAC_Fuel_CCS + sum(inputs["omega"].* (value.(EP[:eDAC_Fuel_CO2_captured_per_zone_per_time])[z,:]))

<<<<<<< Updated upstream
		if setup["ModelBIO"] == 1
			tempBiorefinery_Capture = tempBiorefinery_Capture + sum(inputs["omega"].* (value.(EP[:eBiorefinery_CO2_captured_per_zone_per_time])[z,:]))
=======
		if setup["ModelBESC"] == 1
			if setup["Bio_ELEC_On"] == 1
				tempBio_ELEC_Capture = tempBio_ELEC_Capture + sum(inputs["omega"].* (value.(EP[:eBio_ELEC_CO2_captured_per_zone_per_time])[z,:]))
			end

			if setup["Bio_H2_On"] == 1
				tempBio_H2_Capture = tempBio_H2_Capture + sum(inputs["omega"].* (value.(EP[:eBio_H2_CO2_captured_per_zone_per_time])[z,:]))
			end

			if setup["Bio_LF_On"] == 1
				tempBio_LF_Capture = tempBio_LF_Capture + sum(inputs["omega"].* (value.(EP[:eBio_LF_CO2_captured_per_zone_per_time])[z,:]))
			end

			if setup["Bio_NG_On"] == 1
				tempBio_NG_Capture = tempBio_NG_Capture + sum(inputs["omega"].* (value.(EP[:eBio_NG_CO2_captured_per_zone_per_time])[z,:]))
			end

			if setup["Bio_Ethanol_On"] == 1
				tempBio_Ethanol_Capture = tempBio_Ethanol_Capture + sum(inputs["omega"].* (value.(EP[:eBio_Ethanol_CO2_captured_per_zone_per_time])[z,:]))
			end

>>>>>>> Stashed changes
		end

		if setup["ModelLiquidFuels"] == 1
			tempSynfuel_Production_Capture = tempSynfuel_Production_Capture + sum(inputs["omega"].* (value.(EP[:eSyn_Fuels_CO2_Capture_Per_Zone_Per_Time])[z,:]))
			tempSynfuel_Production_Consumption = tempSynfuel_Production_Consumption - sum(inputs["omega"].* (value.(EP[:eSynFuelCO2Cons_Per_Zone_Per_Time])[z,:]))
		end

		if setup["ModelEthyleneProduction"] == 1 && setup["ModelEthyleneRetrofitting"] == 0
			tempEthylene_Production_Capture = tempEthylene_Production_Capture + sum(inputs["omega"].* (value.(EP[:eEthylene_CO2_Capture_Per_Zone_Per_Time_GF])[z,:]))+sum(inputs["omega"].* (value.(EP[:eEthylene_CO2_Capture_Per_Zone_Per_Time_EP])[z,:]))
			tempEthylene_Usage = tempEthylene_Usage - sum(inputs["omega"].* (value.(EP[:eEthylene_CO2inCCS_RES])[z,:])) - sum(inputs["omega"].* (value.(EP[:eEthylene_CO2inCCS_Plant])[z,:]))			
			
		end

		if setup["ModelEthyleneProduction"] == 1 && setup["ModelEthyleneRetrofitting"] == 1
			tempEthylene_Production_Capture = tempEthylene_Production_Capture + sum(inputs["omega"].* (value.(EP[:eEthylene_CO2_Capture_Per_Zone_Per_Time_GF])[z,:]))+sum(inputs["omega"].* (value.(EP[:eEthylene_CO2_Capture_Per_Zone_Per_Time_EP])[z,:]))+sum(inputs["omega"].* (value.(EP[:eEthylene_CO2_Capture_Per_Zone_Per_Time_Retrofit])[z,:]))
			tempEthylene_Usage = tempEthylene_Usage - sum(inputs["omega"].* (value.(EP[:eEthylene_CO2inCCS_RES])[z,:])) - sum(inputs["omega"].* (value.(EP[:eEthylene_CO2inCCS_Plant])[z,:]))			
			
		end

		if setup["ModelCO2Pipelines"] == 1
			tempCO2_Pipeline_Import = tempCO2_Pipeline_Import + sum(inputs["omega"].* (value.(EP[:ePipeZoneCO2Demand])[:,z]))
		end

		tempCO2_Storage = tempCO2_Storage - sum(inputs["omega"].* (value.(EP[:eCO2_Injected_per_zone])[z,:]))

		tempCTotal = tempPower_CCS + tempH2_CCS + tempDAC_Capture + tempDAC_Fuel_CCS + tempBiorefinery_Capture + tempSynfuel_Production_Capture + tempSynfuel_Production_Consumption + tempCO2_Pipeline_Import + tempCO2_Storage

		if setup["ParameterScale"] == 1
			tempPower_CCS = tempPower_CCS * ModelScalingFactor
			tempH2_CCS = tempH2_CCS * ModelScalingFactor
			tempDAC_Capture = tempDAC_Capture * ModelScalingFactor
			tempDAC_Fuel_CCS = tempDAC_Fuel_CCS * ModelScalingFactor
			tempBiorefinery_Capture = tempBiorefinery_Capture * ModelScalingFactor
			tempSynfuel_Production_Capture = tempSynfuel_Production_Capture * ModelScalingFactor
			tempSynfuel_Production_Consumption = tempSynfuel_Production_Consumption * ModelScalingFactor
			tempCO2_Pipeline_Import = tempCO2_Pipeline_Import * ModelScalingFactor
			tempCO2_Storage = tempCO2_Storage * ModelScalingFactor
			tempCTotal = tempCTotal * ModelScalingFactor
		end

<<<<<<< Updated upstream
		dfCost[!,Symbol("Zone$z")] = [tempPower_CCS, tempH2_CCS, tempDAC_Capture, tempDAC_Fuel_CCS, tempBiorefinery_Capture, tempSynfuel_Production_Capture, tempSynfuel_Production_Consumption, tempCO2_Pipeline_Import, tempCO2_Storage, tempCTotal]
=======
		tempCTotal = tempBio_Ethanol_Capture + tempPower_CCS + tempH2_CCS + tempDAC_Capture + tempDAC_Fuel_CCS + tempBio_ELEC_Capture + tempBio_H2_Capture + tempBio_LF_Capture + tempBio_NG_Capture + tempSynfuel_Production_Capture + tempSynfuel_Production_Consumption + tempSyn_NG_Production_Capture + tempSyn_NG_Production_Consumption + tempNG_Power_CCS + tempNG_H2_CCS + tempNG_DAC_CCS + tempCO2_Pipeline_Import + tempCO2_Storage + tempEthylene_Production_Capture + tempEthylene_Usage

		dfCost[!,Symbol("Zone$z")] = [tempPower_CCS, tempH2_CCS, tempDAC_Capture, tempDAC_Fuel_CCS, tempBio_ELEC_Capture, tempBio_H2_Capture, tempBio_LF_Capture, tempBio_NG_Capture, tempBio_Ethanol_Capture, tempSynfuel_Production_Capture, tempSynfuel_Production_Consumption, tempSyn_NG_Production_Capture,  tempSyn_NG_Production_Consumption,  tempNG_Power_CCS, tempNG_H2_CCS, tempNG_DAC_CCS, tempCO2_Pipeline_Import, tempCO2_Storage, tempEthylene_Production_Capture, tempEthylene_Usage, tempCTotal]
>>>>>>> Stashed changes
	end

	CSV.write(string(path,sep,"CSC_storage_balanace_zone.csv"), dfCost)

end
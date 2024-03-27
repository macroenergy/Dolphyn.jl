

@doc raw"""
	write_co2_storage_balance_zone(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting total CO2 storage balance across different zones.
"""
function write_co2_storage_balance_zone(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	Z = inputs["Z"]::Int     # Number of zones

	dfCost = DataFrame(Costs = ["Power_CCS", "H2_CCS", "DAC_Capture", "DAC_Fuel_CCS", "Biorefinery_Capture", "Synfuel_Production_Capture", "Synfuel_Production_Consumption", "CO2_Pipeline_Import", "CO2_Storage", "Total"])

	Power_CCS = sum(sum(inputs["omega"].* (value.(EP[:ePower_CO2_captured_per_zone_per_time])[z,:])) for z in 1:Z)

	if setup["ModelH2"] == 1
		H2_CCS = sum(sum(inputs["omega"].* (value.(EP[:eHydrogen_CO2_captured_per_zone_per_time])[z,:])) for z in 1:Z)
	else
		H2_CCS = 0
	end

	DAC_Capture =  sum(sum(inputs["omega"].* (value.(EP[:eDAC_CO2_Captured_per_zone_per_time])[z,:])) for z in 1:Z)
	DAC_Fuel_CCS = sum(sum(inputs["omega"].* (value.(EP[:eDAC_Fuel_CO2_captured_per_zone_per_time])[z,:])) for z in 1:Z)

	if setup["ModelBIO"] == 1
		Biorefinery_Capture = sum(sum(inputs["omega"].* (value.(EP[:eBiorefinery_CO2_captured_per_zone_per_time])[z,:])) for z in 1:Z)
	else
		Biorefinery_Capture = 0
	end

	if setup["ModelLiquidFuels"] == 1
		Synfuel_Production_Capture = sum(sum(inputs["omega"].* (value.(EP[:eSyn_Fuels_CO2_Capture_Per_Zone_Per_Time])[z,:])) for z in 1:Z)
		Synfuel_Production_Consumption = - sum(sum(inputs["omega"].* (value.(EP[:eSynFuelCO2Cons_Per_Zone_Per_Time])[z,:])) for z in 1:Z)
	else
		Synfuel_Production_Capture = 0
		Synfuel_Production_Consumption = 0
	end

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

	# Define total column, i.e. column 2
	dfCost[!,Symbol("Total")] = [Power_CCS, H2_CCS, DAC_Capture, DAC_Fuel_CCS, Biorefinery_Capture, Synfuel_Production_Capture, Synfuel_Production_Consumption, CO2_Pipeline_Import, CO2_Storage, cTotal]

	################################################################################################################################
	# Computing zonal cost breakdown by cost category
	for z in 1:Z
		tempPower_CCS = 0
		tempH2_CCS = 0
		tempDAC_Capture = 0
		tempDAC_Fuel_CCS = 0
		tempBiorefinery_Capture = 0
		tempSynfuel_Production_Capture = 0
		tempSynfuel_Production_Consumption = 0
		tempCO2_Pipeline_Import = 0
		tempCO2_Storage = 0

		tempPower_CCS = tempPower_CCS + sum(inputs["omega"].* (value.(EP[:ePower_CO2_captured_per_zone_per_time])[z,:]))

		if setup["ModelH2"] == 1
			tempH2_CCS = tempH2_CCS + sum(inputs["omega"].* (value.(EP[:eHydrogen_CO2_captured_per_zone_per_time])[z,:]))
		end

		tempDAC_Capture = tempDAC_Capture + sum(inputs["omega"].* (value.(EP[:eDAC_CO2_Captured_per_zone_per_time])[z,:]))
		tempDAC_Fuel_CCS = tempDAC_Fuel_CCS + sum(inputs["omega"].* (value.(EP[:eDAC_Fuel_CO2_captured_per_zone_per_time])[z,:]))

		if setup["ModelBIO"] == 1
			tempBiorefinery_Capture = tempBiorefinery_Capture + sum(inputs["omega"].* (value.(EP[:eBiorefinery_CO2_captured_per_zone_per_time])[z,:]))
		end

		if setup["ModelLiquidFuels"] == 1
			tempSynfuel_Production_Capture = tempSynfuel_Production_Capture + sum(inputs["omega"].* (value.(EP[:eSyn_Fuels_CO2_Capture_Per_Zone_Per_Time])[z,:]))
			tempSynfuel_Production_Consumption = tempSynfuel_Production_Consumption - sum(inputs["omega"].* (value.(EP[:eSynFuelCO2Cons_Per_Zone_Per_Time])[z,:]))
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

		dfCost[!,Symbol("Zone$z")] = [tempPower_CCS, tempH2_CCS, tempDAC_Capture, tempDAC_Fuel_CCS, tempBiorefinery_Capture, tempSynfuel_Production_Capture, tempSynfuel_Production_Consumption, tempCO2_Pipeline_Import, tempCO2_Storage, tempCTotal]
	end

	CSV.write(string(path,sep,"CSC_storage_balanace_zone.csv"), dfCost)

end
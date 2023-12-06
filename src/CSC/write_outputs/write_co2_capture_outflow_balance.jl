"""
GenX: An Configurable Capacity Expansion Model
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

@doc raw"""
	write_co2_capture_outflow_balance(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting co2 capture and outflow across all zones.
"""
function write_co2_capture_outflow_balance(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	
	Z = inputs["Z"]     # Number of zones
    S = inputs["S"]     # Number of CO2 Sites
	
    ## CO2 balance for each zone
	dfCost = DataFrame(Costs = ["Power_CCS", "H2_CCS", "DAC_Capture", "DAC_Fuel_CCS", "Biorefinery_Capture", "Synfuel_Production_Capture", "Synfuel_Production_Consumption", "CO2_Trunk_Pipeline_Import", "CO2_Spur_Pipeline_Outflow", "CO2_Demand", "Total"])
    
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

    if setup["ModelSynFuels"] == 1
		Synfuel_Production_Capture = sum(sum(inputs["omega"].* (value.(EP[:eSyn_Fuels_CO2_Capture_Per_Zone_Per_Time])[z,:])) for z in 1:Z)
		Synfuel_Production_Consumption = - sum(sum(inputs["omega"].* (value.(EP[:eSynFuelCO2Cons_Per_Zone_Per_Time])[z,:])) for z in 1:Z)
	else
		Synfuel_Production_Capture = 0
		Synfuel_Production_Consumption = 0
	end

    if setup["ModelCO2Pipelines"] == 1
		CO2_Trunk_Pipeline_Import = sum(sum(inputs["omega"].* (value.(EP[:ePipeZoneCO2Demand_Trunk])[:,z])) for z in 1:Z)
        CO2_Spur_Pipeline_Outflow = - sum(sum(inputs["omega"].* (value.(EP[:ePipeZoneCO2Demand_Outflow_Spur])[:,z])) for z in 1:Z)
	else
		CO2_Trunk_Pipeline_Import = 0
        CO2_Spur_Pipeline_Outflow = 0
	end

    if setup["Exogeneous_CO2_Demand"] == 1
        CO2_Demand = sum(sum(inputs["omega"].* inputs["CO2_D"][:,z]) for z in 1:Z)
    else
        CO2_Demand = 0
    end

    # Define Annual Balance
    cTotal = Power_CCS + H2_CCS + DAC_Capture + DAC_Fuel_CCS + Biorefinery_Capture + Synfuel_Production_Capture + Synfuel_Production_Consumption + CO2_Trunk_Pipeline_Import + CO2_Spur_Pipeline_Outflow + CO2_Demand

    if setup["ParameterScale"] == 1
		Power_CCS = Power_CCS * ModelScalingFactor
		H2_CCS = H2_CCS * ModelScalingFactor
		DAC_Capture = DAC_Capture * ModelScalingFactor
		DAC_Fuel_CCS = DAC_Fuel_CCS * ModelScalingFactor
		Biorefinery_Capture = Biorefinery_Capture * ModelScalingFactor
		Synfuel_Production_Capture = Synfuel_Production_Capture * ModelScalingFactor
		Synfuel_Production_Consumption = Synfuel_Production_Consumption * ModelScalingFactor
		CO2_Trunk_Pipeline_Import = CO2_Trunk_Pipeline_Import * ModelScalingFactor
		CO2_Spur_Pipeline_Outflow = CO2_Spur_Pipeline_Outflow * ModelScalingFactor
        CO2_Demand = CO2_Demand * ModelScalingFactor
		cTotal = cTotal * ModelScalingFactor
	end

    # Define total column, i.e. column 2
	dfCost[!,Symbol("Total")] = [Power_CCS, H2_CCS, DAC_Capture, DAC_Fuel_CCS, Biorefinery_Capture, Synfuel_Production_Capture, Synfuel_Production_Consumption, CO2_Trunk_Pipeline_Import, CO2_Spur_Pipeline_Outflow, CO2_Demand, cTotal]
    
    ################################################################################################################################

    for z in 1:Z
        tempPower_CCS = 0
		tempH2_CCS = 0
		tempDAC_Capture = 0
		tempDAC_Fuel_CCS = 0
		tempBiorefinery_Capture = 0
		tempSynfuel_Production_Capture = 0
		tempSynfuel_Production_Consumption = 0
		tempCO2_Trunk_Pipeline_Import = 0
        tempCO2_Spur_Pipeline_Outflow = 0
		tempCO2_Demand = 0

        tempPower_CCS = tempPower_CCS + sum(inputs["omega"].* (value.(EP[:ePower_CO2_captured_per_zone_per_time])[z,:]))

        if setup["ModelH2"] == 1
			tempH2_CCS = tempH2_CCS + sum(inputs["omega"].* (value.(EP[:eHydrogen_CO2_captured_per_zone_per_time])[z,:]))
		end

        tempDAC_Capture = tempDAC_Capture + sum(inputs["omega"].* (value.(EP[:eDAC_CO2_Captured_per_zone_per_time])[z,:]))
		tempDAC_Fuel_CCS = tempDAC_Fuel_CCS + sum(inputs["omega"].* (value.(EP[:eDAC_Fuel_CO2_captured_per_zone_per_time])[z,:]))

        if setup["ModelBIO"] == 1
			tempBiorefinery_Capture = tempBiorefinery_Capture + sum(inputs["omega"].* (value.(EP[:eBiorefinery_CO2_captured_per_zone_per_time])[z,:]))
		end

		if setup["ModelSynFuels"] == 1
			tempSynfuel_Production_Capture = tempSynfuel_Production_Capture + sum(inputs["omega"].* (value.(EP[:eSyn_Fuels_CO2_Capture_Per_Zone_Per_Time])[z,:]))
			tempSynfuel_Production_Consumption = tempSynfuel_Production_Consumption - sum(inputs["omega"].* (value.(EP[:eSynFuelCO2Cons_Per_Zone_Per_Time])[z,:]))
		end

        if setup["ModelCO2Pipelines"] == 1
			tempCO2_Trunk_Pipeline_Import = tempCO2_Trunk_Pipeline_Import + sum(inputs["omega"].* (value.(EP[:ePipeZoneCO2Demand_Trunk])[:,z]))
            tempCO2_Spur_Pipeline_Outflow = - tempCO2_Spur_Pipeline_Outflow - sum(inputs["omega"].* (value.(EP[:ePipeZoneCO2Demand_Outflow_Spur])[:,z]))
		end

        if setup["Exogeneous_CO2_Demand"] == 1
            #tempCO2_Demand = tempCO2_Demand + sum(inputs["omega"].* (inputs["CO2_D"][z,:]))
			tempCO2_Demand = tempCO2_Demand + sum(inputs["omega"].* (inputs["CO2_D"][:,z]))
        end

        tempCTotal = tempPower_CCS + tempH2_CCS + tempDAC_Capture + tempDAC_Fuel_CCS + tempBiorefinery_Capture + tempSynfuel_Production_Capture + tempSynfuel_Production_Consumption + tempCO2_Trunk_Pipeline_Import + tempCO2_Spur_Pipeline_Outflow + tempCO2_Demand

        if setup["ParameterScale"] == 1
			tempPower_CCS = tempPower_CCS * ModelScalingFactor
			tempH2_CCS = tempH2_CCS * ModelScalingFactor
			tempDAC_Capture = tempDAC_Capture * ModelScalingFactor
			tempDAC_Fuel_CCS = tempDAC_Fuel_CCS * ModelScalingFactor
			tempBiorefinery_Capture = tempBiorefinery_Capture * ModelScalingFactor
			tempSynfuel_Production_Capture = tempSynfuel_Production_Capture * ModelScalingFactor
			tempSynfuel_Production_Consumption = tempSynfuel_Production_Consumption * ModelScalingFactor
			tempCO2_Trunk_Pipeline_Import = tempCO2_Trunk_Pipeline_Import * ModelScalingFactor
            tempCO2_Spur_Pipeline_Outflow = tempCO2_Spur_Pipeline_Outflow * ModelScalingFactor
			tempCO2_Demand = tempCO2_Demand * ModelScalingFactor
			tempCTotal = tempCTotal * ModelScalingFactor
		end

        dfCost[!,Symbol("Zone$z")] = [tempPower_CCS, tempH2_CCS, tempDAC_Capture, tempDAC_Fuel_CCS, tempBiorefinery_Capture, tempSynfuel_Production_Capture, tempSynfuel_Production_Consumption, tempCO2_Trunk_Pipeline_Import, tempCO2_Spur_Pipeline_Outflow, tempCO2_Demand, tempCTotal]

    end

    CSV.write(string(path,sep,"CSC_capture_outflow_balanace.csv"), dfCost)

end
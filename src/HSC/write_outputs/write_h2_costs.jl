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
	write_h2_costs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the costs of hydrogen supply chain pertaining to the objective function (fixed, variable O&M etc.).
"""
function write_h2_costs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	## Cost results
	dfH2Gen = inputs["dfH2Gen"]

	H = inputs["H2_RES_ALL"]
	H2_STOR_ALL = inputs["H2_STOR_ALL"] # Set of all h2 storage resources

	SEG = inputs["SEG"]  # Number of lines
	Z = inputs["Z"]     # Number of zones
	T = inputs["T"]     # Number of time steps (hours)
	H2_GEN_COMMIT = inputs["H2_GEN_COMMIT"] # H2 production technologies with unit commitment

	if setup["ModelH2G2P"] == 1
		dfH2G2P = inputs["dfH2G2P"]
		cG2PFix = value.(EP[:eTotalH2G2PCFix])
		cG2PVar = value.(EP[:eTotalCH2G2PVarOut])

		if !isempty(inputs["H2_G2P_COMMIT"])
			if setup["ParameterScale"] == 1
				#cH2Start = value.(EP[:eTotalH2G2PCStart]) * (ModelScalingFactor^2)
				cH2Start_G2P = value.(EP[:eTotalH2G2PCStart]) * (ModelScalingFactor^2)
			else
				#cH2Start = value.(EP[:eTotalH2G2PCStart])
				cH2Start_G2P = value.(EP[:eTotalH2G2PCStart])
			end

		else
			#cH2Start = 0
			cH2Start_G2P = 0
		end

	else
		cG2PFix = 0
		#cH2Start = 0
		cH2Start_G2P = 0
		cG2PVar = 0
	end

    if setup["ModelH2Trucks"] == 1
		cH2Fix_Truck = value.(EP[:eTotalCFixH2TruckEnergy]) + value.(EP[:eTotalCFixH2TruckCharge])
		cTruckVar = value.(EP[:OPEX_Truck]) + value.(EP[:OPEX_Truck_Compression])
	else
		cH2Fix_Truck = 0
		cTruckVar = 0
	end

	dfH2Cost = DataFrame(Costs = ["cH2Total", "cH2Fix_Gen", "cH2Fix_G2P", "cH2Fix_Stor", "cH2Fix_Truck", "cH2Var", "cH2NSE", "cH2Start", "cH2Start_G2P", "cNetworkExp","cElectricity_LCOH_Calculation_Only","H2_Produced_LCOH_Calculation_Only","LCOH"])
	if setup["ParameterScale"]==1 # Convert costs in millions to $
		cH2Var = (value(EP[:eTotalCH2GenVarOut]) + (!isempty(inputs["H2_FLEX"]) ? value(EP[:eTotalCH2VarFlexIn]) : 0) + (!isempty(inputs["H2_STOR_ALL"]) ? value(EP[:eTotalCVarH2StorIn]) : 0) + cG2PVar + cTruckVar) * ModelScalingFactor^2
		cH2Fix_Gen = value(EP[:eTotalH2GenCFix]) * ModelScalingFactor^2
		cH2Fix_G2P = cG2PFix * ModelScalingFactor^2
		cH2Var_G2P = cG2PVar* ModelScalingFactor^2
		cH2Fix_Stor = ((!isempty(inputs["H2_STOR_ALL"]) ? value(EP[:eTotalCFixH2Energy]) +value(EP[:eTotalCFixH2Charge]) : 0)) * ModelScalingFactor^2
	else
		cH2Var = (value(EP[:eTotalCH2GenVarOut])+ (!isempty(inputs["H2_FLEX"]) ? value(EP[:eTotalCH2VarFlexIn]) : 0)+ (!isempty(inputs["H2_STOR_ALL"]) ? value(EP[:eTotalCVarH2StorIn]) : 0))
		cH2Fix_Gen = value(EP[:eTotalH2GenCFix])
		cH2Fix_G2P = cG2PFix
		cH2Var_G2P = cG2PVar
		cH2Fix_Stor = ((!isempty(inputs["H2_STOR_ALL"]) ? value(EP[:eTotalCFixH2Energy]) + value(EP[:eTotalCFixH2Charge]) : 0))
	end

	# Adding emissions penalty to variable cost depending on type of emissions policy constraint
	# Emissions penalty is already scaled by adjusting the value of carbon price used in emissions_HSC.jl
	if((setup["CO2Cap"]==4 && setup["SystemCO2Constraint"]==2)||(setup["H2CO2Cap"]==4 && setup["SystemCO2Constraint"]==1))
		cH2Var  = cH2Var + value(EP[:eCH2GenTotalEmissionsPenalty])
	end

	cH2Start = 0

	if !isempty(inputs["H2_GEN_COMMIT"])
		if setup["ParameterScale"]==1 # Convert costs in millions to $
			cH2Start += value(EP[:eTotalH2GenCStart])*ModelScalingFactor^2
		else
	    	cH2Start += value(EP[:eTotalH2GenCStart])
		end
	end

	if Z > 1
		if setup["ModelH2Pipelines"] == 1
			if setup["ParameterScale"]==1 # Convert costs in millions to $
				cH2NetworkExpCost = value(EP[:eCH2Pipe])*ModelScalingFactor^2
			else
				cH2NetworkExpCost = value(EP[:eCH2Pipe])
			end
		else
			cH2NetworkExpCost=0
		end
	else
		cH2NetworkExpCost=0
	end

	#Electricity cost for calculating LCOH (Does not account into system cost)
	#No need scale parameter as power price as price in $/MWh or $/GWh for H2 power usage in MWh or GWh
	#No need multiply by time weight, since the output shadow price of electricity is EP[:cPowerBalance]/inputs["omega"][t]
	#And when we multiply inputs["omega"][t] to EP[:cPowerBalance]/inputs["omega"][t]*EP[:eH2NetpowerConsumptionByAll][t,z] the term cancels each other out

	cElectricity_LCOH_Calculation_Only = sum(dual.(EP[:cPowerBalance]).* value.(EP[:eH2NetpowerConsumptionByAll]))

	#Obtain the total amount of H2 produced in tonnes
	AnnualGen = zeros(size(inputs["H2_RESOURCES_NAME"]))

	for i in 1:H
		AnnualGen[i] = sum(inputs["omega"].* (value.(EP[:vH2Gen])[i,:]))
	end

	H2_Produced_LCOH_Calculation_Only = sum(AnnualGen[i] for i in 1:H) - sum(AnnualGen[i] for i in H2_STOR_ALL)

	#Add in fixed and var cost of Bio-H2
	#if setup["ModelBIO"] == 1 && setup["BIO_H2_On"] == 1
	#	cBioH2_Fixed_LCOH_Calculation_Only = value.(EP[:eFixed_Cost_BIO_total])
	#	cBioH2_Var_LCOH_Calculation_Only = value.(EP[:eVar_Cost_BIO])
	#	cBioH2_Herb_Resource_LCOH_Calculation_Only = value(EP[:eHerb_biomass_supply_cost])
	#	cBioH2_Wood_Resource_LCOH_Calculation_Only = value(EP[:eWood_biomass_supply_cost])

	#	AnnualGen_BioH2 = zeros(size(1:inputs["BIO_RES_ALL"]))
	#	for i in 1:inputs["BIO_RES_ALL"]
	#		AnnualGen_BioH2[i] = sum(inputs["omega"].* (value.(EP[:eBiohydrogen_produced_per_plant_per_time])[i,:]))
	#	end
	#	Total_AnnualGen_BioH2 = sum(AnnualGen_BioH2)

		###Add in wood and herb cost for Bio-H2
	#else
	#	cBioH2_Fixed_LCOH_Calculation_Only = 0
	#	cBioH2_Var_LCOH_Calculation_Only = 0
	#	Total_AnnualGen_BioH2 = 0
	#	cBioH2_Herb_Resource_LCOH_Calculation_Only = 0
	#	cBioH2_Wood_Resource_LCOH_Calculation_Only = 0
	#end

	#H2_Produced_LCOH_Calculation_Only = Total_AnnualGen + Total_AnnualGen_BioH2
	#Calculate LCOH in terms of $/tonne H2
	#LCOH = (cH2Total - cH2Fix_G2P - cH2Start_G2P - value(EP[:eTotalH2CNSE]) + cElectricity_LCOH_Calculation_Only + cBioH2_Fixed_LCOH_Calculation_Only + cBioH2_Var_LCOH_Calculation_Only + cBioH2_Herb_Resource_LCOH_Calculation_Only + cBioH2_Wood_Resource_LCOH_Calculation_Only)/H2_Produced_LCOH_Calculation_Only
	
    cH2Total = cH2Var + cH2Fix_Gen + cH2Fix_G2P + cH2Fix_Stor + cH2Fix_Truck + cH2Start + cH2Start_G2P + value(EP[:eTotalH2CNSE]) + cH2NetworkExpCost
	LCOH = (cH2Total - cH2Fix_G2P - cH2Start_G2P - value(EP[:eTotalH2CNSE]) + cElectricity_LCOH_Calculation_Only)/H2_Produced_LCOH_Calculation_Only

    dfH2Cost[!,Symbol("Total")] = [cH2Total, cH2Fix_Gen, cH2Fix_G2P, cH2Fix_Stor, cH2Fix_Truck, cH2Var, value(EP[:eTotalH2CNSE]), cH2Start, cH2Start_G2P, cH2NetworkExpCost, cElectricity_LCOH_Calculation_Only, H2_Produced_LCOH_Calculation_Only, LCOH]

	for z in 1:Z
		tempCTotal = 0
		tempC_H2_Fix_Gen = 0
		tempC_H2_Fix_G2P = 0
		tempC_H2_Var_G2P = 0
		tempC_H2_Fix_Stor = 0
		tempC_H2_Var = 0
		tempC_H2_Start = 0
		tempC_H2_Start_G2P = 0

		for y in intersect(inputs["H2_STOR_ALL"], dfH2Gen[dfH2Gen[!,:Zone].==z,:R_ID])
			tempC_H2_Fix_Stor = tempC_H2_Fix_Stor +
			(y in inputs["H2_STOR_ALL"] ? value.(EP[:eCFixH2Energy])[y] : 0) +
			(y in inputs["H2_STOR_ALL"] ? value.(EP[:eCFixH2Charge])[y] : 0)
		end

		for y in dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID]
			tempC_H2_Fix_Gen = tempC_H2_Fix_Gen +
				value.(EP[:eH2GenCFix])[y]
			tempC_H2_Var = tempC_H2_Var +
				(y in inputs["H2_STOR_ALL"] ? sum(value.(EP[:eCVarH2Stor_in])[y,:]) : 0) +
				(y in inputs["H2_FLEX"] ? sum(value.(EP[:eCH2VarFlex_in])[y,:]) : 0) +
				sum(value.(EP[:eCH2GenVar_out])[y,:])
			if !isempty(H2_GEN_COMMIT)
				tempCTotal = tempCTotal +
					value.(EP[:eH2GenCFix])[y] +
					(y in inputs["H2_STOR_ALL"] ? value.(EP[:eCFixH2Energy])[y] : 0) +
					(y in inputs["H2_STOR_ALL"] ? value.(EP[:eCFixH2Charge])[y] : 0) +
					(y in inputs["H2_STOR_ALL"] ? sum(value.(EP[:eCVarH2Stor_in])[y,:]) : 0) +
					(y in inputs["H2_FLEX"] ? sum(value.(EP[:eCH2VarFlex_in])[y,:]) : 0) +
					sum(value.(EP[:eCH2GenVar_out])[y,:]) +
					(y in inputs["H2_GEN_COMMIT"] ? sum(value.(EP[:eH2GenCStart])[y,:]) : 0)
				tempC_H2_Start = tempC_H2_Start +
					(y in inputs["H2_GEN_COMMIT"] ? sum(value.(EP[:eH2GenCStart])[y,:]) : 0)
			else
				tempCTotal = tempCTotal +
					value.(EP[:eH2GenCFix])[y] +
					(y in inputs["H2_STOR_ALL"] ? value.(EP[:eCFixH2Energy])[y] : 0) +
					(y in inputs["H2_STOR_ALL"] ? value.(EP[:eCFixH2Charge])[y] : 0) +
					(y in inputs["H2_STOR_ALL"] ? sum(value.(EP[:eCVarH2Stor_in])[y,:]) : 0) +
					(y in inputs["H2_FLEX"] ? sum(value.(EP[:eCH2VarFlex_in])[y,:]) : 0) +
					sum(value.(EP[:eCH2GenVar_out])[y,:])
			end
		end

		if setup["ModelH2G2P"] == 1
			for  y in dfH2G2P[dfH2G2P[!,:Zone].==z,:][!,:R_ID]

				tempC_H2_Fix_G2P += value.(EP[:eH2G2PCFix])[y]
				tempC_H2_Var_G2P += sum(value.(EP[:eCH2G2PVar_out])[y,:])
				tempCTotal += value.(EP[:eH2G2PCFix])[y] + sum(value.(EP[:eCH2G2PVar_out])[y,:])

				if !isempty(inputs["H2_G2P_COMMIT"])
					if y in inputs["H2_G2P_COMMIT"]
						tempC_H2_Start_G2P += value.(EP[:eTotalH2G2PCStartK])[y]
						tempCTotal += value.(EP[:eTotalH2G2PCStartK])[y]
					end
				else
					tempC_H2_Start_G2P = 0
				end
			end
		end


		if setup["ParameterScale"] == 1 # Convert costs in millions to $
			tempC_H2_Fix_Gen = tempC_H2_Fix_Gen * (ModelScalingFactor^2)
			tempC_H2_Fix_G2P = tempC_H2_Fix_G2P * (ModelScalingFactor^2)
			tempC_H2_Var_G2P = tempC_H2_Var_G2P * (ModelScalingFactor^2)
			tempC_H2_Fix_Stor = tempC_H2_Fix_Stor * (ModelScalingFactor^2)
			tempC_H2_Var = tempC_H2_Var * (ModelScalingFactor^2)
			tempCTotal = tempCTotal * (ModelScalingFactor^2)
			tempC_H2_Start = tempC_H2_Start * (ModelScalingFactor^2)
			tempC_H2_Start_G2P = tempC_H2_Start_G2P * (ModelScalingFactor^2)
		end

		# Add emisions penalty related costs if the constraints are active
		# Emissions penalty is already scaled previously depending on value of ParameterScale and hence not scaled here
		if((setup["CO2Cap"]==4 && setup["SystemCO2Constraint"]==2)||(setup["H2CO2Cap"]==4 && setup["SystemCO2Constraint"]==1))
			tempC_H2_Var  = tempC_H2_Var + value.(EP[:eCH2EmissionsPenaltybyZone])[z]
			tempCTotal = tempCTotal +value.(EP[:eCH2EmissionsPenaltybyZone])[z]
		end

		if setup["ParameterScale"] == 1 # Convert costs in millions to $
			tempC_H2_NSE = sum(value.(EP[:eH2CNSE])[:,:,z])* (ModelScalingFactor^2)
		else
			tempC_H2_NSE = sum(value.(EP[:eH2CNSE])[:,:,z])
		end

		tempCTotal = tempCTotal + tempC_H2_NSE

		dfH2Cost[!,Symbol("Zone$z")] = [tempCTotal, tempC_H2_Fix_Gen, tempC_H2_Fix_G2P, tempC_H2_Fix_Stor, "-", tempC_H2_Var, tempC_H2_NSE, tempC_H2_Start, tempC_H2_Start_G2P, "-","-","-","-"]

end
	CSV.write(string(path, sep, "HSC_costs.csv"), dfH2Cost)
end

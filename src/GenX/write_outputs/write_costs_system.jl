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
	write_costs_system(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the costs pertaining to the objective function (fixed, variable O&M etc.) for all sectors (Power, H2, CSC, BESC, SF).
"""
function write_costs_system(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	## Cost results
	dfGen = inputs["dfGen"]
	SEG = inputs["SEG"]  # Number of lines
	Z = inputs["Z"]     # Number of zones
	T = inputs["T"]     # Number of time steps (hours)

	if setup["ModelH2"] == 1
		dfH2Gen = inputs["dfH2Gen"]
		SEG = inputs["SEG"]  # Number of lines
		Z = inputs["Z"]     # Number of zones
		T = inputs["T"]     # Number of time steps (hours)
		H2_GEN_COMMIT = inputs["H2_GEN_COMMIT"] # H2 production technologies with unit commitment
	end

	if setup["ModelCO2"] == 1
		dfDAC = inputs["dfDAC"]
		dfCO2CaptureComp = inputs["dfCO2CaptureComp"]
		dfCO2Storage = inputs["dfCO2Storage"]
	end

	if setup["ModelBIO"] == 1
		dfbiorefinery = inputs["dfbiorefinery"]
	end
	
	if setup["ModelSynFuels"] == 1
		dfSynFuels= inputs["dfSynFuels"]
	end


	dfCost = DataFrame(Costs = ["cTotal", "cFix_Thermal", "cFix_VRE", "cFix_Trans_VRE", "cFix_Must_Run", "cFix_Hydro", "cFix_Stor", "cVar", "cNSE", "cStart", "cUnmetRsv", "cNetworkExp", "cH2Fix_Gen", "cH2Fix_G2P", "cH2Fix_Stor", "cH2Fix_Truck", "cH2Var", "cH2NSE", "cH2Start", "cH2NetworkExp", "cDACFix", "cDACVar", "cCO2Comp", "cCO2Stor", "cCO2Injection", "cCO2NetworkExp", "cBiorefineryFix", "cBiorefineryVar", "cHerb", "cWood", "cSFFix", "cSFVar", "cSFByProdRev", "CSFConvDieselFuelCost","CSFConvJetfuelFuelCost","CSFConvGasolineFuelCost", "cPower_Total", "cHSC_Total","cCSC_Total","cBiorefinery_Total","cBioresource_Total","cSF_Prod","cConv_Fuels","cHydro_Must_Run"])


	if setup["ParameterScale"] == 1
		cVar = (value(EP[:eTotalCVarOut])+ (!isempty(inputs["STOR_ALL"]) ? value(EP[:eTotalCVarIn]) : 0) + (!isempty(inputs["FLEX"]) ? value(EP[:eTotalCVarFlexIn]) : 0)) * (ModelScalingFactor^2)
		cFix_Thermal = value(EP[:eCFix_Thermal]) * (ModelScalingFactor^2)
		cFix_VRE = value(EP[:eCFix_VRE]) * (ModelScalingFactor^2)
		cFix_VRE_Trans = value(EP[:eCFix_VRE_Trans_Total]) * (ModelScalingFactor^2)
		cFix_Must_Run = value(EP[:eCFix_Must_Run]) * (ModelScalingFactor^2)
		cFix_Hydro = value(EP[:eCFix_Hydro]) * (ModelScalingFactor^2)
		cFix_Stor = (value(EP[:eCFix_Stor_Inv]) + (!isempty(inputs["STOR_ALL"]) ? value(EP[:eTotalCFixEnergy]) : 0) + (!isempty(inputs["STOR_ASYMMETRIC"]) ? value(EP[:eTotalCFixCharge]) : 0)) * (ModelScalingFactor^2)
		cNSE =  value(EP[:eTotalCNSE]) * (ModelScalingFactor^2)
		#cTotal = cVar + cFix + cNSE
		#dfCost[!,Symbol("Total")] = [cTotal, cFix, cVar, cNSE, 0, 0, 0]
	else
		cVar = (value(EP[:eTotalCVarOut])+ (!isempty(inputs["STOR_ALL"]) ? value(EP[:eTotalCVarIn]) : 0) + (!isempty(inputs["FLEX"]) ? value(EP[:eTotalCVarFlexIn]) : 0))
		#cVar = value(EP[:eTotalCVarOut])+(!isempty(inputs["STOR_ALL"]) ? value(EP[:eTotalCVarIn]) : 0) + (!isempty(inputs["FLEX"]) ? value(EP[:eTotalCVarFlexIn]) : 0)
		cFix_Thermal = value(EP[:eCFix_Thermal])
		cFix_VRE = value(EP[:eCFix_VRE])
		cFix_VRE_Trans = value(EP[:eCFix_VRE_Trans_Total])
		cFix_Must_Run = value(EP[:eCFix_Must_Run])
		cFix_Hydro = value(EP[:eCFix_Hydro])
		cFix_Stor = (value(EP[:eCFix_Stor_Inv]) + (!isempty(inputs["STOR_ALL"]) ? value(EP[:eTotalCFixEnergy]) : 0) + (!isempty(inputs["STOR_ASYMMETRIC"]) ? value(EP[:eTotalCFixCharge]) : 0))
		cNSE = value(EP[:eTotalCNSE])
		#cTotal = cVar + cFix + cNSE
	end

	# Adding emissions penalty to variable cost depending on type of emissions policy constraint
	# Emissions penalty is already scaled by adjusting the value of carbon price used in emissions_HSC.jl
	if setup["CO2Cap"]==4
		cVar  = cVar + value(EP[:eCGenTotalEmissionsPenalty])
	end

	# Start cost
	if setup["UCommit"]>=1
		if setup["ParameterScale"] == 1
			cStartCost = value(EP[:eTotalCStart]) * (ModelScalingFactor^2)
		else
			cStartCost = value(EP[:eTotalCStart])
		end
	else
		cStartCost =0
		#cTotal += dfCost[!,2][5]
	end

	# Reserve cost
	if setup["Reserves"]==1
		if setup["ParameterScale"] == 1
			cRsvCost = value(EP[:eTotalCRsvPen]) * (ModelScalingFactor^2)
		else
			cRsvCost = value(EP[:eTotalCRsvPen])
		end
	else
		cRsvCost = 0
		#cTotal += dfCost[!,2][6]
	end

	# Network expansion cost
	if setup["NetworkExpansion"] == 1 && Z > 1
		if setup["ParameterScale"] == 1
			cNetworkExpansionCost = value(EP[:eTotalCNetworkExp]) * (ModelScalingFactor^2)
		else
			cNetworkExpansionCost = value(EP[:eTotalCNetworkExp])
		end

	else
		cNetworkExpansionCost =0
		#cTotal += dfCost[!,2][7]
	end

	cH2Var = 0
	cH2Fix_Gen = 0
	cH2Fix_G2P = 0
	cH2Var_G2P = 0
	cH2Fix_Stor = 0
	cH2Fix_Truck = 0
	cH2Var = 0
	cH2NSE = 0
	cH2Start = 0
	cH2NetworkExpCost = 0

	if setup["ModelH2"] == 1
		if setup["ModelH2G2P"] == 1
			dfH2G2P = inputs["dfH2G2P"]
			cG2PFix = value.(EP[:eTotalH2G2PCFix])
			cG2PVar = value.(EP[:eTotalCH2G2PVarOut])
	
			if !isempty(inputs["H2_G2P_COMMIT"])
				if setup["ParameterScale"] == 1
					cH2Start = value.(EP[:eTotalH2G2PCStart]) * (ModelScalingFactor^2)
				else
					cH2Start = value.(EP[:eTotalH2G2PCStart])
				end
	
			else
				cH2Start = 0
			end
	
		else
			cG2PFix = 0
			cH2Start = 0
			cG2PVar = 0
		end
	
		if setup["ModelH2Trucks"] == 1
			cH2Fix_Truck = value.(EP[:eTotalCFixH2TruckEnergy]) + value.(EP[:eTotalCFixH2TruckCharge])
			cTruckVar = value.(EP[:OPEX_Truck]) + value.(EP[:OPEX_Truck_Compression])
		else
			cH2Fix_Truck = 0
			cTruckVar = 0
		end

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
			end
		else
			cH2NetworkExpCost=0
		end
		
		cH2NSE = value(EP[:eTotalH2CNSE])
	end

	if setup["ModelCO2"] == 1
		if setup["ParameterScale"] == 1
			cDACVar = value(EP[:eVar_OM_DAC]) * ModelScalingFactor^2
			cDACFix = value(EP[:eFixed_Cost_DAC_total]) * ModelScalingFactor^2
			cCO2Comp =  value(EP[:eFixed_Cost_CO2_Capture_Comp_total]) * ModelScalingFactor^2
			cCO2Stor = value(EP[:eFixed_Cost_CO2_Storage_total]) * ModelScalingFactor^2
			cCO2Injection= value(EP[:eVar_OM_CO2_Injection_total]) * ModelScalingFactor^2

			if setup["ModelCO2Pipelines"] == 1
				cCO2NetworkExpansion = value(EP[:eCCO2Pipe]) * ModelScalingFactor^2
			else
				cCO2NetworkExpansion = 0
			end
		else
			cDACVar = value(EP[:eVar_OM_DAC])
			cDACFix = value(EP[:eFixed_Cost_DAC_total])
			cCO2Comp = value(EP[:eFixed_Cost_CO2_Capture_Comp_total])
			cCO2Stor = value(EP[:eFixed_Cost_CO2_Storage_total])
			cCO2Injection= value(EP[:eVar_OM_CO2_Injection_total])
			
			if setup["ModelCO2Pipelines"] == 1
				cCO2NetworkExpansion = value(EP[:eCCO2Pipe])
			else
				cCO2NetworkExpansion = 0
			end
		end

	else
		cDACVar	= 0
		cDACFix = 0
		cCO2Comp = 0
		cCO2Stor = 0
		cCO2Injection = 0
		cCO2NetworkExpansion = 0
	end

	if setup["ModelBIO"] == 1
		if setup["ParameterScale"] == 1
			cBiorefineryVar = value(EP[:eVar_Cost_BIO]) * ModelScalingFactor^2
			cBiorefineryFix = value(EP[:eFixed_Cost_BIO_total]) * ModelScalingFactor^2
			cHerb =  value(EP[:eHerb_biomass_supply_cost]) * ModelScalingFactor^2
			cWood = value(EP[:eWood_biomass_supply_cost]) * ModelScalingFactor^2
		else
			cBiorefineryVar = value(EP[:eVar_Cost_BIO])
			cBiorefineryFix = value(EP[:eFixed_Cost_BIO_total])
			cHerb = value(EP[:eHerb_biomass_supply_cost])
			cWood = value(EP[:eWood_biomass_supply_cost])
		end
	else
		cBiorefineryVar = 0
		cBiorefineryFix = 0
		cHerb = 0
		cWood = 0
	end

	if setup["ModelSynFuels"] == 1
		if setup["ParameterScale"]==1 # Convert costs in millions to $
			cSFVar = value(EP[:eTotalCSFProdVarOut])*ModelScalingFactor^2
			cSFFix = value(EP[:eFixed_Cost_Syn_Fuel_total])*ModelScalingFactor^2
			cSFByProdRev = - value(EP[:eTotalCSFByProdRevenueOut])*ModelScalingFactor^2
			if setup["AllowConventionalDiesel"] == 1
				cSFConvDieselFuelCost = value(EP[:eTotalCLFDieselVarOut])*ModelScalingFactor^2
			else
				cSFConvDieselFuelCost = 0
			end
	
			if setup["AllowConventionalJetfuel"] == 1
				cSFConvJetfuelFuelCost = value(EP[:eTotalCLFJetfuelVarOut])*ModelScalingFactor^2
			else
				cSFConvJetfuelFuelCost = 0
			end
	
			if setup["AllowConventionalGasoline"] == 1
				cSFConvGasolineFuelCost = value(EP[:eTotalCLFGasolineVarOut])*ModelScalingFactor^2
			else
				cSFConvGasolineFuelCost = 0
			end
		else
			cSFVar = value(EP[:eTotalCSFProdVarOut])
			cSFFix = value(EP[:eFixed_Cost_Syn_Fuel_total])
			cSFByProdRev = - value(EP[:eTotalCSFByProdRevenueOut])
			
			if setup["AllowConventionalDiesel"] == 1
				cSFConvDieselFuelCost = value(EP[:eTotalCLFDieselVarOut])
			else
				cSFConvDieselFuelCost = 0
			end
	
			if setup["AllowConventionalJetfuel"] == 1
				cSFConvJetfuelFuelCost = value(EP[:eTotalCLFJetfuelVarOut])
			else
				cSFConvJetfuelFuelCost = 0
			end
	
			if setup["AllowConventionalGasoline"] == 1
				cSFConvGasolineFuelCost = value(EP[:eTotalCLFGasolineVarOut])
			else
				cSFConvGasolineFuelCost = 0
			end
		end
	else
		cSFVar = 0
		cSFFix = 0
		cSFByProdRev = 0
		cSFConvDieselFuelCost = 0
		cSFConvJetfuelFuelCost = 0
		cSFConvGasolineFuelCost = 0
	end
	cFix_VRE_Trans

	# Define total costs
	cPower_Total = cFix_Thermal + cFix_VRE + cFix_VRE_Trans + cFix_Must_Run + cFix_Hydro + cFix_Stor + cVar + cNSE + cStartCost + cRsvCost + cNetworkExpansionCost
	cHSC_Total = cH2Var + cH2Fix_Gen + cH2Fix_G2P + cH2Fix_Stor + cH2Fix_Truck + cH2Start + cH2NSE + cH2NetworkExpCost
	cCSC_Total = cDACFix + cDACVar + cCO2Comp + cCO2Stor + cCO2Injection + cCO2NetworkExpansion
	cBiorefinery = cBiorefineryFix + cBiorefineryVar
	cBioresources = cHerb + cWood
	cSF_Prod = cSFVar + cSFFix + cSFByProdRev
	cConv_Fuels = cSFConvDieselFuelCost + cSFConvJetfuelFuelCost + cSFConvGasolineFuelCost
	cHydro_Must_Run = cFix_Must_Run + cFix_Hydro

	cTotal = cFix_Thermal + cFix_VRE + cFix_VRE_Trans + cFix_Must_Run + cFix_Hydro + cFix_Stor + cVar + cNSE + cStartCost + cRsvCost + cNetworkExpansionCost + cH2Var + cH2Fix_Gen + cH2Fix_G2P + cH2Fix_Stor + cH2Fix_Truck + cH2Start + cH2NSE + cH2NetworkExpCost + cDACFix + cDACVar + cCO2Comp + cCO2Stor + cCO2NetworkExpansion + cBiorefineryFix + cBiorefineryVar + cHerb + cWood + cSFVar + cSFFix + cSFByProdRev + cSFConvDieselFuelCost + cSFConvJetfuelFuelCost + cSFConvGasolineFuelCost

	dfCost[!,Symbol("Total")] = [cTotal, cFix_Thermal, cFix_VRE, cFix_VRE_Trans, cFix_Must_Run, cFix_Hydro, cFix_Stor, cVar, cNSE, cStartCost, cRsvCost, cNetworkExpansionCost, cH2Fix_Gen, cH2Fix_G2P, cH2Fix_Stor, cH2Fix_Truck, cH2Var, cH2NSE, cH2Start, cH2NetworkExpCost, cDACFix, cDACVar, cCO2Comp, cCO2Stor, cCO2Injection, cCO2NetworkExpansion, cBiorefineryFix, cBiorefineryVar, cHerb, cWood,cSFFix, cSFVar, cSFByProdRev, cSFConvDieselFuelCost, cSFConvJetfuelFuelCost, cSFConvGasolineFuelCost, cPower_Total, cHSC_Total, cCSC_Total, cBiorefinery, cBioresources, cSF_Prod, cConv_Fuels, cHydro_Must_Run]

	# Define total column, i.e. column 2


	# Computing zonal cost breakdown by cost category
	for z in 1:Z
		tempCTotal = 0
		tempCFix_Thermal = 0
		tempCFix_VRE = 0
		tempCFix_Trans_VRE = 0
		tempCFix_Must_Run = 0
		tempCFix_Hydro = 0
		tempCFix_Stor = 0
		tempCVar = 0
		tempCStart = 0

		for y in intersect(inputs["THERM_ALL"], dfGen[dfGen[!,:Zone].==z,:R_ID])
			tempCFix_Thermal = tempCFix_Thermal + value.(EP[:eCFix])[y]
		end

		for y in intersect(inputs["VRE"], dfGen[dfGen[!,:Zone].==z,:R_ID])
			tempCFix_VRE = tempCFix_VRE + value.(EP[:eCFix])[y]
			tempCFix_Trans_VRE = tempCFix_Trans_VRE + value.(EP[:eCFix_VRE_Trans])[y]
		end

		for y in intersect(inputs["MUST_RUN"], dfGen[dfGen[!,:Zone].==z,:R_ID])
			tempCFix_Must_Run = tempCFix_Must_Run + value.(EP[:eCFix])[y]
		end

		for y in intersect(inputs["HYDRO_RES"], dfGen[dfGen[!,:Zone].==z,:R_ID])
			tempCFix_Hydro = tempCFix_Hydro + value.(EP[:eCFix])[y]
		end

		for y in intersect(inputs["STOR_ALL"], dfGen[dfGen[!,:Zone].==z,:R_ID])
			tempCFix_Stor = tempCFix_Stor + value.(EP[:eCFix])[y]
		end

		for y in dfGen[dfGen[!,:Zone].==z,:][!,:R_ID]
				
			tempCVar = tempCVar +
				(y in inputs["STOR_ALL"] ? sum(value.(EP[:eCVar_in])[y,:]) : 0) +
				(y in inputs["FLEX"] ? sum(value.(EP[:eCVarFlex_in])[y,:]) : 0) +
				sum(value.(EP[:eCVar_out])[y,:])

			tempCFix_Stor = tempCFix_Stor + (y in inputs["STOR_ALL"] ? value.(EP[:eCFixEnergy])[y] : 0) + (y in inputs["STOR_ASYMMETRIC"] ? value.(EP[:eCFixCharge])[y] : 0)
				
			if setup["UCommit"]>=1
				tempCTotal = tempCTotal +
					value.(EP[:eCFix])[y] +
					value.(EP[:eCFix_VRE_Trans])[y] +
					(y in inputs["STOR_ALL"] ? value.(EP[:eCFixEnergy])[y] : 0) +
					(y in inputs["STOR_ASYMMETRIC"] ? value.(EP[:eCFixCharge])[y] : 0) +
					(y in inputs["STOR_ALL"] ? sum(value.(EP[:eCVar_in])[y,:]) : 0) +
					(y in inputs["FLEX"] ? sum(value.(EP[:eCVarFlex_in])[y,:]) : 0) +
					sum(value.(EP[:eCVar_out])[y,:]) +
					(y in inputs["COMMIT"] ? sum(value.(EP[:eCStart])[y,:]) : 0)
					#
				tempCStart = tempCStart +
					(y in inputs["COMMIT"] ? sum(value.(EP[:eCStart])[y,:]) : 0)
			else
				tempCTotal = tempCTotal +
					value.(EP[:eCFix])[y] +
					value.(EP[:eCFix_VRE_Trans])[y] +
					(y in inputs["STOR_ALL"] ? value.(EP[:eCFixEnergy])[y] : 0) +
					(y in inputs["STOR_ASYMMETRIC"] ? value.(EP[:eCFixCharge])[y] : 0) +
					(y in inputs["STOR_ALL"] ? sum(value.(EP[:eCVar_in])[y,:]) : 0) +
					(y in inputs["FLEX"] ? sum(value.(EP[:eCVarFlex_in])[y,:]) : 0) +
					sum(value.(EP[:eCVar_out])[y,:])
			end
		end

		#HSC costs
		tempC_H2_Fix_Gen = 0
		tempC_H2_Fix_G2P = 0
		tempC_H2_Var_G2P = 0
		tempC_H2_Fix_Stor = 0
		tempC_H2_Var = 0
		tempC_H2_Start = 0

		if setup["ModelH2"] == 1

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

					#if !isempty(inputs["H2_G2P_COMMIT"])
					#	if y in inputs["H2_G2P_COMMIT"]
					#		tempC_H2_Start += value.(EP[:eTotalH2G2PCStartK])[y]
					#		tempCTotal += value.(EP[:eTotalH2G2PCStartK])[y]
					#	end
					#end
				end
			end
		end

		tempCDACFix = 0
		tempCDACVar = 0
		tempCCO2Comp = 0
		tempCCO2Stor = 0
		tempCCO2Injection = 0

		if setup["ModelCO2"] == 1
			for y in dfDAC[dfDAC[!,:Zone].==z,:][!,:R_ID]

				tempCDACFix = tempCDACFix + value.(EP[:eFixed_Cost_DAC_per_type])[y]
				tempCDACVar = tempCDACVar + sum(value.(EP[:eVar_OM_DAC_per_type])[y,:])
				tempCTotal = tempCTotal + value.(EP[:eFixed_Cost_DAC_per_type])[y] + sum(value.(EP[:eVar_OM_DAC_per_type])[y,:])
			end
	
			for y in dfCO2CaptureComp[dfCO2CaptureComp[!,:Zone].==z,:][!,:R_ID]
				tempCCO2Comp = tempCCO2Comp + value.(EP[:eFixed_Cost_CO2_Capture_Comp_per_type])[y]
				tempCTotal = tempCTotal + value.(EP[:eFixed_Cost_CO2_Capture_Comp_per_type])[y]
			end
	
			for y in dfCO2Storage[dfCO2Storage[!,:Zone].==z,:][!,:R_ID]
				tempCCO2Stor = tempCCO2Stor + value.(EP[:eFixed_Cost_CO2_Storage_per_type])[y]
				tempCTotal = tempCTotal + value.(EP[:eFixed_Cost_CO2_Storage_per_type])[y]
			end

			for y in dfCO2Storage[dfCO2Storage[!,:Zone].==z,:][!,:R_ID]
				tempCCO2Injection = tempCCO2Injection + value.(EP[:eVar_OM_CO2_Injection_per_type])[y]
				tempCTotal = tempCTotal + value.(EP[:eVar_OM_CO2_Injection_per_type])[y]
			end
		end

		tempCBIOFix = 0
		tempCBIOVar = 0
		tempCBIOHerb = 0
		tempCBIOWood = 0

		if setup["ModelBIO"] == 1
			for y in dfbiorefinery[dfbiorefinery[!,:Zone].==z,:][!,:R_ID]

				tempCBIOFix = tempCBIOFix + value.(EP[:eFixed_Cost_BIO_per_type])[y]
				tempCBIOVar = tempCBIOVar + sum(value.(EP[:eVar_Cost_BIO_per_plant])[y,:])

				tempCTotal = tempCTotal + value.(EP[:eFixed_Cost_BIO_per_type])[y] + sum(value.(EP[:eVar_Cost_BIO_per_plant])[y,:])
			end

			tempCBIOHerb = tempCBIOHerb + value.(EP[:eHerb_biomass_supply_cost_per_zone][z])
			tempCBIOWood = tempCBIOWood + value.(EP[:eWood_biomass_supply_cost_per_zone][z])
			tempCTotal = tempCTotal + value.(EP[:eHerb_biomass_supply_cost_per_zone][z]) + value.(EP[:eWood_biomass_supply_cost_per_zone][z])
		end

		tempC_SF_Fix = 0
		tempC_SF_Var = 0
		tempC_SF_ByProd = 0
		tempCDieselConvFuel = 0
		tempCJetfuelConvFuel = 0
		tempCGasolineConvFuel = 0

		if setup["ModelSynFuels"] == 1
			if setup["AllowConventionalDiesel"] == 1
				tempCDieselConvFuel = sum(value.(EP[:eCLFDieselVar_out])[z,:])
			else
				tempCDieselConvFuel = 0
			end
	
			if setup["AllowConventionalJetfuel"] == 1
				tempCJetfuelConvFuel = sum(value.(EP[:eCLFJetfuelVar_out])[z,:])
			else
				tempCJetfuelConvFuel = 0
			end
	
			if setup["AllowConventionalGasoline"] == 1
				tempCGasolineConvFuel = sum(value.(EP[:eCLFGasolineVar_out])[z,:])
			else
				tempCGasolineConvFuel = 0
			end

			for y in dfSynFuels[dfSynFuels[!,:Zone].==z,:][!,:R_ID]
				tempC_SF_Fix = tempC_SF_Fix +
					value.(EP[:eFixed_Cost_Syn_Fuels_per_type])[y]

				tempC_SF_Var = tempC_SF_Var +
					sum(value.(EP[:eCSFProdVar_out])[y,:])

				tempC_SF_ByProd = tempC_SF_ByProd + -sum(value.(EP[:eTotalCSFByProdRevenueOutTK])[:,y])


				tempCTotal = tempCTotal +
						value.(EP[:eFixed_Cost_Syn_Fuels_per_type])[y] +
						sum(value.(EP[:eCSFProdVar_out])[y,:]) +
						-sum(value.(EP[:eTotalCSFByProdRevenueOutTK])[:,y]) 
			end

			tempCTotal = tempCTotal +  tempCDieselConvFuel + tempCJetfuelConvFuel + tempCGasolineConvFuel

		end



		if setup["ParameterScale"] == 1 # Convert costs in millions to $
			tempCFix_Thermal = tempCFix_Thermal * (ModelScalingFactor^2)
			tempCFix_VRE = tempCFix_VRE * (ModelScalingFactor^2)
			tempCFix_Trans_VRE = tempCFix_Trans_VRE * (ModelScalingFactor^2)
			tempCFix_Must_Run = tempCFix_Must_Run * (ModelScalingFactor^2)
			tempCFix_Hydro = tempCFix_Hydro * (ModelScalingFactor^2)
			tempCFix_Stor = tempCFix_Stor * (ModelScalingFactor^2)
			tempCVar = tempCVar * (ModelScalingFactor^2)
			tempCStart = tempCStart * (ModelScalingFactor^2)

			tempC_H2_Fix_Gen = tempC_H2_Fix_Gen * (ModelScalingFactor^2)
			tempC_H2_Fix_G2P = tempC_H2_Fix_G2P * (ModelScalingFactor^2)
			tempC_H2_Var_G2P = tempC_H2_Var_G2P * (ModelScalingFactor^2)
			tempC_H2_Fix_Stor = tempC_H2_Fix_Stor * (ModelScalingFactor^2)
			tempC_H2_Var = tempC_H2_Var * (ModelScalingFactor^2)
			tempC_H2_Start = tempC_H2_Start * (ModelScalingFactor^2)

			tempCDACFix = tempCDACFix * (ModelScalingFactor^2)
			tempCDACVar = tempCDACVar * (ModelScalingFactor^2)
			tempCCO2Comp = tempCCO2Comp * (ModelScalingFactor^2)
			tempCCO2Stor = tempCCO2Stor * (ModelScalingFactor^2)
			tempCCO2Injection = tempCCO2Injection * (ModelScalingFactor^2)

			tempCBIOFix = tempCBIOFix * (ModelScalingFactor^2)
			tempCBIOVar = tempCBIOVar * (ModelScalingFactor^2)
			tempCBIOHerb = tempCBIOHerb * (ModelScalingFactor^2)
			tempCBIOWood = tempCBIOWood * (ModelScalingFactor^2)

			tempC_SF_Fix = tempC_SF_Fix * (ModelScalingFactor^2)
			tempC_SF_Var = tempC_SF_Var * (ModelScalingFactor^2)
			tempC_SF_ByProd = tempC_SF_ByProd * (ModelScalingFactor^2)
			tempCDieselConvFuel = tempCDieselConvFuel * (ModelScalingFactor^2)
			tempCJetfuelConvFuel = tempCJetfuelConvFuel * (ModelScalingFactor^2)
			tempCGasolineConvFuel = tempCGasolineConvFuel * (ModelScalingFactor^2)
			
			tempCTotal = tempCTotal * (ModelScalingFactor^2)
		end


		# Add emisions penalty related costs if the constraints are active to variable and total costs
		# Emissions penalty is already scaled previously depending on value of ParameterScale and hence not scaled here
		if setup["CO2Cap"]==4
			tempCVar  = tempCVar + value.(EP[:eCEmissionsPenaltybyZone])[z]
			tempCTotal=tempCTotal + value.(EP[:eCEmissionsPenaltybyZone])[z]
		end

		if setup["ParameterScale"] == 1
			tempCNSE = sum(value.(EP[:eCNSE])[:,:,z]) * (ModelScalingFactor^2)
		else
			tempCNSE = sum(value.(EP[:eCNSE])[:,:,z])
		end
		# Update non-served energy cost for each zone
		tempCTotal = tempCTotal +tempCNSE


		if setup["ModelH2"] == 1
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
		else
			tempC_H2_NSE = 0
		end

		dfCost[!,Symbol("Zone$z")] = [tempCTotal, tempCFix_Thermal, tempCFix_VRE, tempCFix_Trans_VRE, tempCFix_Must_Run, tempCFix_Hydro, tempCFix_Stor, tempCVar, tempCNSE, tempCStart, "-", "-",tempC_H2_Fix_Gen, tempC_H2_Fix_G2P, tempC_H2_Fix_Stor, "-", tempC_H2_Var, tempC_H2_NSE, tempC_H2_Start, "-", tempCDACFix, tempCDACVar, tempCCO2Comp, tempCCO2Stor, tempCCO2Injection, "-", tempCBIOFix, tempCBIOVar, tempCBIOHerb, tempCBIOWood, tempC_SF_Fix, tempC_SF_Var, tempC_SF_ByProd, tempCDieselConvFuel, tempCJetfuelConvFuel, tempCGasolineConvFuel, "-", "-", "-", "-", "-", "-", "-", "-"]
	end
	CSV.write(string(path,sep,"costs_system.csv"), dfCost)
end

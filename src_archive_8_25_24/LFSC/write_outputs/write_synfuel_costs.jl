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
	write_synfuel_costs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for writing the cost for the different sectors of the liquid fuels supply chain (Synthetic fuel resources CAPEX and OPEX, different types of conventional gasoline, jetfuel, and diesel).
"""
function write_synfuel_costs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	## Cost results
	dfSynFuels= inputs["dfSynFuels"]

	Z = inputs["Z"]     # Number of zones
	T = inputs["T"]     # Number of time steps (hours)

	dfSynFuelsCost = DataFrame(Costs = ["cSFTotal", "cSFFix", "cSFVar", "cSFByProdRev", "CSFConvDieselFuelCost","CSFConvJetfuelFuelCost","CSFConvGasolineFuelCost"])
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

	if setup["CO2Cap"]==4 
        ErrorException("Carbon Price for SynFuels Not implemented")
    end

	# Adding emissions penalty to variable cost depending on type of emissions policy constraint
	# Emissions penalty is already scaled by adjusting the value of carbon price used in emissions_HSC.jl
	#if((setup["CO2Cap"]==4 && setup["SystemCO2Constraint"]==2)||(setup["H2CO2Cap"]==4 && setup["SystemCO2Constraint"]==1))
	#	cSFVar  = cSFVar + value(EP[:eCH2GenTotalEmissionsPenalty])
	#end
	 
    cSFTotal = cSFVar + cSFFix + cSFByProdRev + cSFConvDieselFuelCost + cSFConvJetfuelFuelCost + cSFConvGasolineFuelCost

    dfSynFuelsCost[!,Symbol("Total")] = [cSFTotal, cSFFix, cSFVar, cSFByProdRev, cSFConvDieselFuelCost, cSFConvJetfuelFuelCost, cSFConvGasolineFuelCost]

	for z in 1:Z
		tempCTotal = 0
		tempC_SF_Fix = 0
		tempC_SF_Var = 0
		tempC_SF_ByProd = 0
		tempCDieselConvFuel = 0
		tempCJetfuelConvFuel = 0
		tempCGasolineConvFuel = 0

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

		if setup["ParameterScale"] == 1 # Convert costs in millions to $
			tempC_SF_Fix = tempC_SF_Fix * (ModelScalingFactor^2)
			tempC_SF_Var = tempC_SF_Var * (ModelScalingFactor^2)
			tempC_SF_ByProd = tempC_SF_ByProd * (ModelScalingFactor^2)
			tempCDieselConvFuel = tempCDieselConvFuel * (ModelScalingFactor^2)
			tempCJetfuelConvFuel = tempCJetfuelConvFuel * (ModelScalingFactor^2)
			tempCGasolineConvFuel = tempCGasolineConvFuel * (ModelScalingFactor^2)
			tempCTotal = tempCTotal * (ModelScalingFactor^2)
		end

		if setup["CO2Cap"]==4 
			ErrorException("Carbon Price for SynFuels Not implemented")
		end

		# Add emisions penalty related costs if the constraints are active
		# Emissions penalty is already scaled previously depending on value of ParameterScale and hence not scaled here
		#if((setup["CO2Cap"]==4 && setup["SystemCO2Constraint"]==2)||(setup["H2CO2Cap"]==4 && setup["SystemCO2Constraint"]==1))
		#	tempC_SF_Var  = tempC_SF_Var + value.(EP[:eCH2EmissionsPenaltybyZone])[z]
		#	tempCTotal = tempCTotal +value.(EP[:eCH2EmissionsPenaltybyZone])[z]
		#end

		dfSynFuelsCost[!,Symbol("Zone$z")] = [tempCTotal, tempC_SF_Fix, tempC_SF_Var, tempC_SF_ByProd, tempCDieselConvFuel, tempCJetfuelConvFuel, tempCGasolineConvFuel]
	end
	CSV.write(string(path,sep,"SynFuel_costs.csv"), dfSynFuelsCost)
end

"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
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
	write_h2_costs(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)

Function for writing the costs pertaining to the objective function (fixed, variable O&M etc.).
"""
function write_syn_costs(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)
	## Cost results
	dfSynGen = inputs["dfSynGen"]

	Z = inputs["Z"]     # Number of zones
	T = inputs["T"]     # Number of time steps (hours)
	SYN_GEN_COMMIT = inputs["SYN_GEN_COMMIT"] # H2 production technologies with unit commitment

	dfSynCost = DataFrame(Costs = ["cSynTotal", "cSynFix", "cSynVar", "cSynNSE", "cSynStart", "cNetworkExp"])
	if setup["ParameterScale"]==1 # Convert costs in millions to $
		cSynVar = (value(EP[:eTotalCSynGenVarOut])+ (!isempty(inputs["SYN_FLEX"]) ? value(EP[:eTotalCSynVarFlexIn]) : 0) + (!isempty(inputs["SYN_STOR_ALL"]) ? value(EP[:eTotalCVarSynStorIn]) : 0))* (ModelScalingFactor^2)
		cSynFix = (value(EP[:eTotalSynGenCFix])+ (!isempty(inputs["SYN_STOR_ALL"]) ? value(EP[:eTotalCFixSynEnergy]) + (!isempty(inputs["SYN_STOR_ASYMMETRIC"]) ? value(EP[:eTotalCFixSynCharge]) : 0) : 0))*ModelScalingFactor^2
	else
		cSynVar = (value(EP[:eTotalCSynGenVarOut])+ (!isempty(inputs["SYN_FLEX"]) ? value(EP[:eTotalCSynVarFlexIn]) : 0)+ (!isempty(inputs["SYN_STOR_ALL"]) ? value(EP[:eTotalCVarSynStorIn]) : 0))
		cSynFix = (value(EP[:eTotalSynGenCFix])+ (!isempty(inputs["SYN_STOR_ALL"]) ? value(EP[:eTotalCFixSynEnergy]) + (!isempty(inputs["SYN_STOR_ASYMMETRIC"]) ? value(EP[:eTotalCFixSynCharge]) : 0) : 0))
	end

	# Adding emissions penalty to variable cost depending on type of emissions policy constraint
	# Emissions penalty is already scaled by adjusting the value of carbon price used in emissions_HSC.jl
	if((setup["CO2Cap"]==4 && setup["SystemCO2Constraint"]==2)||(setup["SynCO2Cap"]==4 && setup["SystemCO2Constraint"]==1))
		cSynVar  = cSynVar + value(EP[:eCSynGenTotalEmissionsPenalty])
	end

	if !isempty(inputs["SYN_GEN_COMMIT"])
		if setup["ParameterScale"]==1 # Convert costs in millions to $
			cSynStart += value(EP[:eTotalSynGenCStart])*ModelScalingFactor^2
		else
	    	cSynStart += value(EP[:eTotalSynGenCStart])
		end
	end

	if Z >1
		if setup["ParameterScale"]==1 # Convert costs in millions to $
			cSynNetworkExpCost = value(EP[:eCSynPipe])*ModelScalingFactor^2
		else
			cSynNetworkExpCost = value(EP[:eCSynPipe])
		end
		cSynNetworkExpCost=0
	end


    cSynTotal = cSynVar + cSynFix + cSynStart + value(EP[:eTotalSynCNSE]) +cSynNetworkExpCost

    dfSynCost[!,Symbol("Total")] = [cSynTotal, cSynFix, cSynVar, value(EP[:eTotalSynCNSE]), cSynStart,cSynNetworkExpCost]


	for z in 1:Z
		tempCTotal = 0
		tempCFix = 0
		tempCVar = 0
		tempCStart = 0
		for y in dfSynGen[dfSynGen[!,:Zone].==z,:][!,:R_ID]
			tempCFix = tempCFix +
				(y in inputs["SYN_STOR_ALL"] ? value.(EP[:eCFixSynEnergy])[y] : 0) +
				(y in inputs["SYN_STOR_ALL"] ? value.(EP[:eCFixSynCharge])[y] : 0) +
				value.(EP[:eSynGenCFix])[y]
			tempCVar = tempCVar +
				(y in inputs["SYN_STOR_ALL"] ? sum(value.(EP[:eCVarSynStor_in])[y,:]) : 0) +
				(y in inputs["SYN_FLEX"] ? sum(value.(EP[:eCSynVarFlex_in])[y,:]) : 0) +
				sum(value.(EP[:eCSynGenVar_out])[y,:])
			if !isempty(SYN_GEN_COMMIT)
				tempCTotal = tempCTotal +
					value.(EP[:eSynGenCFix])[y] +
					(y in inputs["SYN_STOR_ALL"] ? value.(EP[:eCFixSynEnergy])[y] : 0) +
					(y in inputs["SYN_STOR_ALL"] ? value.(EP[:eCFixSynCharge])[y] : 0) +
					(y in inputs["SYN_STOR_ALL"] ? sum(value.(EP[:eCVarSynStor_in])[y,:]) : 0) +
					(y in inputs["SYN_FLEX"] ? sum(value.(EP[:eCSynVarFlex_in])[y,:]) : 0) +
					sum(value.(EP[:eCSynGenVar_out])[y,:]) +
					(y in inputs["SYN_GEN_COMMIT"] ? sum(value.(EP[:eSynGenCStart])[y,:]) : 0)
				tempCStart = tempCStart +
					(y in inputs["SYN_GEN_COMMIT"] ? sum(value.(EP[:eSynGenCStart])[y,:]) : 0)
			else
				tempCTotal = tempCTotal +
					value.(EP[:eSynGenCFix])[y] +
					(y in inputs["SYN_STOR_ALL"] ? value.(EP[:eCFixSynEnergy])[y] : 0) +
					(y in inputs["SYN_STOR_ALL"] ? value.(EP[:eCFixSynCharge])[y] : 0) +
					(y in inputs["SYN_STOR_ALL"] ? sum(value.(EP[:eCVarSynStor_in])[y,:]) : 0) +
					(y in inputs["SYN_FLEX"] ? sum(value.(EP[:eCSynVarFlex_in])[y,:]) : 0) +
					sum(value.(EP[:eCSynGenVar_out])[y,:])
			end
		end


		if setup["ParameterScale"] == 1 # Convert costs in millions to $
			tempCFix = tempCFix * (ModelScalingFactor^2)
			tempCVar = tempCVar * (ModelScalingFactor^2)
			tempCTotal = tempCTotal * (ModelScalingFactor^2)
			tempCStart = tempCStart * (ModelScalingFactor^2)
		end

		# Add emisions penalty related costs if the constraints are active
		# Emissions penalty is already scaled previously depending on value of ParameterScale and hence not scaled here
		if((setup["CO2Cap"]==4 && setup["SystemCO2Constraint"]==2)||(setup["SynCO2Cap"]==4 && setup["SystemCO2Constraint"]==1))
			tempCVar  = tempCVar + value.(EP[:eCSynEmissionsPenaltybyZone])[z]
			tempCTotal = tempCTotal +value.(EP[:eCSynEmissionsPenaltybyZone])[z]
		end

		if setup["ParameterScale"] == 1 # Convert costs in millions to $
			tempCNSE = sum(value.(EP[:eSynCNSE])[:,:,z])* (ModelScalingFactor^2)
		else
			tempCNSE = sum(value.(EP[:eSynCNSE])[:,:,z])
		end

		dfSynCost[!,Symbol("Zone$z")] = [tempCTotal, tempCFix, tempCVar, tempCNSE, tempCStart,"-"]
	end

	CSV.write(joinpath(path,"Syn_fuels_costs.csv"), dfSynCost)

end

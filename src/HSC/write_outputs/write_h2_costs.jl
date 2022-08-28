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

Function for writing the costs of hydrogen supply chain pertaining to the objective function (fixed, variable O&M etc.).
"""
function write_h2_costs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	## Cost results
	dfH2Gen = inputs["dfH2Gen"]

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


	dfH2Cost = DataFrame(Costs = ["cH2Total", "cH2Fix", "cH2Var", "cH2NSE", "cH2Start", "cNetworkExp"])
	if setup["ParameterScale"]==1 # Convert costs in millions to $
		cH2Var = (value(EP[:eTotalCH2GenVarOut])+ (!isempty(inputs["H2_FLEX"]) ? value(EP[:eTotalCH2VarFlexIn]) : 0) + (!isempty(inputs["H2_STOR_ALL"]) ? value(EP[:eTotalCVarH2StorIn]) : 0) + cG2PVar)* (ModelScalingFactor^2)
		cH2Fix = (value(EP[:eTotalH2GenCFix])+ (!isempty(inputs["H2_STOR_ALL"]) ? value(EP[:eTotalCFixH2Energy]) +value(EP[:eTotalCFixH2Charge]) : 0) + cG2PFix )*ModelScalingFactor^2
	else
		cH2Var = (value(EP[:eTotalCH2GenVarOut])+ (!isempty(inputs["H2_FLEX"]) ? value(EP[:eTotalCH2VarFlexIn]) : 0)+ (!isempty(inputs["H2_STOR_ALL"]) ? value(EP[:eTotalCVarH2StorIn]) : 0) + cG2PVar)
		cH2Fix = (value(EP[:eTotalH2GenCFix])+ (!isempty(inputs["H2_STOR_ALL"]) ? value(EP[:eTotalCFixH2Energy]) +value(EP[:eTotalCFixH2Charge]) : 0) + cG2PFix)
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

	if Z >1
		if setup["ParameterScale"]==1 # Convert costs in millions to $
			cH2NetworkExpCost = value(EP[:eCH2Pipe])*ModelScalingFactor^2
		else
			cH2NetworkExpCost = value(EP[:eCH2Pipe])
		end
		cH2NetworkExpCost=0
	end

	 
    cH2Total = cH2Var + cH2Fix + cH2Start + value(EP[:eTotalH2CNSE]) +cH2NetworkExpCost

    dfH2Cost[!,Symbol("Total")] = [cH2Total, cH2Fix, cH2Var, value(EP[:eTotalH2CNSE]), cH2Start,cH2NetworkExpCost]


	for z in 1:Z
		tempCTotal = 0
		tempCFix = 0
		tempCVar = 0
		tempCStart = 0
		for y in dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID]
			tempCFix = tempCFix +
				(y in inputs["H2_STOR_ALL"] ? value.(EP[:eCFixH2Energy])[y] : 0) +
				(y in inputs["H2_STOR_ALL"] ? value.(EP[:eCFixH2Charge])[y] : 0) +
				value.(EP[:eH2GenCFix])[y]
			tempCVar = tempCVar +
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
				tempCStart = tempCStart +
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

			if setup["ModelH2G2P"] == 1
				for  y in dfH2G2P[dfH2G2P[!,:Zone].==z,:][!,:R_ID]

					tempCFix += value.(EP[:eTotalH2G2PCFix])
					tempCVar += value.(EP[:eTotalCH2G2PVarOut])
					tempCTotal += value.(EP[:eTotalH2G2PCFix]) + value.(EP[:eTotalCH2G2PVarOut])

					if !isempty(inputs["H2_G2P_COMMIT"])
						if y in inputs["H2_G2P_COMMIT"]
							tempCStart += value.(EP[:eTotalH2G2PCStart]) 
							tempCTotal += value.(EP[:eTotalH2G2PCStart]) 
						end
					end
				end
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
		if((setup["CO2Cap"]==4 && setup["SystemCO2Constraint"]==2)||(setup["H2CO2Cap"]==4 && setup["SystemCO2Constraint"]==1))
			tempCVar  = tempCVar + value.(EP[:eCH2EmissionsPenaltybyZone])[z]
			tempCTotal = tempCTotal +value.(EP[:eCH2EmissionsPenaltybyZone])[z]
		end
		
		if setup["ParameterScale"] == 1 # Convert costs in millions to $
			tempCNSE = sum(value.(EP[:eH2CNSE])[:,:,z])* (ModelScalingFactor^2)
		else
			tempCNSE = sum(value.(EP[:eH2CNSE])[:,:,z])
		end

		dfH2Cost[!,Symbol("Zone$z")] = [tempCTotal, tempCFix, tempCVar, tempCNSE, tempCStart,"-"]
	end
	CSV.write(string(path,sep,"HSC_costs.csv"), dfH2Cost)
end

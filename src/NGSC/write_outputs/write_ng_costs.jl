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
	write_ng_costs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for writing the cost for the different sectors of the natural gas supply chain (Synthetic NG resources CAPEX and OPEX, conventional NG).
"""
function write_ng_costs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	## Cost results
	#if setup["ModelSyntheticNG"] == 1
	#	dfNG= inputs["dfNG"]
	#end

	Z = inputs["Z"]     # Number of zones
	T = inputs["T"]     # Number of time steps (hours)

	dfNGCost = DataFrame(Costs = ["cNGTotal", "cSNGFix", "cSNGVar","cConvNGCost"])

	cSNGVar = 0
	cSNGFix = 0

	#if setup["ModelSyntheticNG"] == 1
	#	cSNGVar = value(EP[:eTotalCSNGProdVarOut])*ModelScalingFactor^2
	#	cSNGFix = value(EP[:eFixed_Cost_Syn_NG_total])*ModelScalingFactor^2
	#end

	cConvNGCost = value(EP[:eTotalConv_NG_VarOut])
	 
    cNGTotal = cSNGVar + cSNGFix + cConvNGCost

    dfNGCost[!,Symbol("Total")] = [cNGTotal, cSNGFix, cSNGVar, cConvNGCost]

	for z in 1:Z
		tempCTotal = 0
		tempC_SNG_Fix = 0
		tempC_SNG_Var = 0

		tempCNGConvFuel = sum(value.(EP[:eTotalConv_NG_VarOut_Z])[z,:])

		#if setup["ModelSyntheticNG"] == 1
		#	for y in dfNG[dfNG[!,:Zone].==z,:][!,:R_ID]
		#		tempC_SNG_Fix = tempC_SNG_Fix +
		#			value.(EP[:eFixed_Cost_Syn_NG_per_type])[y]

		#		tempC_SNG_Var = tempC_SNG_Var +
		#			sum(value.(EP[:eCSNGProdVar_out])[y,:])

		#		tempCTotal = tempCTotal +
		#				value.(EP[:eFixed_Cost_Syn_NG_per_type])[y] +
		#				sum(value.(EP[:eCSNGProdVar_out])[y,:])
		#	end
		#end

		tempCTotal = tempCTotal +  tempCNGConvFuel

		dfNGCost[!,Symbol("Zone$z")] = [tempCTotal, tempC_SNG_Fix, tempC_SNG_Var, tempCNGConvFuel]
	end
	CSV.write(string(path,sep,"NG_costs.csv"), dfNGCost)
end

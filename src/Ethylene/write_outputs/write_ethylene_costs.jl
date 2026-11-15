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

Function for writing the cost for the different sectors of the Ethylene (Synthetic Ethylene resources CAPEX and OPEX, conventional Ethylene Purchase).
"""
function write_ethylene_costs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

#=	
	## Cost results
	Z = inputs["Z"]     # Number of zones

	if setup["ModelEthyleneProduction"] == 1
		dfEthylene = inputs["dfEthylene"]
    end
	

	dfEthyleneCost = DataFrame(Costs = ["cEthyleneTotal", "c_EthyleneFix", "c_EthyleneVar","cConvEthyleneCost"])

	cEthyleneVar = 0
	cEthyleneFix = 0

	if setup["ModelEthyleneProduction"] == 1
		cEthyleneVar = value(EP[:eTotalCEthyleneProdVarOut])
		cEthyleneFix = value(EP[:eFixed_Cost_Ethylene_total])
	end

	cConvEthyleneCost = 0
	if setup["ModelEthylenePurchase"] == 1
		cConvEthyleneCost = value(EP[:eTotalConv_Ethylene_VarOut])
	end
	
	 
    cEthyleneTotal = cEthyleneVar + cEthyleneFix + cConvEthyleneCost

    dfEthyleneCost[!,Symbol("Total")] = [cEthyleneTotal, cEthyleneFix, cEthyleneVar, cConvEthyleneCost]
	tempCEthyleneConvFuel = 0
	for z in 1:Z
		tempCTotal = 0
		tempC_Ethylene_Fix = 0
		tempC_Ethylene_Var = 0
		if setup["ModelEthylenePurchase"] == 1
			tempCEthyleneConvFuel = sum(value.(EP[:eTotalConv_Ethylene_VarOut_Z])[z,:])
		end
		

		if setup["ModelEthyleneProduction"] == 1
			for y in dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID]
				tempC_Ethylene_Fix = tempC_Ethylene_Fix +
					value.(EP[:eFixed_Cost_Ethylene_per_type])[y]

				tempC_Ethylene_Var = tempC_Ethylene_Var +
					sum(value.(EP[:eCEthyleneProdVar_out])[y,:])

				tempCTotal = tempCTotal +
						value.(EP[:eFixed_Cost_Ethylene_per_type])[y] +
						sum(value.(EP[:eCEthyleneProdVar_out])[y,:])
			end
		end

		tempCTotal = tempCTotal +  tempCEthyleneConvFuel

		dfEthyleneCost[!,Symbol("Zone$z")] = [tempCTotal, tempC_Ethylene_Fix, tempC_Ethylene_Var, tempCEthyleneConvFuel]
	end

=#
	################################################ VERSION 2  #########################################################
		
	## Cost results
	Z = inputs["Z"]     # Number of zones

	if setup["ModelEthyleneProduction"] == 1
		dfEthylene = inputs["dfEthylene"]
		dfEthylene_plants = inputs["dfEthylene_plants"]
    end
	

	dfEthyleneCost = DataFrame(Costs = ["cEthyleneTotal", "c_EthyleneFix_GF", "c_EthyleneVar_GF","c_EthyleneFix_EP", "c_EthyleneVar_EP","cConvEthyleneCost"])

	cEthyleneVar_GF = 0
	cEthyleneFix_GF = 0
	cEthyleneVar_EP = 0
	cEthyleneFix_EP = 0

	if setup["ModelEthyleneProduction"] == 1
		cEthyleneVar_GF = value(EP[:eTotalCEthyleneProdVarOut_GF])
		cEthyleneFix_GF = value(EP[:eFixed_Cost_Ethylene_total_GF])
		if setup["ModelEthylenePlants"] == 1
			cEthyleneVar_EP = value(EP[:eTotalCEthyleneProdVarOut_EP])
			cEthyleneFix_EP = value(EP[:eFixed_Cost_Ethylene_total_EP])
		end


	end

	cConvEthyleneCost = 0
	if setup["ModelEthylenePurchase"] == 1
		cConvEthyleneCost = value(EP[:eTotalConv_Ethylene_VarOut])
	end
	
	 
    cEthyleneTotal = cEthyleneVar_GF + cEthyleneFix_GF + cConvEthyleneCost + cEthyleneVar_EP + cEthyleneFix_EP

    dfEthyleneCost[!,Symbol("Total")] = [cEthyleneTotal, cEthyleneFix_GF, cEthyleneVar_GF, cEthyleneFix_EP, cEthyleneVar_EP, cConvEthyleneCost]

	tempCEthyleneConvFuel = 0

	for z in 1:Z
		tempCTotal = 0
		tempC_Ethylene_Fix_GF = 0
		tempC_Ethylene_Var_GF = 0
		tempC_Ethylene_Fix_EP = 0
		tempC_Ethylene_Var_EP = 0

		if setup["ModelEthylenePurchase"] == 1
			tempCEthyleneConvFuel = sum(value.(EP[:eTotalConv_Ethylene_VarOut_Z])[z,:])
		end
		

		if setup["ModelEthyleneProduction"] == 1
			for y in dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID]
				tempC_Ethylene_Fix_GF = tempC_Ethylene_Fix_GF +
					value.(EP[:eFixed_Cost_Ethylene_per_type_GF])[y]

				tempC_Ethylene_Var_GF = tempC_Ethylene_Var_GF +
					sum(value.(EP[:eCEthyleneProdVar_out_GF])[y,:])

				tempCTotal = tempCTotal +
						value.(EP[:eFixed_Cost_Ethylene_per_type_GF])[y] +
						sum(value.(EP[:eCEthyleneProdVar_out_GF])[y,:])
			end
			if setup["ModelEthylenePlants"] == 1
				for y in dfEthylene_plants[dfEthylene_plants[!,:Plant_Zone].==z,:][!,:R_ID]
					tempC_Ethylene_Fix_EP = tempC_Ethylene_Fix_EP +
						value.(EP[:eFixed_Cost_Ethylene_per_type_EP])[y]
	
					tempC_Ethylene_Var_EP = tempC_Ethylene_Var_EP +
						sum(value.(EP[:eCEthyleneProdVar_out_EP])[y,:])
	
					tempCTotal = tempCTotal +
							value.(EP[:eFixed_Cost_Ethylene_per_type_EP])[y] +
							sum(value.(EP[:eCEthyleneProdVar_out_EP])[y,:])
				end

			end



		end

		tempCTotal = tempCTotal +  tempCEthyleneConvFuel

		dfEthyleneCost[!,Symbol("Zone$z")] = [tempCTotal, tempC_Ethylene_Fix_GF, tempC_Ethylene_Var_GF, tempC_Ethylene_Fix_EP, tempC_Ethylene_Var_EP,tempCEthyleneConvFuel]
	end
	CSV.write(string(path,sep,"Ethylene_costs.csv"), dfEthyleneCost)
end

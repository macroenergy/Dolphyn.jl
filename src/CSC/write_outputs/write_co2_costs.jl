"""
DOLPHYN: Decision Optimization for Low-carbon for Power and Hydrogen Networks
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
	write_costs(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)

Function for writing the costs pertaining to the objective function (fixed, variable O&M etc.).
"""
function write_co2_costs(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)

	## Cost results
	dfCO2Capture = inputs["dfCO2Capture"]

	CO2_SEG = inputs["CO2_SEG"]  # Number of lines
	Z = inputs["Z"]     # Number of zones
	T = inputs["T"]     # Number of time steps (hours)
	CO2_CAPTURE_COMMIT = inputs["CO2_CAPTURE_COMMIT"] # CO2 production technologies with unit commitment

	cCO2Start = 0

	dfCO2Cost = DataFrame(Costs = ["cCO2Total", "cCO2Fix", "cCO2Var", "cCO2Start"])
	if setup["ParameterScale"] == 1 # Convert costs in millions to $
		cCO2Var = value(EP[:eTotalCCO2CaptureVarOut])* (ModelScalingFactor^2)
		cCO2Fix = value(EP[:eTotalCO2CaptureCFix])*ModelScalingFactor^2
	else
		cCO2Var = value(EP[:eTotalCCO2CaptureVarOut])
		cCO2Fix = value(EP[:eTotalCO2CaptureCFix])
	end

	# Adding emissions penalty to variable cost depending on type of emissions policy constraint
	# Emissions penalty is already scaled by adjusting the value of carbon price used in emissions_CSC.jl
	# if((setup["CO2Cap"]==4 && setup["SystemCO2Constraint"]==2)||(setup["CO2CO2Cap"]==4 && setup["SystemCO2Constraint"]==1))
	# 	cCO2Var  = cCO2Var + value(EP[:eCCO2CaptureTotalEmissionsPenalty])
	# end

	if !isempty(inputs["CO2_CAPTURE_COMMIT"])
		if setup["ParameterScale"]==1 # Convert costs in millions to $
			cCO2Start += value(EP[:eTotalCO2CaptureCStart])*ModelScalingFactor^2
		else
	    	cCO2Start += value(EP[:eTotalCO2CaptureCStart])
		end
	end
	 
    cCO2Total = cCO2Var + cCO2Fix + cCO2Start

    dfCO2Cost[!,Symbol("Total")] = [cCO2Total, cCO2Fix, cCO2Var, cCO2Start]


	for z in 1:Z
		tempCTotal = 0
		tempCFix = 0
		tempCVar = 0
		tempCStart = 0
		for y in dfCO2Capture[dfCO2Capture[!,:Zone].==z,:][!,:R_ID]
			tempCFix = tempCFix +
			if !isempty(CO2_CAPTURE_COMMIT)
				tempCTotal = tempCTotal +
					value.(EP[:eCO2CaptureCFix])[y] +
					sum(value.(EP[:eCCO2CaptureVar_out])[y,:]) +
					(y in inputs["CO2_CAPTURE_COMMIT"] ? sum(value.(EP[:eCO2CaptureCStart])[y,:]) : 0)
				tempCStart = tempCStart +
					(y in inputs["CO2_CAPTURE_COMMIT"] ? sum(value.(EP[:eCO2CaptureCStart])[y,:]) : 0)
			else
				tempCTotal = tempCTotal +
					value.(EP[:eCO2CaptureCFix])[y] +
					sum(value.(EP[:eCCO2CaptureVar_out])[y,:])
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
		#if((setup["CO2Cap"]==4 && setup["SystemCO2Constraint"]==2)||(setup["CO2CO2Cap"]==4 && setup["SystemCO2Constraint"]==1))
			#tempCVar  = tempCVar + value.(EP[:eCCO2EmissionsPenaltybyZone])[z]
			#tempCTotal = tempCTotal +value.(EP[:eCCO2EmissionsPenaltybyZone])[z]
		#end

		dfCO2Cost[!,Symbol("Zone$z")] = [tempCTotal, tempCFix, tempCVar, tempCStart]
	end

	CSV.write(joinpath(path, "CSC_costs.csv"), dfCO2Cost)
end

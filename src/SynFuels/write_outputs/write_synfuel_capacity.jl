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
	write_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model))

Function for writing the diferent capacities for the different generation technologies (starting capacities or, existing capacities, retired capacities, and new-built capacities).
"""
function write_synfuel_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	# Capacity decisions
	dfSynFuels = inputs["dfSynFuels"]
	capdischarge = zeros(size(inputs["SYN_FUELS_RESOURCES_NAME"]))
	for i in union(inputs["SYN_FUEL_RES_COMMIT"], inputs["SYN_FUEL_RES_NO_COMMIT"])
		if i in inputs["SYN_FUEL_RES_COMMIT"]
			#capdischarge[i] = value(EP[:vH2GenNewCap][i]) * dfSynFuels[!,:Cap_Size_tonne_p_hr][i]
			ErrorException("SynFuel Commit Output functions not implemented")
		else
			if setup["ParameterScale"] ==1
				capdischarge[i] = value(EP[:vCapacity_Syn_Fuel_per_type][i])*ModelScalingFactor
			else
				capdischarge[i] = value(EP[:vCapacity_Syn_Fuel_per_type][i])
			end
		end
	end

	#No retirment feature implemented

	#retcapdischarge = zeros(size(inputs["H2_RESOURCES_NAME"]))
	#for i in inputs["H2_GEN_RET_CAP"]
	#	if i in inputs["H2_GEN_COMMIT"]
	#		retcapdischarge[i] = first(value.(EP[:vH2GenRetCap][i])) * dfSynFuels[!,:Cap_Size_tonne_p_hr][i]
	#	else
	#		retcapdischarge[i] = first(value.(EP[:vH2GenRetCap][i]))
	#	end
	#end

	dfCap = DataFrame(
		Resource = inputs["SYN_FUELS_RESOURCES_NAME"], Zone = dfSynFuels[!,:Zone],
		#StartCap = dfSynFuels[!,:Existing_Cap_tonne_p_hr],
		#RetCap = retcapdischarge[:],
		NewCap = capdischarge[:]
		#EndCap = value.(EP[:eH2GenTotalCap])
	)

	total = DataFrame(
			Resource = "Total", Zone = "n/a",
			#StartCap = sum(dfCap[!,:StartCap]), RetCap = sum(dfCap[!,:RetCap]),
			NewCap = sum(dfCap[!,:NewCap]))
			#, EndCap = sum(dfCap[!,:EndCap]))

	dfCap = vcat(dfCap, total)
	CSV.write(string(path,sep,"SynFuel_capacity.csv"), dfCap)
	return dfCap
end

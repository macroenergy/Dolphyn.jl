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
	write_g2p_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the diferent capacities for the different hydrogen to power technologies (starting capacities or, existing capacities, retired capacities, and new-built capacities).
"""
function write_g2p_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	# Capacity decisions
	dfH2G2P = inputs["dfH2G2P"]
	H = inputs["H2_G2P_ALL"]

	capdischarge = zeros(size(inputs["H2_G2P_NAME"]))
	for i in inputs["H2_G2P_NEW_CAP"]
		if i in inputs["H2_G2P_COMMIT"]
			capdischarge[i] = value(EP[:vH2G2PNewCap][i]) * dfH2G2P[!,:Cap_Size_MW][i]
		else
			capdischarge[i] = value(EP[:vH2G2PNewCap][i])
		end
	end

	retcapdischarge = zeros(size(inputs["H2_G2P_NAME"]))
	for i in inputs["H2_G2P_RET_CAP"]
		if i in inputs["H2_G2P_COMMIT"]
			retcapdischarge[i] = first(value.(EP[:vH2G2PRetCap][i])) * dfH2G2P[!,:Cap_Size_MW][i]
		else
			retcapdischarge[i] = first(value.(EP[:vH2G2PRetCap][i]))
		end
	end

	MaxGen = zeros(size(1:inputs["H2_G2P_ALL"]))
	for i in 1:H
		MaxGen[i] = value.(EP[:eH2G2PTotalCap])[i] * 8760
	end

	AnnualGen = zeros(size(1:inputs["H2_G2P_ALL"]))
	for i in 1:H
		AnnualGen[i] = sum(inputs["omega"].* (value.(EP[:vPG2P])[i,:]))
	end

	CapFactor = zeros(size(1:inputs["H2_G2P_ALL"]))
	for i in 1:H
		if MaxGen[i] == 0
			CapFactor[i] = 0
		else
			CapFactor[i] = AnnualGen[i]/MaxGen[i]
		end
	end

	

	dfCap = DataFrame(
		Resource = inputs["H2_G2P_NAME"], Zone = dfH2G2P[!,:Zone],
		StartCap = dfH2G2P[!,:Existing_Cap_MW],
		RetCap = retcapdischarge[:],
		NewCap = capdischarge[:],
		EndCap = value.(EP[:eH2G2PTotalCap]),
		MaxAnnualGeneration = MaxGen[:],
		AnnualGeneration = AnnualGen[:],
		CapacityFactor = CapFactor[:]
	)


	total = DataFrame(
			Resource = "Total", Zone = "n/a",
			StartCap = sum(dfCap[!,:StartCap]), RetCap = sum(dfCap[!,:RetCap]),
			NewCap = sum(dfCap[!,:NewCap]), EndCap = sum(dfCap[!,:EndCap]),
			MaxAnnualGeneration = sum(dfCap[!,:MaxAnnualGeneration]), AnnualGeneration = sum(dfCap[!,:AnnualGeneration]),
			CapacityFactor = "-"
		)

	dfCap = vcat(dfCap, total)
	CSV.write(string(path,sep,"HSC_g2p_capacity.csv"), dfCap)
	return dfCap
end

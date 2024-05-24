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
	write_bio_wood_supply(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the wood biomass purchased from different resources across zones with time.
"""
function write_bio_wood_supply(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	dfWood = inputs["dfWood"]
	H = inputs["WOOD_SUPPLY_RES_ALL"]     # Number of resources (generators, storage, DR, and DERs)
	T = inputs["T"]     # Number of time steps (hours)

	# Hydrogen injected by each resource in each time step
	# dfWoodOut_annual = DataFrame(Resource = inputs["WOOD_SUPPLY_NAME"], Zone = dfWood[!,:Zone], AnnualSum = Array{Union{Missing,Float32}}(undef, H))
	dfWoodOut = DataFrame(Resource = inputs["WOOD_SUPPLY_NAME"], Zone = dfWood[!,:Zone], AnnualSum = Array{Union{Missing,Float32}}(undef, H))

	woodsupply = value.(EP[:vWood_biomass_purchased])
    dfWoodOut.AnnualSum .= woodsupply * inputs["omega"]

	# Load hourly values
	dfWoodOut = hcat(dfWoodOut, DataFrame((value.(EP[:vWood_biomass_purchased])), :auto))

	# Add labels
	auxNew_Names=[Symbol("Resource");Symbol("Zone");Symbol("AnnualSum");[Symbol("t$t") for t in 1:T]]
	rename!(dfWoodOut,auxNew_Names)

	total = DataFrame(["Total" 0 sum(dfWoodOut[!,:AnnualSum]) fill(0.0, (1,T))], :auto)

 	total[:,4:T+3] .= sum(woodsupply, dims=1)

	rename!(total,auxNew_Names)

	dfWoodOut = vcat(dfWoodOut, total)
 	CSV.write(string(path,sep,"BESC_wood_supply.csv"), dftranspose(dfWoodOut, false), writeheader=false)
	
	return dfWoodOut


end

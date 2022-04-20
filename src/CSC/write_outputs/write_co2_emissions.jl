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
	write_emissions(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting time-dependent CO$_2$ emissions by zone.

"""
function write_co2_emissions(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	dfCO2Capture = inputs["dfCO2Capture"]
	G = inputs["G"]     # Number of resources (generators, storage, DR, and DERs)
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

		dfEmissions = DataFrame(Zone = 1:Z, AnnualSum = Array{Union{Missing,Float32}}(undef, Z))

	for i in 1:Z
		if setup["ParameterScale"]==1
			dfEmissions[!,:AnnualSum][i] = sum(inputs["omega"].*value.(EP[:eCO2NegativeEmissionsByZone])[i,:])*ModelScalingFactor
		else
			dfEmissions[!,:AnnualSum][i] = sum(inputs["omega"].*value.(EP[:eCO2NegativeEmissionsByZone])[i,:])/ModelScalingFactor
		end
	end

	if setup["ParameterScale"]==1
		dfEmissions = hcat(dfEmissions, DataFrame(value.(EP[:eCO2NegativeEmissionsByZone])*ModelScalingFactor, :auto))
	else
		dfEmissions = hcat(dfEmissions, DataFrame(value.(EP[:eCO2NegativeEmissionsByZone])/ModelScalingFactor, :auto))
	end


	auxNew_Names=[Symbol("Zone"); Symbol("AnnualSum"); [Symbol("t$t") for t in 1:T]]
	rename!(dfEmissions,auxNew_Names)
	total = DataFrame(["Total" sum(dfEmissions[!,:AnnualSum]) fill(0.0, (1,T))], :auto)
	for t in 1:T
		if v"1.3" <= VERSION < v"1.4"
			total[!,t+2] .= sum(dfEmissions[!,Symbol("t$t")][1:Z])
		elseif v"1.4" <= VERSION < v"1.7"
			total[:,t+2] .= sum(dfEmissions[:,Symbol("t$t")][1:Z])
		end
	end
	rename!(total,auxNew_Names)
	dfEmissions = vcat(dfEmissions, total)

	CSV.write(string(path,sep,"CSC_emissions.csv"), dftranspose(dfEmissions, false), writeheader=false)
end

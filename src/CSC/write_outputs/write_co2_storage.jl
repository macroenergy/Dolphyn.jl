"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
Copyright (C) 2021, Massachusetts Institute of Technology and Peking University
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt. Users uncompressing this from an archive may not have
received this license file. If not, see <http://www.gnu.org/licenses/>.
"""

@doc raw"""
	write_power(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)

Function for writing the different values of power generated by the different technologies in operation.
"""
function write_co2_storage(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)

	dfCO2Stor = inputs["dfCO2Stor"]
	H = inputs["CO2_STOR_ALL"]     # Number of resources (Capture units, storage, DR, and DERs)
	T = inputs["T"]     # Number of time steps (hours)

	# Power injected by each resource in each time step
	# dfCO2StorOut_annual = DataFrame(Resource = inputs["CO2_STORAGE_NAME"], Zone = dfCO2Stor[!,:Zone], AnnualSum = Array{Union{Missing,Float32}}(undef, H))
	dfCO2StorOut = DataFrame(Resource = inputs["CO2_STORAGE_NAME"], Zone = dfCO2Stor[!,:Zone], AnnualSum = Array{Union{Missing,Float32}}(undef, H))

	for i in 1:H
		dfCO2StorOut[!,:AnnualSum][i] = sum(inputs["omega"].* (value.(EP[:vCO2S])[i,:]))
	end
	# Load hourly values
	dfCO2StorOut = hcat(dfCO2StorOut, DataFrame((value.(EP[:vCO2S])), :auto))

	# Add labels
	auxNew_Names=[Symbol("Resource");Symbol("Zone");Symbol("AnnualSum");[Symbol("t$t") for t in 1:T]]
	rename!(dfCO2StorOut,auxNew_Names)

	total = DataFrame(["Total" 0 sum(dfCO2StorOut[!,:AnnualSum]) fill(0.0, (1,T))], :auto)

	for t in  1:T
		total[:,t+3] .= sum(dfCO2StorOut[:,Symbol("t$t")][1:H])
	end

	rename!(total,auxNew_Names)
	dfCO2StorOut = vcat(dfCO2StorOut, total)

 	CSV.write(joinpath(path, "CSC_co2_storage.csv"), dftranspose(dfCO2StorOut, false), writeheader=false)

	return dfCO2StorOut
end
